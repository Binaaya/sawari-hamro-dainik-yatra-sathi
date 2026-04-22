const db = require('../config/database');
const { asyncHandler, ApiError } = require('../middleware/errorHandler');
const { notifyUser } = require('./notifications.controller');

/**
 * Get complaints (for authenticated user or admin)
 * GET /api/complaints
 */
const getComplaints = asyncHandler(async (req, res) => {
  const { status, rideId, page = 1, limit = 20 } = req.query;
  const userId = req.user.userid;
  const userRole = req.user.role;

  let whereClause = 'WHERE 1=1';
  const params = [];

  // Non-admin users can only see their own complaints
  if (userRole !== 'Admin') {
    params.push(userId);
    whereClause += ` AND c.userid = $${params.length}`;
  }

  if (status) {
    params.push(status);
    whereClause += ` AND c.complaintstatus = $${params.length}`;
  }

  if (rideId) {
    params.push(rideId);
    whereClause += ` AND c.rideid = $${params.length}`;
  }

  // Count total
  const countResult = await db.query(
    `SELECT COUNT(*) as total
     FROM complaints c
     JOIN users u ON c.userid = u.userid
     LEFT JOIN passengers p ON c.passengerid = p.passengerid
     ${whereClause}`,
    params
  );
  const total = parseInt(countResult.rows[0].total);

  // Get paginated results
  const offset = (page - 1) * limit;
  params.push(limit);
  params.push(offset);

  const result = await db.query(
    `SELECT c.*,
            COALESCE(p.fullname, o.operatorname, u.email) as complainant_name,
            u.role as complainant_role,
            rt.routename, r.entrytime as ride_date
     FROM complaints c
     JOIN users u ON c.userid = u.userid
     LEFT JOIN passengers p ON c.passengerid = p.passengerid
     LEFT JOIN operators o ON u.userid = o.userid
     LEFT JOIN rides r ON c.rideid = r.rideid
     LEFT JOIN routes rt ON r.routeid = rt.routeid
     ${whereClause}
     ORDER BY c.complaintdate DESC
     LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );

  res.json({
    success: true,
    data: {
      complaints: result.rows,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / limit)
      }
    }
  });
});

/**
 * Get complaint by ID
 * GET /api/complaints/:id
 */
const getComplaintById = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.userid;
  const userRole = req.user.role;

  const result = await db.query(
    `SELECT c.*,
            COALESCE(p.fullname, o.operatorname, u.email) as complainant_name,
            u.phonenumber as complainant_phone, u.role as complainant_role,
            r.rideid, r.entrytime, r.exittime, r.fareamountnpr,
            rt.routename, v.registrationnumber,
            COALESCE(ra.fullname, rp.fullname) as resolved_by_name
     FROM complaints c
     JOIN users u ON c.userid = u.userid
     LEFT JOIN passengers p ON c.passengerid = p.passengerid
     LEFT JOIN operators o ON u.userid = o.userid
     LEFT JOIN rides r ON c.rideid = r.rideid
     LEFT JOIN routes rt ON r.routeid = rt.routeid
     LEFT JOIN vehicles v ON r.vehicleid = v.vehicleid
     LEFT JOIN users ru ON c.resolvedby = ru.userid
     LEFT JOIN admins ra ON ru.userid = ra.userid
     LEFT JOIN passengers rp ON ru.userid = rp.userid
     WHERE c.complaintid = $1`,
    [id]
  );

  if (result.rows.length === 0) {
    throw new ApiError(404, 'Complaint not found');
  }

  const complaint = result.rows[0];

  // Check access - non-admin can only view their own complaints
  if (userRole !== 'Admin' && complaint.userid !== userId) {
    throw new ApiError(403, 'Access denied');
  }

  res.json({
    success: true,
    data: { complaint }
  });
});

/**
 * Create a new complaint
 * POST /api/complaints
 */
const createComplaint = asyncHandler(async (req, res) => {
  const { rideId, complaintText } = req.body;
  const userId = req.user.userid;
  const userRole = req.user.role;

  if (!complaintText) {
    throw new ApiError(400, 'Complaint text is required');
  }

  let passengerId = null;

  // If user is a passenger, look up their passengerid
  if (userRole === 'Passenger') {
    const passengerResult = await db.query(
      'SELECT passengerid FROM passengers WHERE userid = $1',
      [userId]
    );

    if (passengerResult.rows.length === 0) {
      throw new ApiError(403, 'Passenger profile not found');
    }

    passengerId = passengerResult.rows[0].passengerid;

    // If ride ID provided, verify it belongs to this passenger
    if (rideId) {
      const rideCheck = await db.query(
        'SELECT rideid FROM rides WHERE rideid = $1 AND passengerid = $2',
        [rideId, passengerId]
      );

      if (rideCheck.rows.length === 0) {
        throw new ApiError(400, 'Invalid ride ID or ride does not belong to you');
      }
    }
  }

  const result = await db.query(
    `INSERT INTO complaints (userid, passengerid, rideid, complainttext, complaintstatus)
     VALUES ($1, $2, $3, $4, 'Pending')
     RETURNING *`,
    [userId, passengerId, rideId || null, complaintText]
  );

  // Notify admin(s) about the new complaint
  try {
    const admins = await db.query("SELECT userid FROM users WHERE role = 'Admin'");
    const truncatedText = complaintText.length > 50 ? complaintText.substring(0, 50) + '...' : complaintText;

    for (const admin of admins.rows) {
      await db.query(
        `INSERT INTO notifications (userid, title, message, type)
         VALUES ($1, $2, $3, 'complaint')`,
        [admin.userid, 'New Complaint', `A new complaint has been filed: "${truncatedText}"`]
      );
    }

    // DB notifications already inserted above — app polls for them
  } catch (notifError) {
    // Don't fail the complaint creation if notification fails
    console.error('Failed to send complaint notification:', notifError.message);
  }

  res.status(201).json({
    success: true,
    message: 'Complaint submitted successfully',
    data: { complaint: result.rows[0] }
  });
});

/**
 * Update complaint (admin only - status/resolution)
 * PUT /api/complaints/:id
 */
const updateComplaint = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { status, resolution } = req.body;
  const adminUserId = req.user.userid;

  // Validate status
  const validStatuses = ['Pending', 'InProgress', 'Resolved', 'Rejected'];
  if (status && !validStatuses.includes(status)) {
    throw new ApiError(400, `Invalid status. Must be one of: ${validStatuses.join(', ')}`);
  }

  // Check if complaint exists
  const existingResult = await db.query(
    'SELECT complaintid FROM complaints WHERE complaintid = $1',
    [id]
  );

  if (existingResult.rows.length === 0) {
    throw new ApiError(404, 'Complaint not found');
  }

  // Build dynamic SET clause so both status and resolution update properly
  const updates = [];
  const params = [];

  if (status) {
    params.push(status);
    updates.push(`complaintstatus = $${params.length}`);
  }

  if (resolution !== undefined && resolution !== null) {
    params.push(resolution);
    updates.push(`resolutionnotes = $${params.length}`);
  }

  if (status === 'Resolved' || status === 'Rejected') {
    params.push(adminUserId);
    updates.push(`resolvedby = $${params.length}`);
    updates.push(`resolvedat = NOW()`);
  } else if (status === 'InProgress') {
    params.push(adminUserId);
    updates.push(`resolvedby = $${params.length}`);
    updates.push(`resolvedat = NULL`);
  }

  if (updates.length === 0) {
    throw new ApiError(400, 'No fields to update');
  }

  params.push(id);
  const result = await db.query(
    `UPDATE complaints
     SET ${updates.join(', ')}
     WHERE complaintid = $${params.length}
     RETURNING *`,
    params
  );

  if (status && ['Resolved', 'Rejected', 'InProgress'].includes(status)) {
    const statusLabel = status === 'InProgress' ? 'in progress' : status.toLowerCase();
    const noteText = resolution ? ` Notes: ${resolution}` : '';
    await notifyUser(result.rows[0].userid, 'Complaint Update', `Your complaint has been marked as ${statusLabel}.${noteText}`, 'complaint');
  }

  res.json({
    success: true,
    message: 'Complaint updated successfully',
    data: { complaint: result.rows[0] }
  });
});

/**
 * Delete complaint (passenger can delete only pending ones)
 * DELETE /api/complaints/:id
 */
const deleteComplaint = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.userid;
  const userRole = req.user.role;

  // Get the complaint
  const complaintResult = await db.query(
    `SELECT c.complaintid, c.complaintstatus, p.userid
     FROM complaints c
     JOIN passengers p ON c.passengerid = p.passengerid
     WHERE c.complaintid = $1`,
    [id]
  );

  if (complaintResult.rows.length === 0) {
    throw new ApiError(404, 'Complaint not found');
  }

  const complaint = complaintResult.rows[0];

  // Check permissions
  if (userRole !== 'Admin') {
    if (complaint.userid !== userId) {
      throw new ApiError(403, 'Access denied');
    }
    if (complaint.complaintstatus !== 'Pending') {
      throw new ApiError(400, 'Can only delete pending complaints');
    }
  }

  await db.query('DELETE FROM complaints WHERE complaintid = $1', [id]);

  res.json({
    success: true,
    message: 'Complaint deleted successfully'
  });
});

module.exports = {
  getComplaints,
  getComplaintById,
  createComplaint,
  updateComplaint,
  deleteComplaint
};
