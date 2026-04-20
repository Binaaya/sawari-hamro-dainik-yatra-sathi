const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/payment.controller');
const { authenticate, requireRole } = require('../middleware/auth');

router.use(authenticate);
router.use(requireRole('Passenger'));

// POST /api/payments/khalti/initiate - Start a Khalti payment
router.post('/khalti/initiate', paymentController.initiateKhaltiPayment);

// POST /api/payments/khalti/verify - Verify & complete a Khalti payment
router.post('/khalti/verify', paymentController.verifyKhaltiPayment);

module.exports = router;
