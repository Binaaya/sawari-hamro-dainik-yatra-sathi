const express = require('express');
const router = express.Router();
const ridesController = require('../controllers/rides.controller');
const { authenticate, requireRole } = require('../middleware/auth');

// RFID Tap Endpoints (hardware/device)
const requireApiKey = (req, res, next) => {
  const apiKey = req.headers['x-api-key'];
  const validKey = process.env.RFID_API_KEY || 'sawari-rfid-secret-key';
  if (!apiKey || apiKey !== validKey) {
    return res.status(401).json({ success: false, error: 'Invalid or missing API key' });
  }
  next();
};

// POST /api/rides/tap-in - RFID tap at entry
router.post('/tap-in', requireApiKey, ridesController.tapIn);

// POST /api/rides/tap-out - RFID tap at exit
router.post('/tap-out', requireApiKey, ridesController.tapOut);

// Authenticated Ride Queries

// GET /api/rides/:id - Get ride details
router.get('/:id', authenticate, ridesController.getRideById);

// GET /api/rides/ongoing - Get current ongoing ride for authenticated passenger
router.get('/status/ongoing', authenticate, requireRole('Passenger'), ridesController.getOngoingRide);

module.exports = router;
