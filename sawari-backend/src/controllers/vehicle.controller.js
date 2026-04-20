const db = require('../config/database');
const { asyncHandler, ApiError } = require('../middleware/errorHandler');

/**
 * Update vehicle GPS location & auto-detect nearest stop
 * POST /api/vehicles/:id/location
 * Expects: { latitude, longitude }
 * Protected by API key (same as RFID)
 */
const updateLocation = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { latitude, longitude } = req.body;

  if (!latitude || !longitude) {
    throw new ApiError(400, 'latitude and longitude are required');
  }

  // Update GPS coordinates
  const vehicleResult = await db.query(
    `UPDATE vehicles SET currentlatitude = $1, currentlongitude = $2, updatedat = NOW()
     WHERE vehicleid = $3 AND approvalstatus = 'Approved'
     RETURNING vehicleid, registrationnumber`,
    [latitude, longitude, id]
  );

  if (vehicleResult.rows.length === 0) {
    throw new ApiError(404, 'Vehicle not found or not approved');
  }

  // Find nearest stop on the assigned route
  const nearestStop = await db.query(
    `SELECT s.stopid, s.stopname, s.latitude, s.longitude, rs.stopsequence,
            SQRT(POW(s.latitude - $1, 2) + POW(s.longitude - $2, 2)) AS distance
     FROM vehicleroutes vr
     JOIN routestops rs ON vr.routeid = rs.routeid
     JOIN stops s ON rs.stopid = s.stopid
     WHERE vr.vehicleid = $3
     ORDER BY distance ASC
     LIMIT 1`,
    [latitude, longitude, id]
  );

  const nearest = nearestStop.rows.length > 0 ? nearestStop.rows[0] : null;

  res.json({
    success: true,
    data: {
      vehicle: vehicleResult.rows[0].registrationnumber,
      location: { latitude, longitude },
      nearest_stop: nearest ? {
        stop_id: nearest.stopid,
        stop_name: nearest.stopname,
        sequence: nearest.stopsequence
      } : null
    }
  });
});

/**
 * Get vehicle's current location & nearest stop
 * GET /api/vehicles/:id/location
 */
const getLocation = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const result = await db.query(
    `SELECT v.vehicleid, v.registrationnumber, v.currentlatitude, v.currentlongitude
     FROM vehicles v WHERE v.vehicleid = $1`,
    [id]
  );

  if (result.rows.length === 0) {
    throw new ApiError(404, 'Vehicle not found');
  }

  const vehicle = result.rows[0];

  // Find nearest stop
  let nearest = null;
  if (vehicle.currentlatitude && vehicle.currentlongitude) {
    const nearestStop = await db.query(
      `SELECT s.stopid, s.stopname, rs.stopsequence,
              SQRT(POW(s.latitude - $1, 2) + POW(s.longitude - $2, 2)) AS distance
       FROM vehicleroutes vr
       JOIN routestops rs ON vr.routeid = rs.routeid
       JOIN stops s ON rs.stopid = s.stopid
       WHERE vr.vehicleid = $3
       ORDER BY distance ASC
       LIMIT 1`,
      [vehicle.currentlatitude, vehicle.currentlongitude, id]
    );
    nearest = nearestStop.rows[0] || null;
  }

  res.json({
    success: true,
    data: {
      vehicle_id: vehicle.vehicleid,
      registration: vehicle.registrationnumber,
      latitude: vehicle.currentlatitude,
      longitude: vehicle.currentlongitude,
      nearest_stop: nearest ? {
        stop_id: nearest.stopid,
        stop_name: nearest.stopname,
        sequence: nearest.stopsequence
      } : null
    }
  });
});

module.exports = { updateLocation, getLocation };
