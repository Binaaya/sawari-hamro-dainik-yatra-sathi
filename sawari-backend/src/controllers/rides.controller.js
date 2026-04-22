const db = require('../config/database');
const { asyncHandler, ApiError } = require('../middleware/errorHandler');

const MINIMUM_BALANCE = 10; // Minimum balance required for entry (10 tokens = 50 NPR)

/**
 * Find the nearest stop for a vehicle using its GPS coordinates
 * Returns stop_id or throws error if no GPS data
 */
async function findNearestStop(client, vehicle_id) {
  const gps = await client.query(
    `SELECT currentlatitude, currentlongitude FROM vehicles WHERE vehicleid = $1`,
    [vehicle_id]
  );
  if (gps.rows.length === 0 || !gps.rows[0].currentlatitude) {
    throw new ApiError(400, 'Vehicle has no GPS location. Cannot auto-detect stop.');
  }
  const { currentlatitude, currentlongitude } = gps.rows[0];

  const nearest = await client.query(
    `SELECT s.stopid
     FROM vehicleroutes vr
     JOIN routestops rs ON vr.routeid = rs.routeid
     JOIN stops s ON rs.stopid = s.stopid
     WHERE vr.vehicleid = $1
     ORDER BY SQRT(POW(s.latitude - $2, 2) + POW(s.longitude - $3, 2)) ASC
     LIMIT 1`,
    [vehicle_id, currentlatitude, currentlongitude]
  );
  if (nearest.rows.length === 0) {
    throw new ApiError(400, 'No stops found on vehicle route');
  }
  return nearest.rows[0].stopid;
}

/**
 * RFID Tap-In - Entry point for ride
 * POST /api/rides/tap-in
 * Expects: { rfid_card_uid, vehicle_id, stop_id? }
 * stop_id is optional — auto-detected from vehicle GPS if not provided
 */
const tapIn = asyncHandler(async (req, res) => {
  const { rfid_card_uid, vehicle_id } = req.body;
  let stop_id = req.body.stop_id ? parseInt(req.body.stop_id) : null;

  if (!rfid_card_uid || !vehicle_id) {
    throw new ApiError(400, 'Missing required fields: rfid_card_uid, vehicle_id');
  }

  const result = await db.transaction(async (client) => {
    // Auto-detect stop from GPS if not provided
    if (!stop_id) {
      stop_id = await findNearestStop(client, vehicle_id);
    }
    // 1. Find the RFID card and passenger
    const cardResult = await client.query(
      `SELECT rc.cardid, rc.cardstatus as card_status,
              p.passengerid, p.accountbalancenpr, p.userid
       FROM rfidcards rc
       JOIN passengers p ON rc.cardid = p.rfidcardid
       WHERE rc.carduid = $1`,
      [rfid_card_uid]
    );

    if (cardResult.rows.length === 0) {
      throw new ApiError(404, 'RFID card not found or not assigned to any passenger');
    }

    const { cardid, card_status, passengerid, accountbalancenpr } = cardResult.rows[0];

    // Validate card status
    if (card_status !== 'Active') {
      throw new ApiError(403, `RFID card is ${card_status}. Cannot process tap.`);
    }

    // Validate minimum balance
    if (accountbalancenpr < MINIMUM_BALANCE) {
      throw new ApiError(403, `Insufficient balance. Minimum ${MINIMUM_BALANCE} tokens required. Current balance: ${accountbalancenpr} tokens`);
    }

    // Ensure no ongoing ride exists
    const ongoingRide = await client.query(
      `SELECT rideid FROM rides
       WHERE passengerid = $1 AND ridestatus = 'Ongoing'`,
      [passengerid]
    );

    if (ongoingRide.rows.length > 0) {
      throw new ApiError(409, 'Passenger already has an ongoing ride. Please tap out first.');
    }

    // Retrieve vehicle and assigned route
    const vehicleResult = await client.query(
      `SELECT v.vehicleid, v.registrationnumber, vr.routeid, r.routename
       FROM vehicles v
       JOIN vehicleroutes vr ON v.vehicleid = vr.vehicleid
       JOIN routes r ON vr.routeid = r.routeid
       WHERE v.vehicleid = $1 AND v.approvalstatus = 'Approved'`,
      [vehicle_id]
    );

    if (vehicleResult.rows.length === 0) {
      throw new ApiError(404, 'Vehicle not found or not approved');
    }

    const { routeid, routename, registrationnumber } = vehicleResult.rows[0];

    // Validate stop belongs to the vehicle's route
    const stopCheck = await client.query(
      `SELECT rs.stopsequence, s.stopname
       FROM routestops rs
       JOIN stops s ON rs.stopid = s.stopid
       WHERE rs.routeid = $1 AND rs.stopid = $2`,
      [routeid, stop_id]
    );

    if (stopCheck.rows.length === 0) {
      throw new ApiError(400, 'Stop is not on this vehicle\'s route');
    }

    const { stopsequence, stopname } = stopCheck.rows[0];

    // Create ride record
    const rideResult = await client.query(
      `INSERT INTO rides (passengerid, vehicleid, routeid, entrystopid, ridestatus, entrytime, balancebeforeentrynpr)
       VALUES ($1, $2, $3, $4, 'Ongoing', NOW(), $5)
       RETURNING rideid, entrytime`,
      [passengerid, vehicle_id, routeid, stop_id, accountbalancenpr]
    );

    return {
      rideid: rideResult.rows[0].rideid,
      entrytime: rideResult.rows[0].entrytime,
      routename,
      vehicle: registrationnumber,
      entry_stop: stopname,
      balance: accountbalancenpr
    };
  });
  
  res.status(201).json({
    success: true,
    message: 'Tap-in successful. Ride started.',
    data: result
  });
});

/**
 * RFID Tap-Out - Exit point for ride
 * POST /api/rides/tap-out
 * Expects: { rfid_card_uid, vehicle_id, stop_id? }
 * stop_id is optional — auto-detected from vehicle GPS if not provided
 */
const tapOut = asyncHandler(async (req, res) => {
  const { rfid_card_uid, vehicle_id } = req.body;
  let stop_id = req.body.stop_id ? parseInt(req.body.stop_id) : null;

  if (!rfid_card_uid || !vehicle_id) {
    throw new ApiError(400, 'Missing required fields: rfid_card_uid, vehicle_id');
  }

  const result = await db.transaction(async (client) => {
    // Look up RFID card and passenger FIRST (before GPS lookup)
    const cardResult = await client.query(
      `SELECT rc.cardid, p.passengerid, p.accountbalancenpr
       FROM rfidcards rc
       JOIN passengers p ON rc.cardid = p.rfidcardid
       WHERE rc.carduid = $1`,
      [rfid_card_uid]
    );

    if (cardResult.rows.length === 0) {
      throw new ApiError(404, 'RFID card not found');
    }

    const { passengerid, accountbalancenpr } = cardResult.rows[0];

    // Retrieve the ongoing ride
    const rideResult = await client.query(
      `SELECT r.rideid, r.routeid, r.entrystopid, r.entrytime,
              es.stopname as entry_stop_name, rt.routename
       FROM rides r
       JOIN stops es ON r.entrystopid = es.stopid
       JOIN routes rt ON r.routeid = rt.routeid
       WHERE r.passengerid = $1 AND r.ridestatus = 'Ongoing'`,
      [passengerid]
    );

    if (rideResult.rows.length === 0) {
      throw new ApiError(404, 'No ongoing ride found. Please tap in first.');
    }

    const ride = rideResult.rows[0];

    // Auto-detect stop from GPS if not provided
    if (!stop_id) {
      stop_id = await findNearestStop(client, vehicle_id);
    }

    // Get exit stop details
    const exitStopResult = await client.query(
      `SELECT rs.stopsequence, s.stopname
       FROM routestops rs
       JOIN stops s ON rs.stopid = s.stopid
       WHERE rs.routeid = $1 AND rs.stopid = $2`,
      [ride.routeid, stop_id]
    );

    if (exitStopResult.rows.length === 0) {
      throw new ApiError(400, 'Exit stop is not on this route');
    }

    const { stopsequence: exit_sequence, stopname: exit_stop_name } = exitStopResult.rows[0];

    // Get entry stop sequence
    const entryStopSeq = await client.query(
      `SELECT stopsequence FROM routestops WHERE routeid = $1 AND stopid = $2`,
      [ride.routeid, ride.entrystopid]
    );
    const entry_sequence = entryStopSeq.rows[0]?.stopsequence || 0;

    // Handle same-stop exit (cancel ride)
    if (ride.entrystopid === stop_id) {
      // Same stop - cancel the ride with zero fare
      await client.query(
        `UPDATE rides
         SET exitstopid = $1, exittime = NOW(),
             ridestatus = 'Cancelled', fareamountnpr = 0, balanceafterexitnpr = $2
         WHERE rideid = $3`,
        [stop_id, accountbalancenpr, ride.rideid]
      );

      return {
        rideid: ride.rideid,
        status: 'Cancelled',
        fare: 0,
        message: 'Same stop exit - ride cancelled with no charge',
        entry_stop: ride.entry_stop_name,
        exit_stop: exit_stop_name,
        balance: accountbalancenpr
      };
    }

    // Calculate fare based on stop sequence difference
    const stopDifference = Math.abs(exit_sequence - entry_sequence);

    // Get fare from fare_structure table
    const fareResult = await client.query(
      `SELECT fareamountnpr FROM farestructure
       WHERE routeid = $1 AND fromstopsequence = $2 AND tostopsequence = $3`,
      [ride.routeid, Math.min(entry_sequence, exit_sequence), Math.max(entry_sequence, exit_sequence)]
    );

    let fareAmount;
    if (fareResult.rows.length > 0) {
      fareAmount = fareResult.rows[0].fareamountnpr;
    } else {
      // Fallback: calculate based on stop difference (10 NPR per stop)
      fareAmount = Math.max(stopDifference * 10, 15); // Minimum 15 NPR
    }

    // Deduct fare from passenger balance
    const fareInTokens = fareAmount / 5;
    const newBalance = accountbalancenpr - fareInTokens;

    await client.query(
      `UPDATE passengers SET accountbalancenpr = $1 WHERE passengerid = $2`,
      [newBalance, passengerid]
    );

    // Update ride record with exit details
    await client.query(
      `UPDATE rides
       SET exitstopid = $1, exittime = NOW(),
           ridestatus = 'Completed', fareamountnpr = $2, balanceafterexitnpr = $3
       WHERE rideid = $4`,
      [stop_id, fareAmount, newBalance, ride.rideid]
    );

    // Record fare transaction
    await client.query(
      `INSERT INTO transactions (userid, rideid, transactiontype, amountnpr, balancebeforenpr, balanceafternpr)
       SELECT p.userid, $1, 'RidePayment', $2, $3, $4
       FROM passengers p WHERE p.passengerid = $5`,
      [ride.rideid, fareAmount, accountbalancenpr, newBalance, passengerid]
    );

    return {
      rideid: ride.rideid,
      status: 'Completed',
      routename: ride.routename,
      entry_stop: ride.entry_stop_name,
      exit_stop: exit_stop_name,
      stops_traveled: stopDifference,
      fare: fareAmount,
      balance_before: accountbalancenpr,
      balance_after: newBalance
    };
  });
  
  res.json({
    success: true,
    message: 'Tap-out successful. Ride completed.',
    data: result
  });
});

/**
 * Get ride details by ID
 * GET /api/rides/:id
 */
const getRideById = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.userid;

  const result = await db.query(
    `SELECT r.*,
            rt.routename, rt.routecode,
            es.stopname as entry_stop, xs.stopname as exit_stop,
            v.registrationnumber,
            p.userid as passenger_user_id
     FROM rides r
     JOIN routes rt ON r.routeid = rt.routeid
     LEFT JOIN stops es ON r.entrystopid = es.stopid
     LEFT JOIN stops xs ON r.exitstopid = xs.stopid
     LEFT JOIN vehicles v ON r.vehicleid = v.vehicleid
     JOIN passengers p ON r.passengerid = p.passengerid
     WHERE r.rideid = $1`,
    [id]
  );

  if (result.rows.length === 0) {
    throw new ApiError(404, 'Ride not found');
  }

  const ride = result.rows[0];

  // Check authorization (passenger can see own rides, admin can see all)
  if (req.user.role !== 'Admin' && ride.passenger_user_id !== userId) {
    throw new ApiError(403, 'Not authorized to view this ride');
  }

  res.json({
    success: true,
    data: { ride }
  });
});

/**
 * Get ongoing ride for authenticated passenger
 * GET /api/rides/status/ongoing
 */
const getOngoingRide = asyncHandler(async (req, res) => {
  const passengerId = req.user.passengerid;

  const result = await db.query(
    `SELECT r.rideid, r.passengerid, r.vehicleid, r.routeid,
            r.ridestatus, r.entrytime, r.fareamountnpr,
            r.balancebeforeentrynpr, r.balanceafterexitnpr,
            rt.routename, rt.routecode,
            es.stopname as entry_stop_name,
            v.registrationnumber
     FROM rides r
     JOIN routes rt ON r.routeid = rt.routeid
     JOIN stops es ON r.entrystopid = es.stopid
     LEFT JOIN vehicles v ON r.vehicleid = v.vehicleid
     WHERE r.passengerid = $1 AND r.ridestatus = 'Ongoing'`,
    [passengerId]
  );

  res.json({
    success: true,
    data: {
      ride: result.rows[0] || null
    }
  });
});

module.exports = {
  tapIn,
  tapOut,
  getRideById,
  getOngoingRide
};
