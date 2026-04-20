const express = require('express');
const router = express.Router();
const vehicleController = require('../controllers/vehicle.controller');

// API key authentication
const requireApiKey = (req, res, next) => {
  const apiKey = req.headers['x-api-key'];
  const validKey = process.env.RFID_API_KEY || 'sawari-rfid-secret-key';
  if (!apiKey || apiKey !== validKey) {
    return res.status(401).json({ success: false, error: 'Invalid or missing API key' });
  }
  next();
};

// POST /api/vehicles/:id/location — GPS phone sends location updates
router.post('/:id/location', requireApiKey, vehicleController.updateLocation);

// GET /api/vehicles/:id/location — check vehicle's current location
router.get('/:id/location', requireApiKey, vehicleController.getLocation);

module.exports = router;
