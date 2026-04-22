/**
 * RFID card reader client for tap-in/tap-out ride processing.
 * Captures HID keyboard input from a USB RFID reader and relays events to the backend API.
 *
 * Usage:
 *   node rfid_reader.js
 *
 * Then type a card UID and press Enter to simulate a scan.
 * First scan = tap-in, second scan = tap-out.
 *
 * Before running, set VEHICLE_ID and STOP_ID below to match your DB.
 * Run this SQL to find your IDs:
 *   SELECT v.vehicleid, v.registrationnumber, r.routecode, rs.stopsequence, s.stopid, s.stopname
 *   FROM vehicles v
 *   JOIN vehicleroutes vr ON v.vehicleid = vr.vehicleid
 *   JOIN routes r ON vr.routeid = r.routeid
 *   JOIN routestops rs ON r.routeid = rs.routeid
 *   JOIN stops s ON rs.stopid = s.stopid
 *   ORDER BY v.vehicleid, r.routecode, rs.stopsequence;
 */

const http = require('http');
const readline = require('readline');

// ─── Configuration ───────────────────────────────────────────────
const VEHICLE_ID = 1;                                    // Set your vehicle ID here
const TAP_IN_STOP_ID = null;                             // Set entry stop ID (or null to prompt)
const TAP_OUT_STOP_ID = null;                            // Set exit stop ID (or null to prompt)
const API_URL = 'http://localhost:3000/api';
const API_KEY = 'sawari-rfid-secret-key';
// ─────────────────────────────────────────────────────────────────

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

function ask(question) {
  return new Promise(resolve => rl.question(question, resolve));
}

async function main() {
  console.log('════════════════════════════════════════');
  console.log('  Sawari RFID Reader Simulator');
  console.log('════════════════════════════════════════');
  console.log(`Vehicle ID: ${VEHICLE_ID}`);
  console.log(`Backend:    ${API_URL}`);
  console.log('');

  // If stop IDs not set, fetch available stops from an interactive prompt
  let tapInStop = TAP_IN_STOP_ID;
  let tapOutStop = TAP_OUT_STOP_ID;

  if (!tapInStop || !tapOutStop) {
    console.log('Stop IDs not configured. Enter them now:');
    if (!tapInStop) {
      tapInStop = parseInt(await ask('  Entry stop ID (tap-in): '));
    }
    if (!tapOutStop) {
      tapOutStop = parseInt(await ask('  Exit stop ID (tap-out):  '));
    }
    console.log('');
  }

  console.log(`Entry stop: ${tapInStop} | Exit stop: ${tapOutStop}`);
  console.log('');
  console.log('Scan a card (type UID + Enter)...');
  console.log('');

  // Track which cards are currently on a ride (for choosing stop)
  const ongoingRides = new Set();

  rl.on('line', async (input) => {
    const cardUid = input.trim();
    if (!cardUid) return;

    console.log(`\nCard scanned: ${cardUid}`);

    try {
      if (ongoingRides.has(cardUid)) {
        // Card has an ongoing ride — do tap-out
        const tapOutResult = await apiCall('POST', '/rides/tap-out', {
          rfid_card_uid: cardUid,
          vehicle_id: VEHICLE_ID,
          stop_id: tapOutStop,
        });

        if (tapOutResult.success) {
          const d = tapOutResult.data;
          ongoingRides.delete(cardUid);
          console.log(`  ✓ TAP-OUT: ${d.entry_stop} → ${d.exit_stop}`);
          console.log(`    Fare: ${d.fare} NPR | Balance: ${d.balance_after} tokens`);
          if (d.status === 'Cancelled') {
            console.log('    (Same stop — ride cancelled, no charge)');
          }
        } else {
          console.log(`  ✗ Error: ${tapOutResult.error}`);
        }
      } else {
        // No ongoing ride — do tap-in
        const tapInResult = await apiCall('POST', '/rides/tap-in', {
          rfid_card_uid: cardUid,
          vehicle_id: VEHICLE_ID,
          stop_id: tapInStop,
        });

        if (tapInResult.success) {
          const d = tapInResult.data;
          ongoingRides.add(cardUid);
          console.log(`  ✓ TAP-IN: Ride started at ${d.entry_stop}`);
          console.log(`    Route: ${d.routename} | Balance: ${d.balance} tokens`);
        } else if (
          tapInResult.error?.includes('already has an ongoing ride') ||
          tapInResult.error?.includes('tap out first')
        ) {
          // Card already has a ride (from a previous session) — do tap-out instead
          ongoingRides.add(cardUid);
          console.log('  → Already has ongoing ride, scanning again to tap out...');
        } else {
          console.log(`  ✗ Error: ${tapInResult.error}`);
        }
      }
    } catch (err) {
      console.log(`  ✗ Connection error: ${err.message}`);
    }

    console.log('\nWaiting for next scan...');
  });
}

/**
 * Sends an HTTP request to the backend API.
 */
function apiCall(method, endpoint, body) {
  return new Promise((resolve) => {
    const url = new URL(API_URL + endpoint);
    const postData = JSON.stringify(body);

    const options = {
      hostname: url.hostname,
      port: url.port || 3000,
      path: url.pathname,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': API_KEY,
        'Content-Length': Buffer.byteLength(postData),
      },
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch {
          resolve({ success: false, error: 'Invalid response from server' });
        }
      });
    });

    req.on('error', (err) => {
      resolve({ success: false, error: err.message });
    });

    req.setTimeout(10000, () => {
      req.destroy();
      resolve({ success: false, error: 'Request timed out' });
    });

    req.write(postData);
    req.end();
  });
}

main();
