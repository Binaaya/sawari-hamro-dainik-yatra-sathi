const express = require('express');
const router = express.Router();
const transactionsController = require('../controllers/transactions.controller');
const { authenticate, requireRole } = require('../middleware/auth');

// All routes require authentication
router.use(authenticate);

// GET /api/transactions - Get transactions (filtered by role)
// Passengers see their own, Admins see all
router.get('/', transactionsController.getTransactions);

// GET /api/transactions/:id - Get transaction details
router.get('/:id', transactionsController.getTransactionById);

// GET /api/transactions/summary - Get transaction summary/stats
router.get('/stats/summary', transactionsController.getTransactionSummary);

module.exports = router;
