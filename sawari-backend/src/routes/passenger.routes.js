const express = require('express');
const router = express.Router();
const passengerController = require('../controllers/passenger.controller');
const { authenticate, requireRole } = require('../middleware/auth');

// All routes require authentication and Passenger role
router.use(authenticate);
router.use(requireRole('Passenger'));

// GET /api/passengers/profile - Get passenger profile
router.get('/profile', passengerController.getProfile);

// GET /api/passengers/balance - Get current balance
router.get('/balance', passengerController.getBalance);

// GET /api/passengers/rfid - Get RFID card details
router.get('/rfid', passengerController.getRfidCard);

// GET /api/passengers/rides - Get ride history
router.get('/rides', passengerController.getRides);

// GET /api/passengers/transactions - Get transaction history
router.get('/transactions', passengerController.getTransactions);

// POST /api/passengers/complaints - File a new complaint
router.post('/complaints', passengerController.fileComplaint);

// GET /api/passengers/complaints - Get my complaints
router.get('/complaints', passengerController.getMyComplaints);

module.exports = router;
