-- -- ============================================================
-- -- Sawari Demo Seed Script — Pokhara City
-- -- ============================================================
-- -- Seeds the database with realistic Pokhara bus stops, routes,
-- -- vehicles, passengers with RFID cards, fare structure, and
-- -- sample rides/transactions to demo the full tap-in/tap-out
-- -- fare deduction system.
-- --
-- -- Run:  psql -U postgres -d sawari_db -f seed_demo_data.sql
-- --
-- -- Columns are matched exactly to the queries in the controllers
-- -- (auth.controller.js, rides.controller.js, admin.controller.js,
-- --  payment.controller.js, etc.)
-- -- ============================================================

BEGIN;

-- ============================================================
-- 1. ADMIN USER
-- ============================================================

INSERT INTO users (firebaseuid, email, phonenumber, passwordhash, role, accountstatus)
VALUES ('MbiMw5rvmHQvBRVrdmvG2JROhNq2', 'admin@sawari.com', '9806000001', 'firebase-auth', 'Admin', 'Active')
ON CONFLICT (firebaseuid) DO UPDATE SET email = EXCLUDED.email, accountstatus = EXCLUDED.accountstatus;

INSERT INTO admins (userid, fullname)
SELECT u.userid, 'Sawari Admin'
FROM users u
WHERE u.firebaseuid = 'MbiMw5rvmHQvBRVrdmvG2JROhNq2'
  AND NOT EXISTS (
    SELECT 1 FROM admins a WHERE a.userid = u.userid
  );

COMMIT;

-- ============================================================
-- 2. OPERATOR (Pokhara Yatayat)
-- ============================================================

BEGIN;

INSERT INTO users (firebaseuid, email, phonenumber, passwordhash, role, accountstatus)
VALUES ('3pmiBlm0UfW33NWk2Ima5L3GkYr2', 'meow@inboxorigin.com', '9806000010', 'firebase-auth', 'Operator', 'Active')
ON CONFLICT (firebaseuid) DO UPDATE SET email = EXCLUDED.email, accountstatus = EXCLUDED.accountstatus;

INSERT INTO operators (userid, operatorname, approvalstatus, approvedat)
SELECT u.userid, 'Pokhara Yatayat Pvt. Ltd.', 'Approved', NOW()
FROM users u
WHERE u.firebaseuid = '3pmiBlm0UfW33NWk2Ima5L3GkYr2'
  AND NOT EXISTS (
    SELECT 1 FROM operators o WHERE o.userid = u.userid
  );

COMMIT;

-- ============================================================
-- 3. VEHICLES (Gandaki province plates)
-- ============================================================

BEGIN;

INSERT INTO vehicles (operatorid, registrationnumber, vehicletype, seatingcapacity, modelyear,
                      approvalstatus, approvedat, currentlatitude, currentlongitude)
SELECT o.operatorid, 'Ga 1 Kha 3045', 'Bus', 40, 2023, 'Approved', NOW(),
       28.2096, 83.9856
FROM operators o
JOIN users u ON o.userid = u.userid
WHERE u.firebaseuid = '3pmiBlm0UfW33NWk2Ima5L3GkYr2'
  AND NOT EXISTS (SELECT 1 FROM vehicles WHERE registrationnumber = 'Ga 1 Kha 3045');

INSERT INTO vehicles (operatorid, registrationnumber, vehicletype, seatingcapacity, modelyear,
                      approvalstatus, approvedat, currentlatitude, currentlongitude)
SELECT o.operatorid, 'Ga 2 Kha 7812', 'Microbus', 22, 2024, 'Approved', NOW(),
       28.2190, 83.9590
FROM operators o
JOIN users u ON o.userid = u.userid
WHERE u.firebaseuid = '3pmiBlm0UfW33NWk2Ima5L3GkYr2'
  AND NOT EXISTS (SELECT 1 FROM vehicles WHERE registrationnumber = 'Ga 2 Kha 7812');

COMMIT;

-- -- ============================================================
-- -- 4. STOPS (real Pokhara bus stops / landmarks)
-- -- ============================================================
-- -- Coordinates are approximate real-world GPS for Pokhara, Nepal.

INSERT INTO stops (stopname, latitude, longitude)
SELECT s.name, s.lat, s.lng
FROM (VALUES
  ('Prithvi Chowk',     28.2096, 83.9856),
  ('Mahendrapool',       28.2130, 83.9870),
  ('Chipledhunga',       28.2170, 83.9870),
  ('Srijana Chowk',     28.2095, 83.9740),
  ('Lakeside',           28.2090, 83.9560),
  ('Bagar',              28.2190, 83.9810),
  ('Naya Bazar',         28.2230, 83.9870),
  ('Hallanchowk',       28.2020, 83.9865),
  ('Bus Park',           28.2250, 83.9910),
  ('Mustang Chowk',      28.2050, 83.9800),
  ('Baidam',             28.2080, 83.9490),
  ('Bindabasini',        28.2210, 83.9850)
) AS s(name, lat, lng)
WHERE NOT EXISTS (SELECT 1 FROM stops WHERE stopname = s.name);

-- -- ============================================================
-- -- 5. ROUTES (6 stops each, as required by the route system)
-- -- ============================================================

-- Route R-1: Prithvi Chowk → Bus Park (city center north)
INSERT INTO routes (routename, routecode, maxfarenpr, isactive)
SELECT 'Prithvi Chowk - Bus Park', 'R-1', 50, true
WHERE NOT EXISTS (SELECT 1 FROM routes WHERE routecode = 'R-1');

INSERT INTO routestops (routeid, stopid, stopsequence)
SELECT r.routeid, s.stopid, seq.n
FROM routes r
CROSS JOIN (
  SELECT 1 AS n, 'Prithvi Chowk'  AS sname UNION ALL
  SELECT 2,      'Mahendrapool'             UNION ALL
  SELECT 3,      'Chipledhunga'             UNION ALL
  SELECT 4,      'Bindabasini'              UNION ALL
  SELECT 5,      'Naya Bazar'               UNION ALL
  SELECT 6,      'Bus Park'
) seq
JOIN stops s ON s.stopname = seq.sname
WHERE r.routecode = 'R-1'
  AND NOT EXISTS (
    SELECT 1 FROM routestops rs
    WHERE rs.routeid = r.routeid AND rs.stopsequence = seq.n
  );

-- Route R-2: Hallanchowk → Lakeside (south to lakeside)
INSERT INTO routes (routename, routecode, maxfarenpr, isactive)
SELECT 'Hallanchowk - Lakeside', 'R-2', 50, true
WHERE NOT EXISTS (SELECT 1 FROM routes WHERE routecode = 'R-2');

INSERT INTO routestops (routeid, stopid, stopsequence)
SELECT r.routeid, s.stopid, seq.n
FROM routes r
CROSS JOIN (
  SELECT 1 AS n, 'Hallanchowk'    AS sname UNION ALL
  SELECT 2,      'Mustang Chowk'            UNION ALL
  SELECT 3,      'Srijana Chowk'            UNION ALL
  SELECT 4,      'Prithvi Chowk'            UNION ALL
  SELECT 5,      'Bagar'                     UNION ALL
  SELECT 6,      'Lakeside'
) seq
JOIN stops s ON s.stopname = seq.sname
WHERE r.routecode = 'R-2'
  AND NOT EXISTS (
    SELECT 1 FROM routestops rs
    WHERE rs.routeid = r.routeid AND rs.stopsequence = seq.n
  );

-- Route R-3: Bus Park → Baidam (full city traverse)
INSERT INTO routes (routename, routecode, maxfarenpr, isactive)
SELECT 'Bus Park - Baidam', 'R-3', 50, true
WHERE NOT EXISTS (SELECT 1 FROM routes WHERE routecode = 'R-3');

INSERT INTO routestops (routeid, stopid, stopsequence)
SELECT r.routeid, s.stopid, seq.n
FROM routes r
CROSS JOIN (
  SELECT 1 AS n, 'Bus Park'       AS sname UNION ALL
  SELECT 2,      'Naya Bazar'               UNION ALL
  SELECT 3,      'Chipledhunga'              UNION ALL
  SELECT 4,      'Mahendrapool'              UNION ALL
  SELECT 5,      'Srijana Chowk'            UNION ALL
  SELECT 6,      'Baidam'
) seq
JOIN stops s ON s.stopname = seq.sname
WHERE r.routecode = 'R-3'
  AND NOT EXISTS (
    SELECT 1 FROM routestops rs
    WHERE rs.routeid = r.routeid AND rs.stopsequence = seq.n
  );

-- ============================================================
-- 6. FARE STRUCTURE
-- ============================================================
-- Fare logic: NPR 15 base (1-2 stops), NPR 20 (3-4 stops),
-- NPR 25 (5 stops), NPR 30 (full route if maxfare allows).
-- We insert all from→to pairs (fromseq < toseq).

-- Helper: generate fares for a given route code
-- Route R-1
INSERT INTO farestructure (routeid, fromstopsequence, tostopsequence, fareamountnpr)
SELECT r.routeid, f.fs, f.ts, f.fare
FROM routes r
CROSS JOIN (
  -- 1 stop hop = 15
  SELECT 1 AS fs, 2 AS ts, 15 AS fare UNION ALL SELECT 2,3,15 UNION ALL SELECT 3,4,15 UNION ALL SELECT 4,5,15 UNION ALL SELECT 5,6,15 UNION ALL
  -- 2 stop hop = 15
  SELECT 1,3,15 UNION ALL SELECT 2,4,15 UNION ALL SELECT 3,5,15 UNION ALL SELECT 4,6,15 UNION ALL
  -- 3 stop hop = 20
  SELECT 1,4,20 UNION ALL SELECT 2,5,20 UNION ALL SELECT 3,6,20 UNION ALL
  -- 4 stop hop = 20
  SELECT 1,5,20 UNION ALL SELECT 2,6,20 UNION ALL
  -- 5 stop hop (full route) = 25
  SELECT 1,6,25
) f
WHERE r.routecode = 'R-1'
ON CONFLICT (routeid, fromstopsequence, tostopsequence) DO NOTHING;

-- Route R-2
INSERT INTO farestructure (routeid, fromstopsequence, tostopsequence, fareamountnpr)
SELECT r.routeid, f.fs, f.ts, f.fare
FROM routes r
CROSS JOIN (
  SELECT 1 AS fs, 2 AS ts, 15 AS fare UNION ALL SELECT 2,3,15 UNION ALL SELECT 3,4,15 UNION ALL SELECT 4,5,15 UNION ALL SELECT 5,6,15 UNION ALL
  SELECT 1,3,15 UNION ALL SELECT 2,4,15 UNION ALL SELECT 3,5,15 UNION ALL SELECT 4,6,15 UNION ALL
  SELECT 1,4,20 UNION ALL SELECT 2,5,20 UNION ALL SELECT 3,6,20 UNION ALL
  SELECT 1,5,20 UNION ALL SELECT 2,6,20 UNION ALL
  SELECT 1,6,25
) f
WHERE r.routecode = 'R-2'
ON CONFLICT (routeid, fromstopsequence, tostopsequence) DO NOTHING;

-- Route R-3
INSERT INTO farestructure (routeid, fromstopsequence, tostopsequence, fareamountnpr)
SELECT r.routeid, f.fs, f.ts, f.fare
FROM routes r
CROSS JOIN (
  SELECT 1 AS fs, 2 AS ts, 15 AS fare UNION ALL SELECT 2,3,15 UNION ALL SELECT 3,4,15 UNION ALL SELECT 4,5,15 UNION ALL SELECT 5,6,15 UNION ALL
  SELECT 1,3,15 UNION ALL SELECT 2,4,15 UNION ALL SELECT 3,5,15 UNION ALL SELECT 4,6,15 UNION ALL
  SELECT 1,4,20 UNION ALL SELECT 2,5,20 UNION ALL SELECT 3,6,20 UNION ALL
  SELECT 1,5,25 UNION ALL SELECT 2,6,25 UNION ALL
  SELECT 1,6,30
) f
WHERE r.routecode = 'R-3'
ON CONFLICT (routeid, fromstopsequence, tostopsequence) DO NOTHING;

-- ============================================================
-- 7. ASSIGN VEHICLES TO ROUTES
-- ============================================================

BEGIN;

INSERT INTO vehicleroutes (vehicleid, routeid, isactive)
SELECT v.vehicleid, r.routeid, true
FROM vehicles v, routes r
WHERE v.registrationnumber = 'Ga 1 Kha 3045' AND r.routecode = 'R-1'
ON CONFLICT (vehicleid, routeid) DO NOTHING;

INSERT INTO vehicleroutes (vehicleid, routeid, isactive)
SELECT v.vehicleid, r.routeid, true
FROM vehicles v, routes r
WHERE v.registrationnumber = 'Ga 1 Kha 3045' AND r.routecode = 'R-2'
ON CONFLICT (vehicleid, routeid) DO NOTHING;

INSERT INTO vehicleroutes (vehicleid, routeid, isactive)
SELECT v.vehicleid, r.routeid, true
FROM vehicles v, routes r
WHERE v.registrationnumber = 'Ga 2 Kha 7812' AND r.routecode = 'R-3'
ON CONFLICT (vehicleid, routeid) DO NOTHING;

COMMIT;

-- ============================================================
-- 8. PASSENGERS with RFID cards and balance
-- ============================================================
-- 1 token = 5 NPR. Balance ≥ 10 tokens required to tap in.

BEGIN;

-- Passenger 1: Demo Passenger — 100 tokens
INSERT INTO users (firebaseuid, email, phonenumber, passwordhash, role, accountstatus)
VALUES ('demo_passenger_uid_001', 'xedahod201@soppat.com', '9846100001', 'firebase-auth', 'Passenger', 'Active')
ON CONFLICT (firebaseuid) DO UPDATE SET email = EXCLUDED.email;

INSERT INTO rfidcards (carduid, cardstatus, issuedat)
SELECT '0010870497', 'Active', NOW()
WHERE NOT EXISTS (SELECT 1 FROM rfidcards WHERE carduid = '0010870497');

INSERT INTO passengers (userid, fullname, accountbalancenpr, address, citizenshipnumber, rfidcardid)
SELECT u.userid, 'Demo Passenger', 100, 'Pokhara', '45-01-00001',
       (SELECT cardid FROM rfidcards WHERE carduid = '0010870497')
FROM users u
WHERE u.firebaseuid = 'demo_passenger_uid_001'
  AND NOT EXISTS (SELECT 1 FROM passengers WHERE userid = u.userid);

COMMIT;

-- -- ============================================================
-- -- 9. TOP-UP TRANSACTIONS (payment history)
-- -- ============================================================
-- -- These match the column names from payment.controller.js:
-- --   transactions(userid, transactiontype, amountnpr, balancebeforenpr,
-- --                balanceafternpr, paymentmethod)

-- -- Bikash: Cash top-up NPR 500 → 100 tokens
-- INSERT INTO transactions (userid, transactiontype, amountnpr, balancebeforenpr, balanceafternpr, paymentmethod, transactiontime)
-- SELECT u.userid, 'TopUp', 500, 0, 100, 'Cash', NOW() - INTERVAL '3 days'
-- FROM users u
-- WHERE u.firebaseuid = 'demo_passenger_uid_001'
--   AND NOT EXISTS (
--     SELECT 1 FROM transactions t
--     WHERE t.userid = u.userid AND t.transactiontype = 'TopUp' AND t.amountnpr = 500
--   );

-- -- Anita: Khalti top-up NPR 250 → 50 tokens
-- INSERT INTO transactions (userid, transactiontype, amountnpr, balancebeforenpr, balanceafternpr, paymentmethod, transactiontime)
-- SELECT u.userid, 'TopUp', 250, 0, 50, 'Khalti:demo_pidx_001', NOW() - INTERVAL '2 days'
-- FROM users u
-- WHERE u.firebaseuid = 'demo_passenger_uid_002'
--   AND NOT EXISTS (
--     SELECT 1 FROM transactions t
--     WHERE t.userid = u.userid AND t.transactiontype = 'TopUp' AND t.amountnpr = 250
--   );

-- -- Suresh: Cash top-up NPR 1000 → 200 tokens
-- INSERT INTO transactions (userid, transactiontype, amountnpr, balancebeforenpr, balanceafternpr, paymentmethod, transactiontime)
-- SELECT u.userid, 'TopUp', 1000, 0, 200, 'Cash', NOW() - INTERVAL '4 days'
-- FROM users u
-- WHERE u.firebaseuid = 'demo_passenger_uid_003'
--   AND NOT EXISTS (
--     SELECT 1 FROM transactions t
--     WHERE t.userid = u.userid AND t.transactiontype = 'TopUp' AND t.amountnpr = 1000
--   );

-- -- ============================================================
-- -- 10. SAMPLE COMPLETED RIDES (fare deduction history)
-- -- ============================================================
-- -- Column names match rides.controller.js tapOut():
-- --   rides(passengerid, vehicleid, routeid, entrystopid, exitstopid,
-- --         ridestatus, entrytime, exittime, fareamountnpr,
-- --         balancebeforeentrynpr, balanceafterexitnpr)

-- -- Bikash: Prithvi Chowk → Chipledhunga (2 stops, NPR 15, 3 tokens deducted)
-- INSERT INTO rides (passengerid, vehicleid, routeid, entrystopid, exitstopid,
--                    ridestatus, entrytime, exittime, fareamountnpr,
--                    balancebeforeentrynpr, balanceafterexitnpr)
-- SELECT
--   p.passengerid,
--   v.vehicleid,
--   r.routeid,
--   (SELECT s.stopid FROM stops s JOIN routestops rs ON s.stopid = rs.stopid WHERE rs.routeid = r.routeid AND rs.stopsequence = 1),
--   (SELECT s.stopid FROM stops s JOIN routestops rs ON s.stopid = rs.stopid WHERE rs.routeid = r.routeid AND rs.stopsequence = 3),
--   'Completed',
--   NOW() - INTERVAL '1 day 3 hours',
--   NOW() - INTERVAL '1 day 2 hours 40 minutes',
--   15,     -- fare NPR
--   103,    -- balance before (tokens)
--   100     -- balance after  (tokens) → 3 tokens deducted (15 NPR / 5)
-- FROM passengers p
-- JOIN users u ON p.userid = u.userid
-- CROSS JOIN vehicles v
-- CROSS JOIN routes r
-- WHERE u.firebaseuid = 'demo_passenger_uid_001'
--   AND v.registrationnumber = 'Ga 1 Kha 3045'
--   AND r.routecode = 'R-1'
--   AND NOT EXISTS (
--     SELECT 1 FROM rides rd
--     WHERE rd.passengerid = p.passengerid AND rd.ridestatus = 'Completed'
--   );

-- -- Bikash's fare transaction for the ride above
-- INSERT INTO transactions (userid, rideid, transactiontype, amountnpr, balancebeforenpr, balanceafternpr, transactiontime)
-- SELECT u.userid,
--        (SELECT rd.rideid FROM rides rd JOIN passengers pp ON rd.passengerid = pp.passengerid WHERE pp.userid = u.userid AND rd.ridestatus = 'Completed' LIMIT 1),
--        'RidePayment', 15, 103, 100, NOW() - INTERVAL '1 day 2 hours 40 minutes'
-- FROM users u
-- WHERE u.firebaseuid = 'demo_passenger_uid_001'
--   AND NOT EXISTS (
--     SELECT 1 FROM transactions t
--     WHERE t.userid = u.userid AND t.transactiontype = 'RidePayment'
--   );

-- -- Anita: Hallanchowk → Prithvi Chowk (3 stops on R-2, NPR 15)
-- INSERT INTO rides (passengerid, vehicleid, routeid, entrystopid, exitstopid,
--                    ridestatus, entrytime, exittime, fareamountnpr,
--                    balancebeforeentrynpr, balanceafterexitnpr)
-- SELECT
--   p.passengerid,
--   v.vehicleid,
--   r.routeid,
--   (SELECT s.stopid FROM stops s JOIN routestops rs ON s.stopid = rs.stopid WHERE rs.routeid = r.routeid AND rs.stopsequence = 1),
--   (SELECT s.stopid FROM stops s JOIN routestops rs ON s.stopid = rs.stopid WHERE rs.routeid = r.routeid AND rs.stopsequence = 4),
--   'Completed',
--   NOW() - INTERVAL '18 hours',
--   NOW() - INTERVAL '17 hours 30 minutes',
--   20,    -- 3-stop fare
--   53,    -- balance before
--   49     -- balance after (4 tokens = 20 NPR / 5)
-- FROM passengers p
-- JOIN users u ON p.userid = u.userid
-- CROSS JOIN vehicles v
-- CROSS JOIN routes r
-- WHERE u.firebaseuid = 'demo_passenger_uid_002'
--   AND v.registrationnumber = 'Ga 1 Kha 3045'
--   AND r.routecode = 'R-2'
--   AND NOT EXISTS (
--     SELECT 1 FROM rides rd
--     WHERE rd.passengerid = p.passengerid AND rd.ridestatus = 'Completed'
--   );

-- -- Suresh: Bus Park → Baidam (full route R-3, NPR 30)
-- INSERT INTO rides (passengerid, vehicleid, routeid, entrystopid, exitstopid,
--                    ridestatus, entrytime, exittime, fareamountnpr,
--                    balancebeforeentrynpr, balanceafterexitnpr)
-- SELECT
--   p.passengerid,
--   v.vehicleid,
--   r.routeid,
--   (SELECT s.stopid FROM stops s JOIN routestops rs ON s.stopid = rs.stopid WHERE rs.routeid = r.routeid AND rs.stopsequence = 1),
--   (SELECT s.stopid FROM stops s JOIN routestops rs ON s.stopid = rs.stopid WHERE rs.routeid = r.routeid AND rs.stopsequence = 6),
--   'Completed',
--   NOW() - INTERVAL '2 days 1 hour',
--   NOW() - INTERVAL '2 days 15 minutes',
--   30,    -- full route fare
--   206,   -- balance before
--   200    -- balance after (6 tokens = 30 NPR / 5)
-- FROM passengers p
-- JOIN users u ON p.userid = u.userid
-- CROSS JOIN vehicles v
-- CROSS JOIN routes r
-- WHERE u.firebaseuid = 'demo_passenger_uid_003'
--   AND v.registrationnumber = 'Ga 2 Kha 7812'
--   AND r.routecode = 'R-3'
--   AND NOT EXISTS (
--     SELECT 1 FROM rides rd
--     WHERE rd.passengerid = p.passengerid AND rd.ridestatus = 'Completed'
--   );

-- -- ============================================================
-- -- 11. SAMPLE COMPLAINTS
-- -- ============================================================
-- -- Column names from complaints.controller.js createComplaint():
-- --   complaints(userid, passengerid, rideid, complainttext,
-- --              complaintstatus, complaintdate)

-- INSERT INTO complaints (userid, passengerid, rideid, complainttext, complaintstatus, complaintdate)
-- SELECT u.userid, p.passengerid,
--        (SELECT rideid FROM rides WHERE passengerid = p.passengerid LIMIT 1),
--        'The bus from Prithvi Chowk was 25 minutes late. Driver did not stop at Chipledhunga properly.',
--        'Pending', NOW() - INTERVAL '5 hours'
-- FROM users u
-- JOIN passengers p ON u.userid = p.userid
-- WHERE u.firebaseuid = 'demo_passenger_uid_001'
--   AND NOT EXISTS (SELECT 1 FROM complaints c WHERE c.userid = u.userid);

-- INSERT INTO complaints (userid, passengerid, complainttext, complaintstatus, complaintdate)
-- SELECT u.userid, p.passengerid,
--        'The RFID reader at Hallanchowk was not responding. Had to tap multiple times.',
--        'InProgress', NOW() - INTERVAL '1 hour'
-- FROM users u
-- JOIN passengers p ON u.userid = p.userid
-- WHERE u.firebaseuid = 'demo_passenger_uid_002'
--   AND NOT EXISTS (SELECT 1 FROM complaints c WHERE c.userid = u.userid);

-- -- ============================================================
-- -- 12. NOTIFICATIONS (so admin dashboard shows activity)
-- -- ============================================================

-- INSERT INTO notifications (userid, title, message, type, isread)
-- SELECT u.userid, 'New Complaint', 'A new complaint has been filed: "The bus from Prithvi Chowk was 25 min..."', 'complaint', false
-- FROM users u
-- WHERE u.firebaseuid = 'demo_admin_uid_001'
--   AND NOT EXISTS (
--     SELECT 1 FROM notifications n WHERE n.userid = u.userid AND n.type = 'complaint'
--   );

-- INSERT INTO notifications (userid, title, message, type, isread)
-- SELECT u.userid, 'New Registration', 'A new Passenger account has been registered (bikash@example.com).', 'registration', true
-- FROM users u
-- WHERE u.firebaseuid = 'demo_admin_uid_001'
--   AND NOT EXISTS (
--     SELECT 1 FROM notifications n WHERE n.userid = u.userid AND n.type = 'registration'
--   );

-- COMMIT;

-- -- ============================================================
-- -- SUMMARY
-- -- ============================================================
-- --
-- -- USERS:
-- --   admin@sawari.app          (Admin)
-- --   pokharayatayat@sawari.app (Operator — approved)
-- --   bikash@example.com        (Passenger — 100 tokens, RFID-PKR-0001)
-- --   anita@example.com         (Passenger —  50 tokens, RFID-PKR-0002)
-- --   suresh@example.com        (Passenger — 200 tokens, RFID-PKR-0003)
-- --   maya@example.com          (Passenger —   5 tokens, RFID-PKR-0004, LOW BALANCE)
-- --   kumar@example.com         (Passenger —   0 tokens, NO RFID CARD)
-- --
-- -- VEHICLES:
-- --   Ga 1 Kha 3045  (Bus,     40 seats) → Routes R-1, R-2
-- --   Ga 2 Kha 7812  (Minibus, 22 seats) → Route R-3
-- --
-- -- STOPS (12 Pokhara locations):
-- --   Prithvi Chowk, Mahendrapool, Chipledhunga, Srijana Chowk,
-- --   Lakeside, Bagar, Naya Bazar, Hallanchowk, Bus Park,
-- --   Mustang Chowk, Baidam, Bindabasini
-- --
-- -- ROUTES:
-- --   R-1: Prithvi Chowk → Mahendrapool → Chipledhunga → Bindabasini → Naya Bazar → Bus Park
-- --   R-2: Hallanchowk → Mustang Chowk → Srijana Chowk → Prithvi Chowk → Bagar → Lakeside
-- --   R-3: Bus Park → Naya Bazar → Chipledhunga → Mahendrapool → Srijana Chowk → Baidam
-- --
-- -- FARE STRUCTURE: All 15 from→to pairs for each route
-- --   1 stop: NPR 15  |  2 stops: NPR 15  |  3 stops: NPR 20
-- --   4 stops: NPR 20-25  |  5 stops (full): NPR 25-30
-- --
-- -- ============================================================
-- -- HOW TO DEMO TAP-IN / TAP-OUT
-- -- ============================================================
-- --
-- -- The API key defaults to: sawari-rfid-secret-key
-- -- (set via RFID_API_KEY env variable, see rides.routes.js)
-- --
-- -- First, find the vehicle IDs:
-- --   SELECT vehicleid, registrationnumber FROM vehicles;
-- --
-- -- 1) TAP IN — Bikash boards at Prithvi Chowk:
-- --    curl -X POST http://localhost:3000/api/rides/tap-in \
-- --      -H "Content-Type: application/json" \
-- --      -H "x-api-key: sawari-rfid-secret-key" \
-- --      -d '{"rfid_card_uid": "RFID-PKR-0001", "vehicle_id": <VEHICLE_ID>}'
-- --
-- -- 2) TAP OUT — Bikash exits at Naya Bazar (stop 5):
-- --    curl -X POST http://localhost:3000/api/rides/tap-out \
-- --      -H "Content-Type: application/json" \
-- --      -H "x-api-key: sawari-rfid-secret-key" \
-- --      -d '{"rfid_card_uid": "RFID-PKR-0001", "vehicle_id": <VEHICLE_ID>}'
-- --
-- -- 3) LOW BALANCE REJECTION — Maya tries to board:
-- --    curl -X POST http://localhost:3000/api/rides/tap-in \
-- --      -H "Content-Type: application/json" \
-- --      -H "x-api-key: sawari-rfid-secret-key" \
-- --      -d '{"rfid_card_uid": "RFID-PKR-0004", "vehicle_id": <VEHICLE_ID>}'
-- --    → Returns 403: "Insufficient balance. Minimum 10 tokens required."
-- --
-- -- 4) NO CARD — Unknown RFID:
-- --    curl -X POST http://localhost:3000/api/rides/tap-in \
-- --      -H "Content-Type: application/json" \
-- --      -H "x-api-key: sawari-rfid-secret-key" \
-- --      -d '{"rfid_card_uid": "UNKNOWN-CARD", "vehicle_id": <VEHICLE_ID>}'
-- --    → Returns 404: "RFID card not found"
-- --
-- -- 5) SAME-STOP EXIT (cancel):
-- --    Tap in, then immediately tap out at the same stop
-- --    → Ride cancelled with zero fare
-- --
-- -- After tap-out, check the balance was deducted:
-- --   SELECT fullname, accountbalancenpr FROM passengers;
-- -- ============================================================
