const db = require('../config/database');
const { asyncHandler, ApiError } = require('../middleware/errorHandler');

/**
 * Get all active routes
 * GET /api/routes
 */
const getAllRoutes = asyncHandler(async (req, res) => {
  const result = await db.query(
    `SELECT r.routeid, r.routename, r.routecode, r.isactive,
            COUNT(DISTINCT rs.stopid) as stop_count,
            MIN(s.stopname) as first_stop,
            MAX(s.stopname) as last_stop
     FROM routes r
     LEFT JOIN routestops rs ON r.routeid = rs.routeid
     LEFT JOIN stops s ON rs.stopid = s.stopid
     WHERE r.isactive = true
     GROUP BY r.routeid
     ORDER BY r.routecode`
  );

  res.json({
    success: true,
    data: { routes: result.rows }
  });
});

/**
 * Get route details with stops
 * GET /api/routes/:id
 */
const getRouteById = asyncHandler(async (req, res) => {
  const { id } = req.params;

  // Get route details
  const routeResult = await db.query(
    'SELECT * FROM routes WHERE routeid = $1',
    [id]
  );

  if (routeResult.rows.length === 0) {
    throw new ApiError(404, 'Route not found');
  }

  // Get stops for this route
  const stopsResult = await db.query(
    `SELECT s.stopid, s.stopname, s.latitude, s.longitude,
            rs.stopsequence
     FROM routestops rs
     JOIN stops s ON rs.stopid = s.stopid
     WHERE rs.routeid = $1
     ORDER BY rs.stopsequence`,
    [id]
  );

  res.json({
    success: true,
    data: {
      route: routeResult.rows[0],
      stops: stopsResult.rows
    }
  });
});

/**
 * Get stops for a route
 * GET /api/routes/:id/stops
 */
const getRouteStops = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const result = await db.query(
    `SELECT s.stopid, s.stopname, s.latitude, s.longitude,
            rs.stopsequence
     FROM routestops rs
     JOIN stops s ON rs.stopid = s.stopid
     WHERE rs.routeid = $1
     ORDER BY rs.stopsequence`,
    [id]
  );

  res.json({
    success: true,
    data: { stops: result.rows }
  });
});

/**
 * Calculate fare between two stops
 * GET /api/routes/:id/fare?from_stop=X&to_stop=Y
 */
const calculateFare = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { from_stop, to_stop } = req.query;

  if (!from_stop || !to_stop) {
    throw new ApiError(400, 'Both from_stop and to_stop are required');
  }

  // Get sequence numbers for both stops
  const stopsResult = await db.query(
    `SELECT s.stopid, s.stopname, rs.stopsequence
     FROM routestops rs
     JOIN stops s ON rs.stopid = s.stopid
     WHERE rs.routeid = $1 AND rs.stopid IN ($2, $3)`,
    [id, from_stop, to_stop]
  );

  if (stopsResult.rows.length !== 2) {
    throw new ApiError(404, 'One or both stops not found on this route');
  }

  const fromStop = stopsResult.rows.find(s => s.stopid == from_stop);
  const toStop = stopsResult.rows.find(s => s.stopid == to_stop);

  const fromSeq = Math.min(fromStop.stopsequence, toStop.stopsequence);
  const toSeq = Math.max(fromStop.stopsequence, toStop.stopsequence);

  // Try to get fare from fare_structure table
  const fareResult = await db.query(
    `SELECT fareamountnpr FROM farestructure
     WHERE routeid = $1 AND fromstopsequence = $2 AND tostopsequence = $3`,
    [id, fromSeq, toSeq]
  );

  let fare;
  if (fareResult.rows.length > 0) {
    fare = fareResult.rows[0].fareamountnpr;
  } else {
    // Fallback calculation: 10 NPR per stop, minimum 15 NPR
    const stopDiff = Math.abs(toStop.stopsequence - fromStop.stopsequence);
    fare = Math.max(stopDiff * 10, 15);
  }

  res.json({
    success: true,
    data: {
      route_id: id,
      from_stop: fromStop,
      to_stop: toStop,
      stops_between: Math.abs(toStop.stopsequence - fromStop.stopsequence),
      fare_npr: fare
    }
  });
});

/**
 * Get all stops
 * GET /api/routes/stops/all
 */
const getAllStops = asyncHandler(async (req, res) => {
  const result = await db.query(
    `SELECT s.stopid, s.stopname, s.latitude, s.longitude,
            COUNT(rs.routeid) as route_count
     FROM stops s
     LEFT JOIN routestops rs ON s.stopid = rs.stopid
     GROUP BY s.stopid
     ORDER BY s.stopname`
  );

  res.json({
    success: true,
    data: { stops: result.rows }
  });
});

/**
 * Search routes by stop names
 * GET /api/routes/search/by-stops?from=X&to=Y
 */
const searchRoutesByStops = asyncHandler(async (req, res) => {
  const { from, to } = req.query;

  if (!from || !to) {
    throw new ApiError(400, 'Both from and to stop names are required');
  }

  // Find routes that contain both stops
  const result = await db.query(
    `SELECT DISTINCT r.routeid, r.routename, r.routecode,
            fs.stopsequence as from_sequence, fs.stopname as from_stop,
            ts.stopsequence as to_sequence, ts.stopname as to_stop
     FROM routes r
     JOIN (
       SELECT rs.routeid, rs.stopsequence, s.stopname
       FROM routestops rs
       JOIN stops s ON rs.stopid = s.stopid
       WHERE LOWER(s.stopname) LIKE LOWER($1)
     ) fs ON r.routeid = fs.routeid
     JOIN (
       SELECT rs.routeid, rs.stopsequence, s.stopname
       FROM routestops rs
       JOIN stops s ON rs.stopid = s.stopid
       WHERE LOWER(s.stopname) LIKE LOWER($2)
     ) ts ON r.routeid = ts.routeid
     WHERE r.isactive = true
     ORDER BY r.routecode`,
    [`%${from}%`, `%${to}%`]
  );

  res.json({
    success: true,
    data: { routes: result.rows }
  });
});

module.exports = {
  getAllRoutes,
  getRouteById,
  getRouteStops,
  calculateFare,
  getAllStops,
  searchRoutesByStops
};
