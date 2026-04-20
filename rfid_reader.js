/**
 * RFID card reader client for tap-in/tap-out ride processing.
 * Captures HID keyboard input from a USB RFID reader and relays events to the backend API.
 */

const http = require('http');
const readline = require('readline');

// Configuration
const VEHICLE_ID = 1;                                    // Set your vehicle ID here
const API_URL = 'http://localhost:3000/api';              // Your backend URL
const API_KEY = 'sawari-rfid-secret-key';                 // Same key as backend expects

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

console.log('Sawari RFID Reader');
console.log(`Vehicle ID: ${VEHICLE_ID}`);
console.log(`Backend:    ${API_URL}`);
console.log('Awaiting card scan...');
console.log('');

rl.on('line', async (input) => {
  const cardUid = input.trim();
  if (!cardUid) return;

  console.log(`\nCard scanned: ${cardUid}`);

  try {
    // Attempt tap-out; fall back to tap-in if no ongoing ride
    const ongoingResult = await apiCall('POST', '/rides/tap-out', {
      rfid_card_uid: cardUid,
      vehicle_id: VEHICLE_ID,
    });

    if (ongoingResult.success) {
      const d = ongoingResult.data;
      console.log(`TAP-OUT: ${d.entry_stop} -> ${d.exit_stop}`);
      console.log(`   Fare: Rs. ${d.fare} | Balance: Rs. ${d.balance_after}`);
      if (d.status === 'Cancelled') {
        console.log('   (Same stop — ride cancelled, no charge)');
      }
    } else {
      // No ongoing ride — initiate tap-in
      if (ongoingResult.error?.includes('No ongoing ride') || ongoingResult.error?.includes('tap in first')) {
        const tapInResult = await apiCall('POST', '/rides/tap-in', {
          rfid_card_uid: cardUid,
          vehicle_id: VEHICLE_ID,
        });

        if (tapInResult.success) {
          const d = tapInResult.data;
          console.log(`TAP-IN: Ride started at ${d.entry_stop}`);
          console.log(`   Route: ${d.routename} | Balance: Rs. ${d.balance}`);
        } else {
          console.log(`Error: ${tapInResult.error}`);
        }
      } else {
        console.log(`Error: ${ongoingResult.error}`);
      }
    }
  } catch (err) {
    console.log(`Connection error: ${err.message}`);
  }

  console.log('Waiting for next scan...');
});

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
