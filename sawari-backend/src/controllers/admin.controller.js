const db = require('../config/database');
const { asyncHandler, ApiError } = require('../middleware/errorHandler');
const { notifyUser } = require('./notifications.controller');

// Operator Approval

/**
 * Get pending operator approvals
 * GET /api/admin/operators/pending
 */
const getPendingOperators = asyncHandler(async (req, res) => {
  const result = await db.query(
    `SELECT o.operatorid, o.operatorname, o.documenturls, o.createdat,
            u.userid, u.email, u.phonenumber
     FROM operators o
     JOIN users u ON o.userid = u.userid
     WHERE o.approvalstatus = 'Pending'
     ORDER BY o.createdat ASC`
  );

  res.json({
    success: true,
    data: { operators: result.rows }
  });
});

/**
 * Approve an operator
 * POST /api/admin/operators/:id/approve
 */
const approveOperator = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const result = await db.query(
    `UPDATE operators SET approvalstatus = 'Approved', approvedat = NOW()
     WHERE operatorid = $1
     RETURNING *`,
    [id]
  );

  if (result.rows.length === 0) {
    throw new ApiError(404, 'Operator not found');
  }

  await notifyUser(result.rows[0].userid, 'Account Approved', 'Your operator account has been approved. You can now add and manage your fleet.', 'approval');

  res.json({
    success: true,
    message: 'Operator approved successfully',
    data: { operator: result.rows[0] }
  });
});

/**
 * Reject an operator
 * POST /api/admin/operators/:id/reject
 */
const rejectOperator = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { reason } = req.body;

  // For rejection, we could either delete or mark as rejected
  // Here we'll delete the operator record but keep the user
  const result = await db.query(
    `DELETE FROM operators WHERE operatorid = $1 RETURNING userid`,
    [id]
  );

  if (result.rows.length === 0) {
    throw new ApiError(404, 'Operator not found');
  }

  const reasonText = reason ? ` Reason: ${reason}` : '';
  await notifyUser(result.rows[0].userid, 'Application Rejected', `Your operator application has been rejected.${reasonText}`, 'rejection');

  res.json({
    success: true,
    message: 'Operator registration rejected'
  });
});

/**
 * Get all operators
 * GET /api/admin/operators
 */
const getAllOperators = asyncHandler(async (req, res) => {
  const { approved } = req.query;

  let whereClause = '';
  const params = [];

  if (approved !== undefined) {
    params.push(approved === 'true' ? 'Approved' : 'Pending');
    whereClause = 'WHERE o.approvalstatus = $1';
  }

  const result = await db.query(
    `SELECT o.operatorid, o.operatorname, o.documenturls, o.approvalstatus,
            o.createdat, o.approvedat,
            u.userid, u.email, u.phonenumber,
            COUNT(v.vehicleid) as vehicle_count
     FROM operators o
     JOIN users u ON o.userid = u.userid
     LEFT JOIN vehicles v ON o.operatorid = v.operatorid
     ${whereClause}
     GROUP BY o.operatorid, u.userid
     ORDER BY o.createdat DESC`,
    params
  );

  res.json({
    success: true,
    data: { operators: result.rows }
  });
});

// Vehicle Approval

/**
 * Get pending vehicle approvals
 * GET /api/admin/vehicles/pending
 */
const getPendingVehicles = asyncHandler(async (req, res) => {
  const result = await db.query(
    `SELECT v.vehicleid, v.registrationnumber, v.vehicletype, v.seatingcapacity,
            v.modelyear, v.documenturls, v.createdat,
            o.operatorid, o.operatorname
     FROM vehicles v
     JOIN operators o ON v.operatorid = o.operatorid
     WHERE v.approvalstatus = 'Pending'
     ORDER BY v.createdat ASC`
  );

  res.json({
    success: true,
    data: { vehicles: result.rows }
  });
});

/**
 * Approve a vehicle
 * POST /api/admin/vehicles/:id/approve
 */
const approveVehicle = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const result = await db.query(
    `UPDATE vehicles SET approvalstatus = 'Approved', approvedat = NOW()
     WHERE vehicleid = $1
     RETURNING *`,
    [id]
  );

  if (result.rows.length === 0) {
    throw new ApiError(404, 'Vehicle not found');
  }

  const operatorForVehicle = await db.query('SELECT userid FROM operators WHERE operatorid = $1', [result.rows[0].operatorid]);
  if (operatorForVehicle.rows.length > 0) {
    await notifyUser(operatorForVehicle.rows[0].userid, 'Vehicle Approved', `Your vehicle ${result.rows[0].registrationnumber} has been approved and is ready for service.`, 'approval');
  }

  res.json({
    success: true,
    message: 'Vehicle approved successfully',
    data: { vehicle: result.rows[0] }
  });
});

/**
 * Reject a vehicle
 * POST /api/admin/vehicles/:id/reject
 */
const rejectVehicle = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const result = await db.query(
    `DELETE FROM vehicles WHERE vehicleid = $1 AND approvalstatus = 'Pending'
     RETURNING vehicleid, operatorid, registrationnumber`,
    [id]
  );

  if (result.rows.length === 0) {
    throw new ApiError(404, 'Vehicle not found or already approved');
  }

  const operatorForRejected = await db.query('SELECT userid FROM operators WHERE operatorid = $1', [result.rows[0].operatorid]);
  if (operatorForRejected.rows.length > 0) {
    await notifyUser(operatorForRejected.rows[0].userid, 'Vehicle Rejected', `Your vehicle registration for ${result.rows[0].registrationnumber} was not approved.`, 'rejection');
  }

  res.json({
    success: true,
    message: 'Vehicle registration rejected'
  });
});

/**
 * Get all vehicles
 * GET /api/admin/vehicles
 */
const getAllVehicles = asyncHandler(async (req, res) => {
  const { operator_id, approved } = req.query;

  let whereClause = 'WHERE 1=1';
  const params = [];

  if (operator_id) {
    params.push(operator_id);
    whereClause += ` AND v.operatorid = $${params.length}`;
  }

  if (approved !== undefined) {
    params.push(approved === 'true' ? 'Approved' : 'Pending');
    whereClause += ` AND v.approvalstatus = $${params.length}`;
  }

  const result = await db.query(
    `SELECT v.*, o.operatorname,
            d.driversname as driver_name
     FROM vehicles v
     JOIN operators o ON v.operatorid = o.operatorid
     LEFT JOIN drivers d ON v.driverid = d.driverid
     ${whereClause}
     ORDER BY v.createdat DESC`,
    params
  );

  res.json({
    success: true,
    data: { vehicles: result.rows }
  });
});

// RFID Card Management

/**
 * Get all RFID cards
 * GET /api/admin/rfid-cards
 */
const getRfidCards = asyncHandler(async (req, res) => {
  const { status, unassigned } = req.query;

  let whereClause = 'WHERE 1=1';
  const params = [];

  if (status) {
    params.push(status);
    whereClause += ` AND rc.cardstatus = $${params.length}`;
  }

  if (unassigned === 'true') {
    whereClause += ' AND p.passengerid IS NULL';
  }

  const result = await db.query(
    `SELECT rc.cardid, rc.carduid, rc.cardstatus, rc.issuedat, rc.createdat,
            p.passengerid, p.fullname as passenger_name, u.phonenumber as passenger_phone
     FROM rfidcards rc
     LEFT JOIN passengers p ON rc.cardid = p.rfidcardid
     LEFT JOIN users u ON p.userid = u.userid
     ${whereClause}
     ORDER BY rc.createdat DESC`,
    params
  );

  res.json({
    success: true,
    data: { rfidCards: result.rows }
  });
});

/**
 * Deactivate RFID card
 * POST /api/admin/rfid-cards/:id/deactivate
 */
const deactivateRfidCard = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { reason } = req.body;

  await db.transaction(async (client) => {
    // Unassign from passenger first
    await client.query(
      'UPDATE passengers SET rfidcardid = NULL WHERE rfidcardid = $1',
      [id]
    );

    // Deactivate the card
    await client.query(
      `UPDATE rfidcards SET cardstatus = 'Inactive' WHERE cardid = $1`,
      [id]
    );
  });

  res.json({
    success: true,
    message: 'RFID card deactivated'
  });
});

/**
 * Delete RFID card permanently
 * DELETE /api/admin/rfid-cards/:id
 */
const deleteRfidCard = asyncHandler(async (req, res) => {
  const { id } = req.params;

  await db.transaction(async (client) => {
    // Only deactivated cards can be deleted
    const card = await client.query(
      'SELECT cardstatus FROM rfidcards WHERE cardid = $1',
      [id]
    );
    if (card.rows.length === 0) {
      throw new ApiError(404, 'RFID card not found');
    }
    if (card.rows[0].cardstatus !== 'Inactive') {
      throw new ApiError(400, 'Only deactivated cards can be deleted. Deactivate the card first.');
    }

    // Unassign from passenger if still linked
    await client.query(
      'UPDATE passengers SET rfidcardid = NULL WHERE rfidcardid = $1',
      [id]
    );

    // Delete the card
    await client.query(
      'DELETE FROM rfidcards WHERE cardid = $1',
      [id]
    );
  });

  res.json({
    success: true,
    message: 'RFID card deleted permanently'
  });
});

/**
 * Scan and assign RFID card to passenger
 * POST /api/admin/rfid-cards/scan-assign
 */
const scanAssignRfidCard = asyncHandler(async (req, res) => {
  const { cardUid, passengerId } = req.body;

  if (!cardUid || !passengerId) {
    throw new ApiError(400, 'Card UID and Passenger ID are required');
  }

  await db.transaction(async (client) => {
    // Check if this UID already exists
    const existing = await client.query(
      'SELECT rc.cardid, rc.cardstatus, p.passengerid, p.fullname FROM rfidcards rc LEFT JOIN passengers p ON rc.cardid = p.rfidcardid WHERE rc.carduid = $1',
      [cardUid]
    );

    if (existing.rows.length > 0) {
      const card = existing.rows[0];
      if (card.passengerid) {
        throw new ApiError(400, `This card is already assigned to ${card.fullname}`);
      }
      if (card.cardstatus !== 'Active') {
        throw new ApiError(400, 'This card has been deactivated');
      }
      // Card exists but unassigned — assign it
      await client.query('UPDATE passengers SET rfidcardid = $1 WHERE passengerid = $2', [card.cardid, passengerId]);
      await client.query('UPDATE rfidcards SET issuedat = NOW() WHERE cardid = $1', [card.cardid]);
    } else {
      // New UID — create card and assign
      const newCard = await client.query(
        "INSERT INTO rfidcards (carduid, cardstatus, issuedat) VALUES ($1, 'Active', NOW()) RETURNING cardid",
        [cardUid]
      );
      await client.query('UPDATE passengers SET rfidcardid = $1 WHERE passengerid = $2', [newCard.rows[0].cardid, passengerId]);
    }

    // Verify passenger was updated
    const verify = await client.query('SELECT rfidcardid FROM passengers WHERE passengerid = $1', [passengerId]);
    if (verify.rows.length === 0) {
      throw new ApiError(404, 'Passenger not found');
    }
  });

  const passengerUser = await db.query(
    'SELECT u.userid FROM passengers p JOIN users u ON p.userid = u.userid WHERE p.passengerid = $1',
    [passengerId]
  );
  if (passengerUser.rows.length > 0) {
    await notifyUser(passengerUser.rows[0].userid, 'RFID Card Assigned', 'An RFID card has been assigned to your account. You can now tap in/out for your rides.', 'rfid');
  }

  res.json({
    success: true,
    message: 'RFID card scanned and assigned successfully'
  });
});

// Passenger Management

/**
 * Get all passengers
 * GET /api/admin/passengers
 */
const getPassengers = asyncHandler(async (req, res) => {
  const { search, hasCard } = req.query;

  let whereClause = 'WHERE 1=1';
  const params = [];

  if (search) {
    params.push(`%${search}%`);
    whereClause += ` AND (p.fullname ILIKE $${params.length} OR u.phonenumber ILIKE $${params.length} OR u.email ILIKE $${params.length})`;
  }

  if (hasCard === 'true') {
    whereClause += ' AND p.rfidcardid IS NOT NULL';
  } else if (hasCard === 'false') {
    whereClause += ' AND p.rfidcardid IS NULL';
  }

  const result = await db.query(
    `SELECT p.passengerid, p.accountbalancenpr, p.rfidcardid, p.fullname,
            p.address, p.citizenshipnumber, p.profilepicture,
            u.userid, u.email, u.phonenumber, u.createdat,
            rc.carduid
     FROM passengers p
     JOIN users u ON p.userid = u.userid
     LEFT JOIN rfidcards rc ON p.rfidcardid = rc.cardid
     ${whereClause}
     ORDER BY u.createdat DESC`,
    params
  );

  res.json({
    success: true,
    data: { passengers: result.rows }
  });
});

/**
 * Get passenger details
 * GET /api/admin/passengers/:id
 */
const getPassenger = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const passengerResult = await db.query(
    `SELECT p.*, u.email, u.phonenumber, u.createdat,
            rc.carduid, rc.cardstatus as card_status
     FROM passengers p
     JOIN users u ON p.userid = u.userid
     LEFT JOIN rfidcards rc ON p.rfidcardid = rc.cardid
     WHERE p.passengerid = $1`,
    [id]
  );

  if (passengerResult.rows.length === 0) {
    throw new ApiError(404, 'Passenger not found');
  }

  // Get recent rides
  const ridesResult = await db.query(
    `SELECT r.rideid, r.ridestatus, r.fareamountnpr, r.entrytime, r.exittime,
            rt.routename
     FROM rides r
     JOIN routes rt ON r.routeid = rt.routeid
     WHERE r.passengerid = $1
     ORDER BY r.entrytime DESC
     LIMIT 10`,
    [id]
  );

  // Get recent transactions
  const transactionsResult = await db.query(
    `SELECT * FROM transactions
     WHERE userid = (SELECT userid FROM passengers WHERE passengerid = $1)
     ORDER BY transactiontime DESC
     LIMIT 10`,
    [id]
  );

  res.json({
    success: true,
    data: {
      passenger: passengerResult.rows[0],
      recentRides: ridesResult.rows,
      recentTransactions: transactionsResult.rows
    }
  });
});

/**
 * Update passenger details
 * PUT /api/admin/passengers/:id
 */
const updatePassenger = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { fullname, address } = req.body;

  // Check passenger exists
  const existing = await db.query(
    'SELECT passengerid FROM passengers WHERE passengerid = $1',
    [id]
  );
  if (existing.rows.length === 0) {
    throw new ApiError(404, 'Passenger not found');
  }

  const updates = [];
  const params = [];

  if (fullname !== undefined) {
    params.push(fullname);
    updates.push(`fullname = $${params.length}`);
  }
  if (address !== undefined) {
    params.push(address);
    updates.push(`address = $${params.length}`);
  }
  if (req.file) {
    params.push(`/uploads/passengers/${req.file.filename}`);
    updates.push(`profilepicture = $${params.length}`);
  }

  if (updates.length === 0) {
    throw new ApiError(400, 'No fields to update');
  }

  params.push(id);
  const result = await db.query(
    `UPDATE passengers SET ${updates.join(', ')} WHERE passengerid = $${params.length} RETURNING *`,
    params
  );

  res.json({
    success: true,
    message: 'Passenger updated successfully',
    data: { passenger: result.rows[0] }
  });
});

/**
 * Cash top-up for passenger
 * POST /api/admin/passengers/:id/topup
 */
const topUpPassenger = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { amount, receiptNumber } = req.body;
  const adminUserId = req.user.userid;

  if (!amount || amount < 50) {
    throw new ApiError(400, 'Minimum top-up amount is NPR 50');
  }

  if (amount % 5 !== 0) {
    throw new ApiError(400, 'Top-up amount must be a multiple of 5');
  }

  const result = await db.transaction(async (client) => {
    // Get admin's actual adminid from admins table
    const adminResult = await client.query(
      'SELECT adminid FROM admins WHERE userid = $1',
      [adminUserId]
    );

    if (adminResult.rows.length === 0) {
      throw new ApiError(403, 'Admin record not found');
    }

    const adminId = adminResult.rows[0].adminid;

    // Get current balance and userid
    const passengerResult = await client.query(
      'SELECT accountbalancenpr, userid FROM passengers WHERE passengerid = $1',
      [id]
    );

    if (passengerResult.rows.length === 0) {
      throw new ApiError(404, 'Passenger not found');
    }

    const currentBalance = parseFloat(passengerResult.rows[0].accountbalancenpr);
    const userId = passengerResult.rows[0].userid;
    const tokensToAdd = amount / 5;
    const newBalance = currentBalance + tokensToAdd;

    // Update balance (stored as tokens, 5 NPR = 1 token)
    await client.query(
      'UPDATE passengers SET accountbalancenpr = $1 WHERE passengerid = $2',
      [newBalance, id]
    );

    // Create transaction record
    const txResult = await client.query(
      `INSERT INTO transactions (userid, transactiontype, amountnpr, balancebeforenpr, balanceafternpr, paymentmethod)
       VALUES ($1, 'TopUp', $2, $3, $4, 'Cash')
       RETURNING transactionid`,
      [userId, amount, currentBalance, newBalance]
    );

    // Create top-up history record
    await client.query(
      `INSERT INTO topuphistory (transactionid, passengerid, topupamount, paymentmethod, adminid)
       VALUES ($1, $2, $3, 'Cash', $4)`,
      [txResult.rows[0].transactionid, id, amount, adminId]
    );

    return { currentBalance, newBalance, amount, userId };
  });

  await notifyUser(result.userId, 'Top-up Successful', `NPR ${result.amount} has been added to your account. New balance: ${result.newBalance} tokens.`, 'topup');

  res.json({
    success: true,
    message: 'Top-up successful',
    data: result
  });
});

/**
 * Delete a user account (admin only)
 * DELETE /api/admin/users/:id
 */
const deleteUser = asyncHandler(async (req, res) => {
  const { id } = req.params; // userid

  const result = await db.transaction(async (client) => {
    // Get user info including Firebase UID
    const userResult = await client.query(
      'SELECT userid, firebaseuid, email, role FROM users WHERE userid = $1',
      [id]
    );

    if (userResult.rows.length === 0) {
      throw new ApiError(404, 'User not found');
    }

    const user = userResult.rows[0];

    // Prevent deleting admin accounts
    if (user.role === 'Admin') {
      throw new ApiError(403, 'Cannot delete admin accounts');
    }

    // Delete role-specific records (cascading dependencies)
    if (user.role === 'Passenger') {
      const passengerResult = await client.query(
        'SELECT passengerid, rfidcardid FROM passengers WHERE userid = $1',
        [id]
      );

      if (passengerResult.rows.length > 0) {
        const { passengerid, rfidcardid } = passengerResult.rows[0];

        await client.query('DELETE FROM topuphistory WHERE passengerid = $1', [passengerid]);
        await client.query('DELETE FROM rides WHERE passengerid = $1', [passengerid]);

        if (rfidcardid) {
          await client.query('UPDATE passengers SET rfidcardid = NULL WHERE passengerid = $1', [passengerid]);
          await client.query('DELETE FROM rfidcards WHERE cardid = $1', [rfidcardid]);
        }

        await client.query('DELETE FROM passengers WHERE passengerid = $1', [passengerid]);
      }
    } else if (user.role === 'Operator') {
      // Delete vehicles and related data
      await client.query(
        'DELETE FROM vehicles WHERE operatorid = (SELECT operatorid FROM operators WHERE userid = $1)',
        [id]
      );
      await client.query('DELETE FROM operators WHERE userid = $1', [id]);
    }

    // Delete transactions
    await client.query('DELETE FROM transactions WHERE userid = $1', [id]);
    // Delete complaints
    await client.query('DELETE FROM complaints WHERE userid = $1', [id]);
    // Delete notifications
    await client.query('DELETE FROM notifications WHERE userid = $1', [id]);
    // Delete device tokens
    await client.query('DELETE FROM device_tokens WHERE userid = $1', [id]);
    // Delete user record
    await client.query('DELETE FROM users WHERE userid = $1', [id]);

    // Delete from Firebase Auth
    try {
      const firebase = require('../config/firebase');
      await firebase.auth.deleteUser(user.firebaseuid);
    } catch (fbError) {
      console.error('Failed to delete Firebase user:', fbError.message);
      // Proceed even if Firebase deletion fails
    }

    return { email: user.email, role: user.role };
  });

  res.json({
    success: true,
    message: `User ${result.email} (${result.role}) deleted successfully`
  });
});

// Complaint Management

/**
 * Get all complaints
 * GET /api/admin/complaints
 */
const getComplaints = asyncHandler(async (req, res) => {
  const { status } = req.query;

  let whereClause = 'WHERE 1=1';
  const params = [];

  if (status) {
    params.push(status);
    whereClause += ` AND c.complaintstatus = $${params.length}`;
  }

  const result = await db.query(
    `SELECT c.*,
            COALESCE(p.fullname, o.operatorname, u.email) as passenger_name,
            u.phonenumber as passenger_phone, u.email as passenger_email,
            r.rideid, rt.routename
     FROM complaints c
     JOIN users u ON c.userid = u.userid
     LEFT JOIN passengers p ON c.passengerid = p.passengerid
     LEFT JOIN operators o ON u.userid = o.userid
     LEFT JOIN rides r ON c.rideid = r.rideid
     LEFT JOIN routes rt ON r.routeid = rt.routeid
     ${whereClause}
     ORDER BY c.complaintdate DESC`,
    params
  );

  res.json({
    success: true,
    data: { complaints: result.rows }
  });
});

/**
 * Get complaint details
 * GET /api/admin/complaints/:id
 */
const getComplaint = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const result = await db.query(
    `SELECT c.*,
            COALESCE(p.fullname, o.operatorname, u.email) as passenger_name,
            u.phonenumber as passenger_phone, u.email as passenger_email,
            r.rideid, r.entrytime, r.exittime, r.fareamountnpr,
            rt.routename, v.registrationnumber,
            es.stopname as entry_stop, xs.stopname as exit_stop
     FROM complaints c
     JOIN users u ON c.userid = u.userid
     LEFT JOIN passengers p ON c.passengerid = p.passengerid
     LEFT JOIN operators o ON u.userid = o.userid
     LEFT JOIN rides r ON c.rideid = r.rideid
     LEFT JOIN routes rt ON r.routeid = rt.routeid
     LEFT JOIN vehicles v ON r.vehicleid = v.vehicleid
     LEFT JOIN stops es ON r.entrystopid = es.stopid
     LEFT JOIN stops xs ON r.exitstopid = xs.stopid
     WHERE c.complaintid = $1`,
    [id]
  );

  if (result.rows.length === 0) {
    throw new ApiError(404, 'Complaint not found');
  }

  res.json({
    success: true,
    data: { complaint: result.rows[0] }
  });
});

/**
 * Update complaint status
 * PUT /api/admin/complaints/:id
 */
const updateComplaint = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { status, resolution } = req.body;
  const adminUserId = req.user.userid;

  const validStatuses = ['Pending', 'InProgress', 'Resolved', 'Rejected'];
  if (status && !validStatuses.includes(status)) {
    throw new ApiError(400, `Invalid status. Must be one of: ${validStatuses.join(', ')}`);
  }

  // Build dynamic SET clause so both status and resolution update in one take
  const updates = [];
  const params = [];

  if (status) {
    params.push(status);
    updates.push(`complaintstatus = $${params.length}`);
  }

  // Always update resolution notes when provided (even empty string to clear)
  if (resolution !== undefined && resolution !== null) {
    params.push(resolution);
    updates.push(`resolutionnotes = $${params.length}`);
  }

  // Set resolvedby and resolvedat when status is terminal
  if (status === 'Resolved' || status === 'Rejected') {
    params.push(adminUserId);
    updates.push(`resolvedby = $${params.length}`);
    updates.push(`resolvedat = NOW()`);
  } else if (status === 'InProgress') {
    params.push(adminUserId);
    updates.push(`resolvedby = $${params.length}`);
    // Clear resolvedat when moving back to in-progress
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

  if (result.rows.length === 0) {
    throw new ApiError(404, 'Complaint not found');
  }

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

// Route Management

/**
 * Get all routes with stats
 * GET /api/admin/routes
 */
const getRoutes = asyncHandler(async (req, res) => {
  const result = await db.query(
    `SELECT r.routeid, r.routename, r.routecode, r.isactive, r.maxfarenpr,
            COUNT(DISTINCT rs.stopid) as stop_count,
            COUNT(DISTINCT vr.vehicleid) as vehicle_count
     FROM routes r
     LEFT JOIN routestops rs ON r.routeid = rs.routeid
     LEFT JOIN vehicleroutes vr ON r.routeid = vr.routeid
     GROUP BY r.routeid
     ORDER BY r.routecode`
  );

  res.json({
    success: true,
    data: { routes: result.rows }
  });
});

/**
 * Create a new route with 6 stops
 * POST /api/admin/routes
 */
const createRoute = asyncHandler(async (req, res) => {
  const { routeName, stops } = req.body;

  if (!routeName) throw new ApiError(400, 'Route name is required');
  if (!Array.isArray(stops) || stops.length !== 6) throw new ApiError(400, 'Exactly 6 stops are required');
  if (new Set(stops).size !== 6) throw new ApiError(400, 'All 6 stops must be different');

  const route = await db.transaction(async (client) => {
    const codeResult = await client.query(
      `SELECT COALESCE(MAX(CAST(SUBSTRING(routecode FROM 3) AS INT)), 0) + 1 AS next_num FROM routes`
    );
    const routeCode = `R-${codeResult.rows[0].next_num}`;

    const routeResult = await client.query(
      `INSERT INTO routes (routename, routecode, maxfarenpr, isactive)
       VALUES ($1, $2, 25, true) RETURNING *`,
      [routeName, routeCode]
    );
    const newRoute = routeResult.rows[0];

    for (let i = 0; i < stops.length; i++) {
      await client.query(
        `INSERT INTO routestops (routeid, stopid, stopsequence) VALUES ($1, $2, $3)`,
        [newRoute.routeid, stops[i], i + 1]
      );
    }

    return newRoute;
  });

  res.status(201).json({
    success: true,
    message: 'Route created successfully',
    data: { route }
  });
});

/**
 * Update a route
 * PUT /api/admin/routes/:id
 */
const updateRoute = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { routeName, isActive, stops } = req.body;

  const route = await db.transaction(async (client) => {
    const routeResult = await client.query(
      `UPDATE routes SET routename = COALESCE($1, routename), isactive = COALESCE($2, isactive)
       WHERE routeid = $3 RETURNING *`,
      [routeName, isActive, id]
    );
    if (routeResult.rows.length === 0) throw new ApiError(404, 'Route not found');

    if (Array.isArray(stops) && stops.length === 6) {
      if (new Set(stops).size !== 6) throw new ApiError(400, 'All 6 stops must be different');
      await client.query('DELETE FROM routestops WHERE routeid = $1', [id]);
      for (let i = 0; i < stops.length; i++) {
        await client.query(
          `INSERT INTO routestops (routeid, stopid, stopsequence) VALUES ($1, $2, $3)`,
          [id, stops[i], i + 1]
        );
      }
    }

    return routeResult.rows[0];
  });

  res.json({
    success: true,
    message: 'Route updated successfully',
    data: { route }
  });
});

/**
 * Delete a route and all its assignments
 * DELETE /api/admin/routes/:id
 */
const deleteRoute = asyncHandler(async (req, res) => {
  const { id } = req.params;

  await db.transaction(async (client) => {
    await client.query('DELETE FROM farestructure WHERE routeid = $1', [id]);
    await client.query('DELETE FROM vehicleroutes WHERE routeid = $1', [id]);
    await client.query('DELETE FROM routestops WHERE routeid = $1', [id]);
    const result = await client.query('DELETE FROM routes WHERE routeid = $1 RETURNING routeid', [id]);
    if (result.rows.length === 0) throw new ApiError(404, 'Route not found');
  });

  res.json({ success: true, message: 'Route deleted successfully' });
});

/**
 * Get stops for a specific route
 * GET /api/admin/routes/:id/stops
 */
const getRouteStops = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const result = await db.query(
    `SELECT rs.stopsequence, s.stopid, s.stopname, s.latitude, s.longitude
     FROM routestops rs
     JOIN stops s ON rs.stopid = s.stopid
     WHERE rs.routeid = $1
     ORDER BY rs.stopsequence`,
    [id]
  );

  res.json({
    success: true,
    data: { stops: result.rows }
  });
});

// Stop Management

/**
 * Get all stops
 * GET /api/admin/stops
 */
const getStops = asyncHandler(async (req, res) => {
  const result = await db.query(
    `SELECT s.stopid, s.stopname, s.latitude, s.longitude,
            COUNT(rs.routeid) as route_count
     FROM stops s
     LEFT JOIN routestops rs ON s.stopid = rs.stopid
     GROUP BY s.stopid
     ORDER BY s.stopname`
  );

  res.json({
    success: true,
    data: { stops: result.rows }
  });
});

/**
 * Create a new stop
 * POST /api/admin/stops
 */
const createStop = asyncHandler(async (req, res) => {
  const { stopName, latitude, longitude } = req.body;

  if (!stopName) {
    throw new ApiError(400, 'Stop name is required');
  }

  const result = await db.query(
    `INSERT INTO stops (stopname, latitude, longitude)
     VALUES ($1, $2, $3)
     RETURNING *`,
    [stopName, latitude, longitude]
  );

  res.status(201).json({
    success: true,
    message: 'Stop created successfully',
    data: { stop: result.rows[0] }
  });
});

/**
 * Update a stop name
 * PUT /api/admin/stops/:id
 */
const updateStop = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { stopName } = req.body;

  if (!stopName) throw new ApiError(400, 'Stop name is required');

  const result = await db.query(
    `UPDATE stops SET stopname = $1 WHERE stopid = $2 RETURNING *`,
    [stopName, id]
  );

  if (result.rows.length === 0) throw new ApiError(404, 'Stop not found');

  res.json({
    success: true,
    message: 'Stop updated successfully',
    data: { stop: result.rows[0] }
  });
});

// Fare Structure

/**
 * Get fare structure
 * GET /api/admin/fare-structure
 */
const getFareStructure = asyncHandler(async (req, res) => {
  const { routeId } = req.query;

  let whereClause = '';
  const params = [];

  if (routeId) {
    params.push(routeId);
    whereClause = 'WHERE fs.routeid = $1';
  }

  const result = await db.query(
    `SELECT fs.*, r.routename
     FROM farestructure fs
     JOIN routes r ON fs.routeid = r.routeid
     ${whereClause}
     ORDER BY fs.routeid, fs.fromstopsequence, fs.tostopsequence`,
    params
  );

  res.json({
    success: true,
    data: { fareStructure: result.rows }
  });
});

/**
 * Update fare structure
 * PUT /api/admin/fare-structure
 */
const updateFareStructure = asyncHandler(async (req, res) => {
  const { routeId, fromSequence, toSequence, fareNpr } = req.body;

  if (!routeId || fromSequence === undefined || toSequence === undefined || !fareNpr) {
    throw new ApiError(400, 'Route ID, from/to sequence, and fare are required');
  }

  const result = await db.query(
    `INSERT INTO farestructure (routeid, fromstopsequence, tostopsequence, fareamountnpr)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (routeid, fromstopsequence, tostopsequence)
     DO UPDATE SET fareamountnpr = $4
     RETURNING *`,
    [routeId, fromSequence, toSequence, fareNpr]
  );

  res.json({
    success: true,
    message: 'Fare structure updated',
    data: { fare: result.rows[0] }
  });
});

// Vehicle Route Management

/**
 * Get all vehicle-route assignments
 * GET /api/admin/vehicle-routes
 */
const getVehicleRoutes = asyncHandler(async (req, res) => {
  const result = await db.query(
    `SELECT vr.vehicleid, vr.routeid, vr.isactive,
            v.registrationnumber, v.vehicletype,
            r.routename, r.routecode,
            o.operatorname
     FROM vehicleroutes vr
     JOIN vehicles v ON vr.vehicleid = v.vehicleid
     JOIN routes r ON vr.routeid = r.routeid
     JOIN operators o ON v.operatorid = o.operatorid
     ORDER BY r.routecode, v.registrationnumber`
  );

  res.json({
    success: true,
    data: { vehicleRoutes: result.rows }
  });
});

/**
 * Assign a vehicle to a route
 * POST /api/admin/vehicle-routes
 */
const assignVehicleRoute = asyncHandler(async (req, res) => {
  const { vehicleId, routeId } = req.body;

  if (!vehicleId || !routeId) throw new ApiError(400, 'Vehicle ID and Route ID are required');

  const result = await db.query(
    `INSERT INTO vehicleroutes (vehicleid, routeid, isactive)
     VALUES ($1, $2, true)
     ON CONFLICT (vehicleid, routeid) DO UPDATE SET isactive = true
     RETURNING *`,
    [vehicleId, routeId]
  );

  res.json({
    success: true,
    message: 'Vehicle assigned to route',
    data: { vehicleRoute: result.rows[0] }
  });
});

/**
 * Remove a vehicle from a route
 * DELETE /api/admin/vehicle-routes/:vehicleId/:routeId
 */
const removeVehicleRoute = asyncHandler(async (req, res) => {
  const { vehicleId, routeId } = req.params;

  const result = await db.query(
    `DELETE FROM vehicleroutes WHERE vehicleid = $1 AND routeid = $2 RETURNING *`,
    [vehicleId, routeId]
  );

  if (result.rows.length === 0) throw new ApiError(404, 'Vehicle route assignment not found');

  res.json({ success: true, message: 'Vehicle removed from route' });
});

// Dashboard & Reports

/**
 * Get admin dashboard statistics
 * GET /api/admin/dashboard
 */
const getDashboard = asyncHandler(async (req, res) => {
  const [passengers, operators, vehicles, rides, revenue, complaints, newPassengers] = await Promise.all([
    db.query('SELECT COUNT(*) as total FROM passengers'),
    db.query(`SELECT COUNT(*) as total, SUM(CASE WHEN approvalstatus = 'Approved' THEN 1 ELSE 0 END) as approved FROM operators`),
    db.query(`SELECT COUNT(*) as total, SUM(CASE WHEN approvalstatus = 'Approved' THEN 1 ELSE 0 END) as approved FROM vehicles`),
    db.query(`SELECT COUNT(*) as total,
              SUM(CASE WHEN DATE(entrytime) = CURRENT_DATE THEN 1 ELSE 0 END) as today
              FROM rides WHERE ridestatus = 'Completed'`),
    db.query(`SELECT COALESCE(SUM(fareamountnpr), 0) as total,
              COALESCE(SUM(CASE WHEN DATE(entrytime) = CURRENT_DATE THEN fareamountnpr ELSE 0 END), 0) as today
              FROM rides WHERE ridestatus = 'Completed'`),
    db.query('SELECT COUNT(*) as total, SUM(CASE WHEN complaintstatus = \'Pending\' THEN 1 ELSE 0 END) as pending FROM complaints'),
    db.query(`SELECT COUNT(*) as total FROM passengers p JOIN users u ON p.userid = u.userid WHERE DATE(u.createdat) = CURRENT_DATE`)
  ]);

  // Flat response format expected by dashboard frontend
  res.json({
    success: true,
    data: {
      totalPassengers: parseInt(passengers.rows[0].total),
      totalOperators: parseInt(operators.rows[0].approved) || 0,
      approvedOperators: parseInt(operators.rows[0].approved) || 0,
      pendingOperators: parseInt(operators.rows[0].total) - (parseInt(operators.rows[0].approved) || 0),
      totalVehicles: parseInt(vehicles.rows[0].total),
      approvedVehicles: parseInt(vehicles.rows[0].approved) || 0,
      totalRides: parseInt(rides.rows[0].total),
      todayRides: parseInt(rides.rows[0].today) || 0,
      totalRevenue: parseFloat(revenue.rows[0].total),
      todayRevenue: parseFloat(revenue.rows[0].today) || 0,
      totalComplaints: parseInt(complaints.rows[0].total),
      pendingComplaints: parseInt(complaints.rows[0].pending) || 0,
      newPassengersToday: parseInt(newPassengers.rows[0].total) || 0
    }
  });
});

/**
 * Get ride reports
 * GET /api/admin/reports/rides
 */
const getRideReports = asyncHandler(async (req, res) => {
  const { startDate, endDate, routeId } = req.query;

  let whereClause = 'WHERE 1=1';
  const params = [];

  if (startDate) {
    params.push(startDate);
    whereClause += ` AND DATE(r.entrytime) >= $${params.length}`;
  }

  if (endDate) {
    params.push(endDate);
    whereClause += ` AND DATE(r.entrytime) <= $${params.length}`;
  }

  if (routeId) {
    params.push(routeId);
    whereClause += ` AND r.routeid = $${params.length}`;
  }

  const result = await db.query(
    `SELECT r.rideid, r.ridestatus, r.fareamountnpr, r.entrytime, r.exittime,
            p.fullname as passenger_name, rt.routename,
            es.stopname as entry_stop, xs.stopname as exit_stop
     FROM rides r
     JOIN passengers p ON r.passengerid = p.passengerid
     JOIN routes rt ON r.routeid = rt.routeid
     LEFT JOIN stops es ON r.entrystopid = es.stopid
     LEFT JOIN stops xs ON r.exitstopid = xs.stopid
     ${whereClause}
     ORDER BY r.entrytime DESC
     LIMIT 200`,
    params
  );

  res.json({
    success: true,
    data: { rides: result.rows }
  });
});

/**
 * Get revenue reports
 * GET /api/admin/reports/revenue
 */
const getRevenueReports = asyncHandler(async (req, res) => {
  const { startDate, endDate, groupBy = 'day' } = req.query;

  let dateFormat, dateLabel;
  switch (groupBy) {
    case 'month':
      dateFormat = "TO_CHAR(entrytime, 'YYYY-MM')";
      dateLabel = 'period';
      break;
    case 'week':
      dateFormat = "TO_CHAR(DATE_TRUNC('week', entrytime), 'YYYY-\"W\"IW')";
      dateLabel = 'period';
      break;
    default:
      dateFormat = "TO_CHAR(DATE(entrytime), 'YYYY-MM-DD')";
      dateLabel = 'period';
  }

  let whereClause = "WHERE ridestatus = 'Completed'";
  const params = [];

  if (startDate) {
    params.push(startDate);
    whereClause += ` AND DATE(entrytime) >= $${params.length}`;
  }

  if (endDate) {
    params.push(endDate);
    whereClause += ` AND DATE(entrytime) <= $${params.length}`;
  }

  const result = await db.query(
    `SELECT ${dateFormat} as period,
            COUNT(*) as total_rides,
            COUNT(*) as completed_rides,
            COALESCE(SUM(fareamountnpr), 0) as total_revenue,
            ROUND(COALESCE(AVG(fareamountnpr), 0), 2) as avg_fare
     FROM rides
     ${whereClause}
     GROUP BY period
     ORDER BY period DESC`,
    params
  );

  res.json({
    success: true,
    data: { revenue: result.rows }
  });
});

/**
 * Get transaction reports
 * GET /api/admin/reports/transactions
 */
const getTransactionReports = asyncHandler(async (req, res) => {
  const { startDate, endDate, type } = req.query;

  let whereClause = 'WHERE 1=1';
  const params = [];

  if (startDate) {
    params.push(startDate);
    whereClause += ` AND DATE(t.transactiontime) >= $${params.length}`;
  }

  if (endDate) {
    params.push(endDate);
    whereClause += ` AND DATE(t.transactiontime) <= $${params.length}`;
  }

  if (type) {
    params.push(type);
    whereClause += ` AND t.transactiontype = $${params.length}`;
  }

  const result = await db.query(
    `SELECT t.transactionid, t.transactiontype, t.amountnpr,
            t.balancebeforenpr, t.balanceafternpr, t.transactiontime,
            t.paymentmethod,
            COALESCE(p.fullname, u.email) as fullname
     FROM transactions t
     JOIN users u ON t.userid = u.userid
     LEFT JOIN passengers p ON u.userid = p.userid
     ${whereClause}
     ORDER BY t.transactiontime DESC
     LIMIT 200`,
    params
  );

  res.json({
    success: true,
    data: { transactions: result.rows }
  });
});

module.exports = {
  getPendingOperators,
  approveOperator,
  rejectOperator,
  getAllOperators,
  getPendingVehicles,
  approveVehicle,
  rejectVehicle,
  getAllVehicles,
  getRfidCards,
  scanAssignRfidCard,
  deactivateRfidCard,
  deleteRfidCard,
  getPassengers,
  getPassenger,
  updatePassenger,
  topUpPassenger,
  getComplaints,
  getComplaint,
  updateComplaint,
  getRoutes,
  createRoute,
  updateRoute,
  deleteRoute,
  getRouteStops,
  getStops,
  createStop,
  updateStop,
  getFareStructure,
  updateFareStructure,
  getVehicleRoutes,
  assignVehicleRoute,
  removeVehicleRoute,
  getDashboard,
  getRideReports,
  getRevenueReports,
  getTransactionReports,
  deleteUser
};
