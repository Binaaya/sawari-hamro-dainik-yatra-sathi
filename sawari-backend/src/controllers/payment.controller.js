const db = require('../config/database');
const { asyncHandler, ApiError } = require('../middleware/errorHandler');

const KHALTI_SECRET_KEY = process.env.KHALTI_SECRET_KEY;
const KHALTI_BASE_URL = 'https://dev.khalti.com/api/v2';

/**
 * Initiate a Khalti payment
 * POST /api/payments/khalti/initiate
 */
const initiateKhaltiPayment = asyncHandler(async (req, res) => {
  const { amount } = req.body; // amount in NPR
  const passengerId = req.user.passengerid;

  if (!KHALTI_SECRET_KEY) {
    throw new ApiError(500, 'Payment service not configured');
  }

  if (!passengerId) {
    throw new ApiError(400, 'Only passengers can top up');
  }

  if (!amount || amount < 10) {
    throw new ApiError(400, 'Minimum top-up amount is NPR 10');
  }

  if (amount > 10000) {
    throw new ApiError(400, 'Maximum top-up amount is NPR 10,000');
  }

  // Khalti expects amount in paisa (1 NPR = 100 paisa)
  const amountInPaisa = Math.round(amount * 100);

  const payload = {
    return_url: process.env.KHALTI_RETURN_URL || 'https://example.com/payment/success',
    website_url: process.env.KHALTI_WEBSITE_URL || 'https://example.com',
    amount: amountInPaisa,
    purchase_order_id: `SAWARI-${passengerId}-${Date.now()}`,
    purchase_order_name: `Sawari Top-Up NPR ${amount}`,
    customer_info: {
      name: req.user.fullname || 'Sawari User',
      email: req.user.email,
      phone: req.user.phonenumber || '',
    },
  };

  const response = await fetch(`${KHALTI_BASE_URL}/epayment/initiate/`, {
    method: 'POST',
    headers: {
      'Authorization': `Key ${KHALTI_SECRET_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  const data = await response.json();

  if (!response.ok) {
    console.error('Khalti initiate error:', data);
    throw new ApiError(502, 'Payment initiation failed. Please try again.');
  }

  res.json({
    success: true,
    data: {
      pidx: data.pidx,
      payment_url: data.payment_url,
      amount,
    },
  });
});

/**
 * Verify a Khalti payment and credit balance
 * POST /api/payments/khalti/verify
 */
const verifyKhaltiPayment = asyncHandler(async (req, res) => {
  const { pidx } = req.body;
  const userId = req.user.userid;
  const passengerId = req.user.passengerid;

  if (!pidx) {
    throw new ApiError(400, 'Payment ID (pidx) is required');
  }

  if (!passengerId) {
    throw new ApiError(400, 'Only passengers can verify top-ups');
  }

  // Lookup the payment via Khalti — retry up to 3 times since
  // test sandbox status can take a moment to propagate
  let data;
  const maxAttempts = 3;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    const response = await fetch(`${KHALTI_BASE_URL}/epayment/lookup/`, {
      method: 'POST',
      headers: {
        'Authorization': `Key ${KHALTI_SECRET_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ pidx }),
    });

    data = await response.json();
    console.log(`Khalti lookup attempt ${attempt}:`, JSON.stringify(data));

    if (!response.ok) {
      console.error('Khalti lookup error:', data);
      if (attempt === maxAttempts) {
        throw new ApiError(502, 'Payment verification failed');
      }
      await new Promise(r => setTimeout(r, 2000));
      continue;
    }

    if (data.status && data.status.toLowerCase() === 'completed') {
      break; // Payment confirmed
    }

    // Not completed yet — retry after delay
    if (attempt < maxAttempts) {
      console.log(`Payment status: ${data.status} — retrying in 2s...`);
      await new Promise(r => setTimeout(r, 2000));
    }
  }

  if (!data.status || data.status.toLowerCase() !== 'completed') {
    throw new ApiError(400, `Payment is not complete (status: ${data.status || 'unknown'}). Please try again.`);
  }

  // Amount from Khalti is in paisa, convert to NPR
  const amountNpr = data.total_amount / 100;

  // Credit the balance inside a DB transaction
  const result = await db.transaction(async (client) => {
    // Idempotency: check if this exact amount was topped up in the last 30 seconds
    // (prevents double-credit from retry logic)
    const existing = await client.query(
      `SELECT transactionid FROM transactions
       WHERE userid = $1 AND transactiontype = 'TopUp' AND paymentmethod = 'Khalti'
         AND amountnpr = $2 AND transactiontime > NOW() - INTERVAL '30 seconds'`,
      [userId, amountNpr]
    );

    if (existing.rows.length > 0) {
      const bal = await client.query(
        'SELECT accountbalancenpr FROM passengers WHERE passengerid = $1',
        [passengerId]
      );
      return {
        alreadyProcessed: true,
        balance: parseFloat(bal.rows[0].accountbalancenpr),
      };
    }

    // Get current balance with row lock
    const passengerResult = await client.query(
      'SELECT accountbalancenpr FROM passengers WHERE passengerid = $1 FOR UPDATE',
      [passengerId]
    );

    const currentBalance = parseFloat(passengerResult.rows[0].accountbalancenpr);
    const tokensToAdd = amountNpr / 5;
    const newBalance = currentBalance + tokensToAdd;

    // Update balance (stored as tokens, 5 NPR = 1 token)
    await client.query(
      'UPDATE passengers SET accountbalancenpr = $1 WHERE passengerid = $2',
      [newBalance, passengerId]
    );

    // Create transaction record — paymentmethod must match CHECK constraint
    const txResult = await client.query(
      `INSERT INTO transactions (userid, transactiontype, amountnpr, balancebeforenpr, balanceafternpr, paymentmethod)
       VALUES ($1, 'TopUp', $2, $3, $4, 'Khalti')
       RETURNING transactionid`,
      [userId, amountNpr, currentBalance, newBalance]
    );

    // Record in topuphistory with pidx for idempotency
    await client.query(
      `INSERT INTO topuphistory (transactionid, passengerid, topupamount, paymentmethod)
       VALUES ($1, $2, $3, 'Khalti')`,
      [txResult.rows[0].transactionid, passengerId, amountNpr]
    );

    return { currentBalance, newBalance, amount: amountNpr };
  });

  res.json({
    success: true,
    message: result.alreadyProcessed
      ? 'Payment was already processed'
      : 'Top-up successful',
    data: {
      amount: amountNpr,
      balance: result.newBalance || result.balance,
    },
  });
});

module.exports = {
  initiateKhaltiPayment,
  verifyKhaltiPayment,
};
