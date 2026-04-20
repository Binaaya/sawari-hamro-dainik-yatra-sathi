const db = require('../config/database');
const { asyncHandler, ApiError } = require('../middleware/errorHandler');

/**
 * Get transactions with filters
 * GET /api/transactions
 */
const getTransactions = asyncHandler(async (req, res) => {
  const { userId, type, startDate, endDate, page = 1, limit = 20 } = req.query;

  let whereClause = 'WHERE 1=1';
  const params = [];

  if (userId) {
    params.push(userId);
    whereClause += ` AND t.userid = $${params.length}`;
  }

  if (type) {
    params.push(type);
    whereClause += ` AND t.transactiontype = $${params.length}`;
  }

  if (startDate) {
    params.push(startDate);
    whereClause += ` AND DATE(t.transactiontime) >= $${params.length}`;
  }

  if (endDate) {
    params.push(endDate);
    whereClause += ` AND DATE(t.transactiontime) <= $${params.length}`;
  }

  // Count total
  const countResult = await db.query(
    `SELECT COUNT(*) as total FROM transactions t ${whereClause}`,
    params
  );
  const total = parseInt(countResult.rows[0].total);

  // Get paginated results
  const offset = (page - 1) * limit;
  params.push(limit);
  params.push(offset);

  const result = await db.query(
    `SELECT t.*, COALESCE(p.fullname, a.fullname) as user_name
     FROM transactions t
     JOIN users u ON t.userid = u.userid
     LEFT JOIN passengers p ON u.userid = p.userid
     LEFT JOIN admins a ON u.userid = a.userid
     ${whereClause}
     ORDER BY t.transactiontime DESC
     LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  );

  res.json({
    success: true,
    data: {
      transactions: result.rows,
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
 * Get transaction by ID
 * GET /api/transactions/:id
 */
const getTransactionById = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const result = await db.query(
    `SELECT t.*, COALESCE(p.fullname, a.fullname) as user_name, u.phonenumber as user_phone,
            r.rideid, rt.routename
     FROM transactions t
     JOIN users u ON t.userid = u.userid
     LEFT JOIN passengers p ON u.userid = p.userid
     LEFT JOIN admins a ON u.userid = a.userid
     LEFT JOIN rides r ON t.rideid = r.rideid
     LEFT JOIN routes rt ON r.routeid = rt.routeid
     WHERE t.transactionid = $1`,
    [id]
  );

  if (result.rows.length === 0) {
    throw new ApiError(404, 'Transaction not found');
  }

  res.json({
    success: true,
    data: { transaction: result.rows[0] }
  });
});

/**
 * Get transaction summary/stats
 * GET /api/transactions/summary
 */
const getTransactionSummary = asyncHandler(async (req, res) => {
  const { userId, startDate, endDate } = req.query;

  let whereClause = 'WHERE 1=1';
  const params = [];

  if (userId) {
    params.push(userId);
    whereClause += ` AND userid = $${params.length}`;
  }

  if (startDate) {
    params.push(startDate);
    whereClause += ` AND DATE(transactiontime) >= $${params.length}`;
  }

  if (endDate) {
    params.push(endDate);
    whereClause += ` AND DATE(transactiontime) <= $${params.length}`;
  }

  const result = await db.query(
    `SELECT
       transactiontype,
       COUNT(*) as count,
       SUM(amountnpr) as total_amount,
       AVG(amountnpr) as avg_amount
     FROM transactions
     ${whereClause}
     GROUP BY transactiontype`,
    params
  );

  // Calculate totals
  const summary = {
    byType: result.rows,
    totals: {
      totalTransactions: 0,
      totalTopUps: 0,
      totalFares: 0,
      totalRefunds: 0
    }
  };

  result.rows.forEach(row => {
    summary.totals.totalTransactions += parseInt(row.count);
    if (row.transactiontype === 'TopUp') {
      summary.totals.totalTopUps = parseFloat(row.total_amount) || 0;
    } else if (row.transactiontype === 'RidePayment') {
      summary.totals.totalFares = parseFloat(row.total_amount) || 0;
    } else if (row.transactiontype === 'Refund') {
      summary.totals.totalRefunds = parseFloat(row.total_amount) || 0;
    }
  });

  res.json({
    success: true,
    data: { summary }
  });
});

module.exports = {
  getTransactions,
  getTransactionById,
  getTransactionSummary
};
