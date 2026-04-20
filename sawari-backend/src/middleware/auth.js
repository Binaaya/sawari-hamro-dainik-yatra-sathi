const firebase = require('../config/firebase');
const db = require('../config/database');

/**
 * Verify Firebase ID token and attach user to request
 */
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        error: 'No token provided'
      });
    }

    const idToken = authHeader.split('Bearer ')[1];

    // Verify the Firebase token
    const decodedToken = await firebase.verifyIdToken(idToken);

    // Get user from database
    const userResult = await db.query(
      `SELECT u.*, p.passengerid, p.accountbalancenpr, p.rfidcardid, p.fullname, p.citizenshipnumber,
              o.operatorid, o.operatorname, o.approvalstatus as operator_approved
       FROM users u
       LEFT JOIN passengers p ON u.userid = p.userid
       LEFT JOIN operators o ON u.userid = o.userid
       WHERE u.firebaseuid = $1`,
      [decodedToken.uid]
    );

    if (userResult.rows.length === 0) {
      return res.status(401).json({
        success: false,
        error: 'User not found in database'
      });
    }

    // Attach user to request
    req.user = userResult.rows[0];
    req.firebaseUser = decodedToken;

    next();
  } catch (error) {
    console.error('Auth error:', error.message);

    if (error.code === 'auth/id-token-expired') {
      return res.status(401).json({
        success: false,
        error: 'Token expired'
      });
    }

    return res.status(401).json({
      success: false,
      error: 'Invalid token'
    });
  }
};

/**
 * Check if user has required role
 */
const requireRole = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required'
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        error: `Access denied. Required role: ${roles.join(' or ')}`
      });
    }

    next();
  };
};

/**
 * Check if operator is approved
 */
const requireApprovedOperator = (req, res, next) => {
  if (req.user.role === 'Operator' && req.user.operator_approved !== 'Approved') {
    return res.status(403).json({
      success: false,
      error: 'Operator account pending approval'
    });
  }
  next();
};

/**
 * Optional authentication - doesn't fail if no token
 */
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (authHeader && authHeader.startsWith('Bearer ')) {
      const idToken = authHeader.split('Bearer ')[1];
      const decodedToken = await firebase.verifyIdToken(idToken);

      const userResult = await db.query(
        `SELECT u.*, p.passengerid, p.accountbalancenpr, p.rfidcardid
         FROM users u
         LEFT JOIN passengers p ON u.userid = p.userid
         WHERE u.firebaseuid = $1`,
        [decodedToken.uid]
      );

      if (userResult.rows.length > 0) {
        req.user = userResult.rows[0];
        req.firebaseUser = decodedToken;
      }
    }

    next();
  } catch (error) {
    // Continue without auth
    next();
  }
};

module.exports = {
  authenticate,
  requireRole,
  requireApprovedOperator,
  optionalAuth
};
