const db = require('../config/database');
const { asyncHandler, ApiError } = require('../middleware/errorHandler');

/**
 * Get passenger's current balance
 * GET /api/passengers/balance
 */
const getBalance = asyncHandler(async (req, res) => {
  const passengerId = req.user.passengerid;

  const result = await db.query(
    'SELECT accountbalancenpr FROM passengers WHERE passengerid = $1',
    [passengerId]
  );

  res.json({
    success: true,
    data: {
      balance: result.rows[0]?.accountbalancenpr || 0
    }
  });
});

/**
 * Get passenger's RFID card details
 * GET /api/passengers/rfid
 */
const getRfidCard = asyncHandler(async (req, res) => {
  const rfidCardId = req.user.rfidcardid;

  if (!rfidCardId) {
    return res.json({
      success: true,
      data: { rfidCard: null, message: 'No RFID card assigned' }
    });
  }

  const result = await db.query(
    'SELECT cardid, carduid, cardstatus, issuedat FROM rfidcards WHERE cardid = $1',
    [rfidCardId]
  );

  res.json({
    success: true,
    data: { rfidCard: result.rows[0] || null }
  });
});

/**
 * Get passenger's ride history
 * GET /api/passengers/rides
 */
const getRides = asyncHandler(async (req, res) => {
  const passengerId = req.user.passengerid;
  const { page = 1, limit = 20, status } = req.query;
  const offset = (page - 1) * limit;

  let whereClause = 'WHERE r.passengerid = $1';
  const params = [passengerId];

  if (status) {
    params.push(status);
    whereClause += ` AND r.ridestatus = $${params.length}`;
  }

  const ridesResult = await db.query(
    `SELECT r.rideid, r.ridestatus, r.fareamountnpr, r.entrytime, r.exittime,
            rt.routename, rt.routecode,
            es.stopname as entry_stop_name, xs.stopname as exit_stop_name,
            v.registrationnumber
     FROM rides r
     JOIN routes rt ON r.routeid = rt.routeid
     LEFT JOIN stops es ON r.entrystopid = es.stopid
     LEFT JOIN stops xs ON r.exitstopid = xs.stopid
     LEFT JOIN vehicles v ON r.vehicleid = v.vehicleid
     ${whereClause}
     ORDER BY r.entrytime DESC
     LIMIT $${params.length + 1} OFFSET $${params.length + 2}`,
    [...params, limit, offset]
  );

  const countResult = await db.query(
    `SELECT COUNT(*) FROM rides r ${whereClause}`,
    params
  );

  res.json({
    success: true,
    data: {
      rides: ridesResult.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: parseInt(countResult.rows[0].count)
      }
    }
  });
});

/**
 * Get passenger's transaction history
 * GET /api/passengers/transactions
 */
const getTransactions = asyncHandler(async (req, res) => {
  const userId = req.user.userid;
  const { page = 1, limit = 20, type } = req.query;
  const offset = (page - 1) * limit;

  let whereClause = 'WHERE t.userid = $1';
  const params = [userId];

  if (type) {
    params.push(type);
    whereClause += ` AND t.transactiontype = $${params.length}`;
  }

  const transactionsResult = await db.query(
    `SELECT t.transactionid, t.transactiontype, t.amountnpr,
            t.balancebeforenpr, t.balanceafternpr, t.transactiontime,
            r.rideid, rt.routename
     FROM transactions t
     LEFT JOIN rides r ON t.rideid = r.rideid
     LEFT JOIN routes rt ON r.routeid = rt.routeid
     ${whereClause}
     ORDER BY t.transactiontime DESC
     LIMIT $${params.length + 1} OFFSET $${params.length + 2}`,
    [...params, limit, offset]
  );

  const countResult = await db.query(
    `SELECT COUNT(*) FROM transactions t ${whereClause}`,
    params
  );

  res.json({
    success: true,
    data: {
      transactions: transactionsResult.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: parseInt(countResult.rows[0].count)
      }
    }
  });
});

/**
 * File a new complaint
 * POST /api/passengers/complaints
 */
const fileComplaint = asyncHandler(async (req, res) => {
  const passengerId = req.user.passengerid;
  const { rideId, complaintText } = req.body;

  if (!complaintText) {
    throw new ApiError(400, 'Complaint text is required');
  }

  // Verify ride belongs to passenger if provided
  if (rideId) {
    const rideCheck = await db.query(
      'SELECT rideid FROM rides WHERE rideid = $1 AND passengerid = $2',
      [rideId, passengerId]
    );
    if (rideCheck.rows.length === 0) {
      throw new ApiError(404, 'Ride not found or does not belong to you');
    }
  }

  const result = await db.query(
    `INSERT INTO complaints (passengerid, rideid, complainttext, complaintstatus)
     VALUES ($1, $2, $3, 'Pending')
     RETURNING complaintid, complainttext, complaintstatus, complaintdate`,
    [passengerId, rideId || null, complaintText]
  );

  res.status(201).json({
    success: true,
    message: 'Complaint filed successfully',
    data: { complaint: result.rows[0] }
  });
});

/**
 * Get passenger's complaints
 * GET /api/passengers/complaints
 */
const getMyComplaints = asyncHandler(async (req, res) => {
  const passengerId = req.user.passengerid;
  const { page = 1, limit = 20, status } = req.query;
  const offset = (page - 1) * limit;

  let whereClause = 'WHERE c.passengerid = $1';
  const params = [passengerId];

  if (status) {
    params.push(status);
    whereClause += ` AND c.complaintstatus = $${params.length}`;
  }

  const complaintsResult = await db.query(
    `SELECT c.complaintid, c.complainttext, c.complaintstatus,
            c.resolutionnotes, c.complaintdate, c.resolvedat,
            r.rideid, rt.routename
     FROM complaints c
     LEFT JOIN rides r ON c.rideid = r.rideid
     LEFT JOIN routes rt ON r.routeid = rt.routeid
     ${whereClause}
     ORDER BY c.complaintdate DESC
     LIMIT $${params.length + 1} OFFSET $${params.length + 2}`,
    [...params, limit, offset]
  );

  res.json({
    success: true,
    data: { complaints: complaintsResult.rows }
  });
});

/**
 * Get passenger profile
 * GET /api/passengers/profile
 */
const getProfile = asyncHandler(async (req, res) => {
  const userId = req.user.userid;

  const result = await db.query(
    `SELECT u.userid, u.firebaseuid, u.email, u.phonenumber, u.role, u.accountstatus, u.createdat,
            p.passengerid, p.fullname, p.citizenshipnumber, p.accountbalancenpr, p.rfidcardid
     FROM users u
     JOIN passengers p ON u.userid = p.userid
     WHERE u.userid = $1`,
    [userId]
  );

  if (result.rows.length === 0) {
    throw new ApiError(404, 'Passenger profile not found');
  }

  res.json({
    success: true,
    data: { user: result.rows[0] }
  });
});

module.exports = {
  getBalance,
  getRfidCard,
  getRides,
  getTransactions,
  fileComplaint,
  getMyComplaints,
  getProfile
};
