const express = require('express');
const router = express.Router();
const db = require('../config/database');

/**
 * Test route to check if API is working
 * GET /api/test
 */
router.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Sawari API is running!',
    timestamp: new Date().toISOString()
  });
});

/**
 * Test database connection
 * GET /api/test/db
 */
router.get('/db', async (req, res) => {
  try {
    const result = await db.query('SELECT NOW() as current_time');
    res.json({
      success: true,
      message: 'Database connection successful',
      data: {
        serverTime: result.rows[0].current_time
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Database connection failed',
      details: error.message
    });
  }
});

/**
 * Test route to get table counts
 * GET /api/test/stats
 */
router.get('/stats', async (req, res) => {
  try {
    const tables = ['users', 'passengers', 'operators', 'vehicles', 'drivers', 'routes', 'stops', 'rides', 'transactions', 'complaints'];
    const counts = {};

    for (const table of tables) {
      const result = await db.query(`SELECT COUNT(*) FROM ${table}`);
      counts[table] = parseInt(result.rows[0].count);
    }

    res.json({
      success: true,
      data: { tableCounts: counts }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;
