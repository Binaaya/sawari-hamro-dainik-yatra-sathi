const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');
const { authenticate, requireRole } = require('../middleware/auth');

// All routes require authentication and Admin role
router.use(authenticate);
router.use(requireRole('Admin'));

// Operator Approval

// GET /api/admin/operators/pending - Get pending operator approvals
router.get('/operators/pending', adminController.getPendingOperators);

// POST /api/admin/operators/:id/approve - Approve an operator
router.post('/operators/:id/approve', adminController.approveOperator);

// POST /api/admin/operators/:id/reject - Reject an operator
router.post('/operators/:id/reject', adminController.rejectOperator);

// GET /api/admin/operators - Get all operators
router.get('/operators', adminController.getAllOperators);

// Vehicle Approval

// GET /api/admin/vehicles/pending - Get pending vehicle approvals
router.get('/vehicles/pending', adminController.getPendingVehicles);

// POST /api/admin/vehicles/:id/approve - Approve a vehicle
router.post('/vehicles/:id/approve', adminController.approveVehicle);

// POST /api/admin/vehicles/:id/reject - Reject a vehicle
router.post('/vehicles/:id/reject', adminController.rejectVehicle);

// GET /api/admin/vehicles - Get all vehicles
router.get('/vehicles', adminController.getAllVehicles);

// RFID Card Management

// GET /api/admin/rfid-cards - Get all RFID cards
router.get('/rfid-cards', adminController.getRfidCards);

// POST /api/admin/rfid-cards/scan-assign - Scan and assign card to passenger
router.post('/rfid-cards/scan-assign', adminController.scanAssignRfidCard);

// POST /api/admin/rfid-cards/:id/deactivate - Deactivate a card
router.post('/rfid-cards/:id/deactivate', adminController.deactivateRfidCard);

// DELETE /api/admin/rfid-cards/:id - Delete a card permanently
router.delete('/rfid-cards/:id', adminController.deleteRfidCard);

// Passenger Management

// GET /api/admin/passengers - Get all passengers
router.get('/passengers', adminController.getPassengers);

// GET /api/admin/passengers/:id - Get passenger details
router.get('/passengers/:id', adminController.getPassenger);

// POST /api/admin/passengers/:id/topup - Cash top-up for passenger
router.post('/passengers/:id/topup', adminController.topUpPassenger);

// DELETE /api/admin/users/:id - Delete a user account
router.delete('/users/:id', adminController.deleteUser);

// Complaint Management

// GET /api/admin/complaints - Get all complaints
router.get('/complaints', adminController.getComplaints);

// GET /api/admin/complaints/:id - Get complaint details
router.get('/complaints/:id', adminController.getComplaint);

// PUT /api/admin/complaints/:id - Update complaint status
router.put('/complaints/:id', adminController.updateComplaint);

// Route Management

// GET /api/admin/routes - Get all routes with stats
router.get('/routes', adminController.getRoutes);

// POST /api/admin/routes - Create a new route
router.post('/routes', adminController.createRoute);

// PUT /api/admin/routes/:id - Update a route
router.put('/routes/:id', adminController.updateRoute);

// Stop Management

// GET /api/admin/stops - Get all stops
router.get('/stops', adminController.getStops);

// POST /api/admin/stops - Create a new stop
router.post('/stops', adminController.createStop);

// Fare Structure

// GET /api/admin/fare-structure - Get fare structure
router.get('/fare-structure', adminController.getFareStructure);

// PUT /api/admin/fare-structure - Update fare structure
router.put('/fare-structure', adminController.updateFareStructure);

// DELETE /api/admin/routes/:id - Delete a route
router.delete('/routes/:id', adminController.deleteRoute);

// GET /api/admin/routes/:id/stops - Get stops for a route
router.get('/routes/:id/stops', adminController.getRouteStops);

// PUT /api/admin/stops/:id - Update a stop
router.put('/stops/:id', adminController.updateStop);

// Vehicle Route Management

// GET /api/admin/vehicle-routes - Get all vehicle-route assignments
router.get('/vehicle-routes', adminController.getVehicleRoutes);

// POST /api/admin/vehicle-routes - Assign vehicle to route
router.post('/vehicle-routes', adminController.assignVehicleRoute);

// DELETE /api/admin/vehicle-routes/:vehicleId/:routeId - Remove vehicle from route
router.delete('/vehicle-routes/:vehicleId/:routeId', adminController.removeVehicleRoute);

// Reports & Dashboard

// GET /api/admin/dashboard - Get dashboard statistics
router.get('/dashboard', adminController.getDashboard);

// GET /api/admin/reports/rides - Get ride reports
router.get('/reports/rides', adminController.getRideReports);

// GET /api/admin/reports/revenue - Get revenue reports
router.get('/reports/revenue', adminController.getRevenueReports);

// GET /api/admin/reports/transactions - Get transaction reports
router.get('/reports/transactions', adminController.getTransactionReports);

module.exports = router;
