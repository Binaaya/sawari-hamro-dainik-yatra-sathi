const db = require('../config/database');
const firebase = require('../config/firebase');
const { asyncHandler, ApiError } = require('../middleware/errorHandler');
const { notifyUser } = require('./notifications.controller');

/**
 * Register a new user
 * POST /api/auth/register
 */
const register = asyncHandler(async (req, res) => {
  const { firebaseUid, email, phone, fullName, role, citizenshipNumber } = req.body;

  // Validate required fields
  if (!firebaseUid || !email || !fullName || !role) {
    throw new ApiError(400, 'Missing required fields: firebaseUid, email, fullName, role');
  }

  // Validate role
  const validRoles = ['Passenger', 'Operator'];
  if (!validRoles.includes(role)) {
    throw new ApiError(400, 'Invalid role. Must be Passenger or Operator');
  }

  const result = await db.transaction(async (client) => {
    // Create user record
    const userResult = await client.query(
      `INSERT INTO users (firebaseuid, email, phonenumber, passwordhash, role, accountstatus)
       VALUES ($1, $2, $3, 'firebase-auth', $4, 'Active')
       RETURNING userid, firebaseuid, email, phonenumber, role, createdat`,
      [firebaseUid, email, phone, role]
    );

    const user = userResult.rows[0];

    // Create role-specific record
    if (role === 'Passenger') {
      await client.query(
        `INSERT INTO passengers (userid, fullname, citizenshipnumber, accountbalancenpr)
         VALUES ($1, $2, $3, 0)`,
        [user.userid, fullName, citizenshipNumber]
      );
    } else if (role === 'Operator') {
      const { companyName, panNumber } = req.body;
      if (!companyName) {
        throw new ApiError(400, 'Company name required for Operator registration');
      }

      let documentUrls = null;
      if (req.file) {
        documentUrls = JSON.stringify({ businessDocument: `/uploads/operators/${req.file.filename}` });
      }

      await client.query(
        `INSERT INTO operators (userid, operatorname, documenturls, approvalstatus)
         VALUES ($1, $2, $3, 'Pending')`,
        [user.userid, companyName, documentUrls]
      );
    }

    // Re-query to get full user data with role-specific fields
    const fullUser = await client.query(
      `SELECT u.userid, u.firebaseuid, u.email, u.phonenumber, u.role, u.accountstatus, u.createdat,
              p.passengerid, p.fullname, p.citizenshipnumber, p.accountbalancenpr, p.rfidcardid,
              rc.carduid,
              o.operatorid, o.operatorname, o.approvalstatus
       FROM users u
       LEFT JOIN passengers p ON u.userid = p.userid
       LEFT JOIN rfidcards rc ON p.rfidcardid = rc.cardid
       LEFT JOIN operators o ON u.userid = o.userid
       WHERE u.userid = $1`,
      [user.userid]
    );

    return fullUser.rows[0];
  });
  
  // Notify admins of new registration
  try {
    const admins = await db.query("SELECT userid FROM users WHERE role = 'Admin'");
    for (const admin of admins.rows) {
      await notifyUser(admin.userid, 'New Registration', `A new ${role} account has been registered (${email}).`, 'registration');
    }
  } catch (notifErr) {
    console.error('Failed to send registration notification:', notifErr.message);
  }

  res.status(201).json({
    success: true,
    message: 'User registered successfully',
    data: { user: result }
  });
});

/**
 * Login - verify Firebase token and return user data
 * POST /api/auth/login
 */
const login = asyncHandler(async (req, res) => {
  const { idToken } = req.body;
  
  if (!idToken) {
    throw new ApiError(400, 'ID token required');
  }
  
  // Verify Firebase token
  const decodedToken = await firebase.verifyIdToken(idToken);
  
  // Get user from database
  const userResult = await db.query(
    `SELECT u.*,
            p.passengerid, p.accountbalancenpr, p.rfidcardid, p.fullname,
            rc.carduid,
            o.operatorid, o.operatorname, o.approvalstatus as operator_approved
     FROM users u
     LEFT JOIN passengers p ON u.userid = p.userid
     LEFT JOIN rfidcards rc ON p.rfidcardid = rc.cardid
     LEFT JOIN operators o ON u.userid = o.userid
     WHERE u.firebaseuid = $1`,
    [decodedToken.uid]
  );

  if (userResult.rows.length === 0) {
    throw new ApiError(404, 'User not found. Please register first.');
  }

  const user = userResult.rows[0];

  // Block suspended/inactive accounts
  if (user.accountstatus === 'Suspended') {
    throw new ApiError(403, 'Your account has been suspended. Please contact support.');
  }
  if (user.accountstatus === 'Inactive') {
    throw new ApiError(403, 'Your account is inactive. Please contact support to reactivate.');
  }

  // Update last login
  await db.query(
    'UPDATE users SET updatedat = NOW() WHERE userid = $1',
    [user.userid]
  );
  
  res.json({
    success: true,
    data: { user }
  });
});

/**
 * Get current user profile
 * GET /api/auth/me
 */
const getCurrentUser = asyncHandler(async (req, res) => {
  const user = req.user;
  
  // Get additional details based on role
  let additionalData = {};
  
  if (user.role === 'Passenger' && user.rfidcardid) {
    const rfidResult = await db.query(
      'SELECT * FROM rfidcards WHERE cardid = $1',
      [user.rfidcardid]
    );
    if (rfidResult.rows.length > 0) {
      additionalData.rfidCard = rfidResult.rows[0];
    }
  }
  
  res.json({
    success: true,
    data: { 
      user: { ...user, ...additionalData }
    }
  });
});

/**
 * Update user profile
 * PUT /api/auth/profile
 */
const updateProfile = asyncHandler(async (req, res) => {
  const userId = req.user.userid;
  const role = req.user.role;
  const { fullName, phone, address } = req.body;
  const profilePicFile = req.file;

  if (!fullName && !phone && !address && !profilePicFile) {
    throw new ApiError(400, 'No fields to update');
  }

  // Update phone on users table
  if (phone) {
    await db.query(
      'UPDATE users SET phonenumber = $1, updatedat = NOW() WHERE userid = $2',
      [phone, userId]
    );
  }

  // Update role-specific fields
  if (role === 'Passenger') {
    if (fullName) {
      await db.query('UPDATE passengers SET fullname = $1 WHERE userid = $2', [fullName, userId]);
    }
    if (address) {
      await db.query('UPDATE passengers SET address = $1 WHERE userid = $2', [address, userId]);
    }
    if (profilePicFile) {
      const picturePath = `/uploads/passengers/${profilePicFile.filename}`;
      await db.query('UPDATE passengers SET profilepicture = $1 WHERE userid = $2', [picturePath, userId]);
    }
  } else if (role === 'Operator' && fullName) {
    await db.query('UPDATE operators SET operatorname = $1 WHERE userid = $2', [fullName, userId]);
  }

  // Return updated user info via join (same as auth middleware)
  const result = await db.query(
    `SELECT u.userid, u.email, u.phonenumber, u.role, u.updatedat,
            COALESCE(p.fullname, o.operatorname) as fullname,
            p.address, p.profilepicture
     FROM users u
     LEFT JOIN passengers p ON u.userid = p.userid
     LEFT JOIN operators o ON u.userid = o.userid
     WHERE u.userid = $1`,
    [userId]
  );

  res.json({
    success: true,
    message: 'Profile updated successfully',
    data: { user: result.rows[0] }
  });
});

/**
 * Verify if token is valid
 * POST /api/auth/verify-token
 */
const verifyToken = asyncHandler(async (req, res) => {
  const { idToken } = req.body;
  
  if (!idToken) {
    throw new ApiError(400, 'ID token required');
  }
  
  try {
    const decodedToken = await firebase.verifyIdToken(idToken);
    res.json({
      success: true,
      data: { 
        valid: true,
        uid: decodedToken.uid,
        email: decodedToken.email
      }
    });
  } catch (error) {
    res.json({
      success: true,
      data: { 
        valid: false,
        error: error.message
      }
    });
  }
});

module.exports = {
  register,
  login,
  getCurrentUser,
  updateProfile,
  verifyToken
};
