const db = require('../config/database');
const { asyncHandler, ApiError } = require('../middleware/errorHandler');

// Vehicle Management

/**
 * Get all vehicles for this operator
 * GET /api/operators/vehicles
 */
const getVehicles = asyncHandler(async (req, res) => {
  const operatorId = req.user.operatorid;

  const result = await db.query(
    `SELECT v.vehicleid, v.registrationnumber, v.vehicletype, v.seatingcapacity,
            v.approvalstatus, v.createdat,
            d.driverid, d.driversname as driver_name, d.phonenumber as driver_phone
     FROM vehicles v
     LEFT JOIN drivers d ON v.driverid = d.driverid
     WHERE v.operatorid = $1
     ORDER BY v.createdat DESC`,
    [operatorId]
  );

  res.json({
    success: true,
    data: { vehicles: result.rows }
  });
});

/**
 * Create a new vehicle
 * POST /api/operators/vehicles
 */
const createVehicle = asyncHandler(async (req, res) => {
  const operatorId = req.user.operatorid;
  const { registrationNumber, vehicleType, seatingCapacity, modelYear } = req.body;

  if (!registrationNumber || !vehicleType) {
    throw new ApiError(400, 'Registration number and vehicle type are required');
  }

  if (!req.file) {
    throw new ApiError(400, 'Bluebook document is required');
  }

  const documentUrls = { bluebook: `/uploads/vehicles/${req.file.filename}` };

  const result = await db.query(
    `INSERT INTO vehicles (operatorid, registrationnumber, vehicletype, seatingcapacity, modelyear, documenturls, approvalstatus)
     VALUES ($1, $2, $3, $4, $5, $6, 'Pending')
     RETURNING *`,
    [operatorId, registrationNumber, vehicleType, seatingCapacity || 40, modelYear || null, JSON.stringify(documentUrls)]
  );

  res.status(201).json({
    success: true,
    message: 'Vehicle registered. Pending admin approval.',
    data: { vehicle: result.rows[0] }
  });
});

/**
 * Get vehicle details
 * GET /api/operators/vehicles/:id
 */
const getVehicle = asyncHandler(async (req, res) => {
  const operatorId = req.user.operatorid;
  const { id } = req.params;

  const result = await db.query(
    `SELECT v.*,
            d.driverid, d.driversname as driver_name, d.phonenumber as driver_phone,
            d.licensenumber as driver_license
     FROM vehicles v
     LEFT JOIN drivers d ON v.driverid = d.driverid
     WHERE v.vehicleid = $1 AND v.operatorid = $2`,
    [id, operatorId]
  );

  if (result.rows.length === 0) {
    throw new ApiError(404, 'Vehicle not found');
  }

  // Get assigned routes
  const routesResult = await db.query(
    `SELECT r.routeid, r.routename, r.routecode
     FROM vehicleroutes vr
     JOIN routes r ON vr.routeid = r.routeid
     WHERE vr.vehicleid = $1`,
    [id]
  );

  res.json({
    success: true,
    data: {
      vehicle: result.rows[0],
      routes: routesResult.rows
    }
  });
});

/**
 * Update vehicle details
 * PUT /api/operators/vehicles/:id
 */
const updateVehicle = asyncHandler(async (req, res) => {
  const operatorId = req.user.operatorid;
  const { id } = req.params;
  const { vehicleType, seatingCapacity } = req.body;

  const result = await db.query(
    `UPDATE vehicles
     SET vehicletype = COALESCE($1, vehicletype),
         seatingcapacity = COALESCE($2, seatingcapacity),
         updatedat = NOW()
     WHERE vehicleid = $3 AND operatorid = $4
     RETURNING *`,
    [vehicleType, seatingCapacity, id, operatorId]
  );

  if (result.rows.length === 0) {
    throw new ApiError(404, 'Vehicle not found');
  }

  res.json({
    success: true,
    message: 'Vehicle updated successfully',
    data: { vehicle: result.rows[0] }
  });
});

// Driver Management

/**
 * Get all drivers for this operator
 * GET /api/operators/drivers
 */
const getDrivers = asyncHandler(async (req, res) => {
  const operatorId = req.user.operatorid;

  const result = await db.query(
    `SELECT d.driverid, d.driversname, d.phonenumber, d.licensenumber, d.createdat,
            v.vehicleid, v.registrationnumber as assigned_vehicle
     FROM drivers d
     LEFT JOIN vehicles v ON v.driverid = d.driverid
     WHERE d.operatorid = $1
     ORDER BY d.driversname`,
    [operatorId]
  );

  res.json({
    success: true,
    data: { drivers: result.rows }
  });
});

/**
 * Add a new driver
 * POST /api/operators/drivers
 */
const createDriver = asyncHandler(async (req, res) => {
  const operatorId = req.user.operatorid;
  const { driversName, phoneNumber, licenseNumber, licenseExpiryDate } = req.body;

  if (!driversName || !phoneNumber || !licenseNumber || !licenseExpiryDate) {
    throw new ApiError(400, 'Driver name, phone, license number, and expiry date are required');
  }

  const result = await db.query(
    `INSERT INTO drivers (operatorid, driversname, phonenumber, licensenumber, licenseexpirydate)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [operatorId, driversName, phoneNumber, licenseNumber, licenseExpiryDate]
  );

  res.status(201).json({
    success: true,
    message: 'Driver added successfully',
    data: { driver: result.rows[0] }
  });
});

/**
 * Update driver details
 * PUT /api/operators/drivers/:id
 */
const updateDriver = asyncHandler(async (req, res) => {
  const operatorId = req.user.operatorid;
  const { id } = req.params;
  const { driversName, phoneNumber, licenseNumber } = req.body;

  const result = await db.query(
    `UPDATE drivers
     SET driversname = COALESCE($1, driversname),
         phonenumber = COALESCE($2, phonenumber),
         licensenumber = COALESCE($3, licensenumber),
         updatedat = NOW()
     WHERE driverid = $4 AND operatorid = $5
     RETURNING *`,
    [driversName, phoneNumber, licenseNumber, id, operatorId]
  );

  if (result.rows.length === 0) {
    throw new ApiError(404, 'Driver not found');
  }

  res.json({
    success: true,
    message: 'Driver updated successfully',
    data: { driver: result.rows[0] }
  });
});

/**
 * Delete a driver
 * DELETE /api/operators/drivers/:id
 */
const deleteDriver = asyncHandler(async (req, res) => {
  const operatorId = req.user.operatorid;
  const { id } = req.params;

  // First unassign from any vehicle
  await db.query(
    `UPDATE vehicles SET driverid = NULL WHERE driverid = $1`,
    [id]
  );

  // Then delete the driver
  const result = await db.query(
    `DELETE FROM drivers WHERE driverid = $1 AND operatorid = $2 RETURNING driverid`,
    [id, operatorId]
  );

  if (result.rows.length === 0) {
    throw new ApiError(404, 'Driver not found');
  }

  res.json({
    success: true,
    message: 'Driver deleted successfully'
  });
});

// Vehicle-Driver Assignment

/**
 * Assign driver to vehicle
 * POST /api/operators/vehicles/:vehicleId/assign-driver
 */
const assignDriver = asyncHandler(async (req, res) => {
  const operatorId = req.user.operatorid;
  const { vehicleId } = req.params;
  const { driverId } = req.body;

  if (!driverId) {
    throw new ApiError(400, 'Driver ID is required');
  }

  // Verify both vehicle and driver belong to this operator
  const vehicleCheck = await db.query(
    'SELECT vehicleid FROM vehicles WHERE vehicleid = $1 AND operatorid = $2',
    [vehicleId, operatorId]
  );

  if (vehicleCheck.rows.length === 0) {
    throw new ApiError(404, 'Vehicle not found');
  }

  const driverCheck = await db.query(
    'SELECT driverid FROM drivers WHERE driverid = $1 AND operatorid = $2',
    [driverId, operatorId]
  );

  if (driverCheck.rows.length === 0) {
    throw new ApiError(404, 'Driver not found');
  }

  // Unassign driver from any current vehicle
  await db.query(
    'UPDATE vehicles SET driverid = NULL WHERE driverid = $1',
    [driverId]
  );

  // Assign to new vehicle
  const result = await db.query(
    `UPDATE vehicles SET driverid = $1, updatedat = NOW()
     WHERE vehicleid = $2
     RETURNING *`,
    [driverId, vehicleId]
  );

  res.json({
    success: true,
    message: 'Driver assigned to vehicle successfully',
    data: { vehicle: result.rows[0] }
  });
});

/**
 * Unassign driver from vehicle
 * DELETE /api/operators/vehicles/:vehicleId/unassign-driver
 */
const unassignDriver = asyncHandler(async (req, res) => {
  const operatorId = req.user.operatorid;
  const { vehicleId } = req.params;

  const result = await db.query(
    `UPDATE vehicles SET driverid = NULL, updatedat = NOW()
     WHERE vehicleid = $1 AND operatorid = $2
     RETURNING *`,
    [vehicleId, operatorId]
  );

  if (result.rows.length === 0) {
    throw new ApiError(404, 'Vehicle not found');
  }

  res.json({
    success: true,
    message: 'Driver unassigned from vehicle',
    data: { vehicle: result.rows[0] }
  });
});

// Route Assignment

/**
 * Get routes assigned to vehicle
 * GET /api/operators/vehicles/:vehicleId/routes
 */
const getVehicleRoutes = asyncHandler(async (req, res) => {
  const operatorId = req.user.operatorid;
  const { vehicleId } = req.params;

  // Verify vehicle belongs to operator
  const vehicleCheck = await db.query(
    'SELECT vehicleid FROM vehicles WHERE vehicleid = $1 AND operatorid = $2',
    [vehicleId, operatorId]
  );

  if (vehicleCheck.rows.length === 0) {
    throw new ApiError(404, 'Vehicle not found');
  }

  const result = await db.query(
    `SELECT r.routeid, r.routename, r.routecode
     FROM vehicleroutes vr
     JOIN routes r ON vr.routeid = r.routeid
     WHERE vr.vehicleid = $1`,
    [vehicleId]
  );

  res.json({
    success: true,
    data: { routes: result.rows }
  });
});

/**
 * Assign route to vehicle
 * POST /api/operators/vehicles/:vehicleId/routes
 */
const assignRoute = asyncHandler(async (req, res) => {
  const operatorId = req.user.operatorid;
  const { vehicleId } = req.params;
  const { routeId } = req.body;

  if (!routeId) {
    throw new ApiError(400, 'Route ID is required');
  }

  // Verify vehicle belongs to operator
  const vehicleCheck = await db.query(
    'SELECT vehicleid FROM vehicles WHERE vehicleid = $1 AND operatorid = $2',
    [vehicleId, operatorId]
  );

  if (vehicleCheck.rows.length === 0) {
    throw new ApiError(404, 'Vehicle not found');
  }

  // Verify route exists
  const routeCheck = await db.query(
    'SELECT routeid FROM routes WHERE routeid = $1 AND isactive = true',
    [routeId]
  );

  if (routeCheck.rows.length === 0) {
    throw new ApiError(404, 'Route not found or inactive');
  }

  await db.query(
    `INSERT INTO vehicleroutes (vehicleid, routeid)
     VALUES ($1, $2)
     ON CONFLICT (vehicleid, routeid) DO NOTHING`,
    [vehicleId, routeId]
  );

  res.json({
    success: true,
    message: 'Route assigned to vehicle successfully'
  });
});

/**
 * Remove route from vehicle
 * DELETE /api/operators/vehicles/:vehicleId/routes/:routeId
 */
const unassignRoute = asyncHandler(async (req, res) => {
  const operatorId = req.user.operatorid;
  const { vehicleId, routeId } = req.params;

  // Verify vehicle belongs to operator
  const vehicleCheck = await db.query(
    'SELECT vehicleid FROM vehicles WHERE vehicleid = $1 AND operatorid = $2',
    [vehicleId, operatorId]
  );

  if (vehicleCheck.rows.length === 0) {
    throw new ApiError(404, 'Vehicle not found');
  }

  await db.query(
    'DELETE FROM vehicleroutes WHERE vehicleid = $1 AND routeid = $2',
    [vehicleId, routeId]
  );

  res.json({
    success: true,
    message: 'Route removed from vehicle'
  });
});

// Dashboard & Profile

/**
 * Get operator dashboard statistics
 * GET /api/operators/dashboard
 */
const getDashboard = asyncHandler(async (req, res) => {
  const operatorId = req.user.operatorid;

  // Get vehicle count
  const vehicleCount = await db.query(
    'SELECT COUNT(*) as total, SUM(CASE WHEN approvalstatus = \'Approved\' THEN 1 ELSE 0 END) as approved FROM vehicles WHERE operatorid = $1',
    [operatorId]
  );

  // Get driver count
  const driverCount = await db.query(
    'SELECT COUNT(*) as total FROM drivers WHERE operatorid = $1',
    [operatorId]
  );

  // Get today's rides for operator's vehicles
  const todayRides = await db.query(
    `SELECT COUNT(*) as total, SUM(fareamountnpr) as revenue
     FROM rides r
     JOIN vehicles v ON r.vehicleid = v.vehicleid
     WHERE v.operatorid = $1 AND DATE(r.entrytime) = CURRENT_DATE`,
    [operatorId]
  );

  res.json({
    success: true,
    data: {
      vehicles: {
        total: parseInt(vehicleCount.rows[0].total),
        approved: parseInt(vehicleCount.rows[0].approved) || 0
      },
      drivers: parseInt(driverCount.rows[0].total),
      todayRides: parseInt(todayRides.rows[0].total) || 0,
      todayRevenue: parseFloat(todayRides.rows[0].revenue) || 0
    }
  });
});

/**
 * Get operator profile
 * GET /api/operators/profile
 */
const getProfile = asyncHandler(async (req, res) => {
  const operatorId = req.user.operatorid;

  const result = await db.query(
    `SELECT o.*, u.email, u.phonenumber
     FROM operators o
     JOIN users u ON o.userid = u.userid
     WHERE o.operatorid = $1`,
    [operatorId]
  );

  res.json({
    success: true,
    data: { operator: result.rows[0] }
  });
});

module.exports = {
  getVehicles,
  createVehicle,
  getVehicle,
  updateVehicle,
  getDrivers,
  createDriver,
  updateDriver,
  deleteDriver,
  assignDriver,
  unassignDriver,
  getVehicleRoutes,
  assignRoute,
  unassignRoute,
  getDashboard,
  getProfile
};
