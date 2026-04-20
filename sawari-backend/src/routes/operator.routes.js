const express = require('express');
const router = express.Router();
const operatorController = require('../controllers/operator.controller');
const { authenticate, requireRole, requireApprovedOperator } = require('../middleware/auth');
const { vehicleUpload } = require('../middleware/upload');

// All routes require authentication and Operator role
router.use(authenticate);
router.use(requireRole('Operator'));

// Vehicle Management

// GET /api/operators/vehicles - Get all vehicles for this operator
router.get('/vehicles', requireApprovedOperator, operatorController.getVehicles);

// POST /api/operators/vehicles - Register a new vehicle
router.post('/vehicles', requireApprovedOperator, vehicleUpload.single('bluebook'), operatorController.createVehicle);

// GET /api/operators/vehicles/:id - Get vehicle details
router.get('/vehicles/:id', requireApprovedOperator, operatorController.getVehicle);

// PUT /api/operators/vehicles/:id - Update vehicle details
router.put('/vehicles/:id', requireApprovedOperator, operatorController.updateVehicle);

// Driver Management

// GET /api/operators/drivers - Get all drivers for this operator
router.get('/drivers', requireApprovedOperator, operatorController.getDrivers);

// POST /api/operators/drivers - Add a new driver
router.post('/drivers', requireApprovedOperator, operatorController.createDriver);

// PUT /api/operators/drivers/:id - Update driver details
router.put('/drivers/:id', requireApprovedOperator, operatorController.updateDriver);

// DELETE /api/operators/drivers/:id - Remove a driver
router.delete('/drivers/:id', requireApprovedOperator, operatorController.deleteDriver);

// Vehicle-Driver Assignment

// POST /api/operators/vehicles/:vehicleId/assign-driver - Assign driver to vehicle
router.post('/vehicles/:vehicleId/assign-driver', requireApprovedOperator, operatorController.assignDriver);

// DELETE /api/operators/vehicles/:vehicleId/unassign-driver - Remove driver from vehicle
router.delete('/vehicles/:vehicleId/unassign-driver', requireApprovedOperator, operatorController.unassignDriver);

// Route Assignment

// GET /api/operators/vehicles/:vehicleId/routes - Get routes assigned to vehicle
router.get('/vehicles/:vehicleId/routes', requireApprovedOperator, operatorController.getVehicleRoutes);

// POST /api/operators/vehicles/:vehicleId/routes - Assign route to vehicle
router.post('/vehicles/:vehicleId/routes', requireApprovedOperator, operatorController.assignRoute);

// DELETE /api/operators/vehicles/:vehicleId/routes/:routeId - Remove route from vehicle
router.delete('/vehicles/:vehicleId/routes/:routeId', requireApprovedOperator, operatorController.unassignRoute);

// Dashboard Stats

// GET /api/operators/dashboard - Get dashboard statistics
router.get('/dashboard', requireApprovedOperator, operatorController.getDashboard);

// GET /api/operators/profile - Get operator profile
router.get('/profile', operatorController.getProfile);

module.exports = router;
