const express = require('express');
const router = express.Router();
const complaintsController = require('../controllers/complaints.controller');
const { authenticate, requireRole } = require('../middleware/auth');

// All routes require authentication
router.use(authenticate);

// GET /api/complaints - Get complaints (filtered by role)
router.get('/', complaintsController.getComplaints);

// GET /api/complaints/:id - Get complaint details
router.get('/:id', complaintsController.getComplaintById);

// POST /api/complaints - Create a new complaint (Passenger or Operator)
router.post('/', requireRole('Passenger', 'Operator'), complaintsController.createComplaint);

// PUT /api/complaints/:id - Update complaint (Admin only)
router.put('/:id', requireRole('Admin'), complaintsController.updateComplaint);

module.exports = router;
