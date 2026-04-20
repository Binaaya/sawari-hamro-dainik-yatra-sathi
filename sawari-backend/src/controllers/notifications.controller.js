const db = require('../config/database');
const { admin } = require('../config/firebase');
const { asyncHandler, ApiError } = require('../middleware/errorHandler');

/**
 * Get notifications for the authenticated user
 * GET /api/notifications
 */
const getNotifications = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20 } = req.query;
  const userId = req.user.userid;
  const offset = (page - 1) * limit;

  const countResult = await db.query(
    'SELECT COUNT(*) as total FROM notifications WHERE userid = $1',
    [userId]
  );
  const total = parseInt(countResult.rows[0].total);

  const unreadResult = await db.query(
    'SELECT COUNT(*) as unread FROM notifications WHERE userid = $1 AND isread = FALSE',
    [userId]
  );
  const unread = parseInt(unreadResult.rows[0].unread);

  const result = await db.query(
    `SELECT * FROM notifications
     WHERE userid = $1
     ORDER BY createdat DESC
     LIMIT $2 OFFSET $3`,
    [userId, limit, offset]
  );

  res.json({
    success: true,
    data: {
      notifications: result.rows,
      unread,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / limit)
      }
    }
  });
});

/**
 * Mark a notification as read
 * PUT /api/notifications/:id/read
 */
const markAsRead = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.userid;

  const result = await db.query(
    `UPDATE notifications SET isread = TRUE
     WHERE notificationid = $1 AND userid = $2
     RETURNING *`,
    [id, userId]
  );

  if (result.rows.length === 0) {
    throw new ApiError(404, 'Notification not found');
  }

  res.json({
    success: true,
    message: 'Notification marked as read'
  });
});

/**
 * Register FCM token for push notifications
 * POST /api/notifications/register-token
 */
const registerToken = asyncHandler(async (req, res) => {
  const { fcmToken, deviceType = 'android' } = req.body;
  const userId = req.user.userid;

  if (!fcmToken) {
    throw new ApiError(400, 'FCM token is required');
  }

  // Upsert: insert or update on conflict
  await db.query(
    `INSERT INTO device_tokens (userid, fcm_token, device_type, updatedat)
     VALUES ($1, $2, $3, NOW())
     ON CONFLICT (fcm_token)
     DO UPDATE SET userid = $1, device_type = $3, updatedat = NOW()`,
    [userId, fcmToken, deviceType]
  );

  res.json({
    success: true,
    message: 'FCM token registered successfully'
  });
});

/**
 * Send push notification to a specific user (internal helper)
 * Not an endpoint — called from other controllers
 */
const sendPushToUser = async (userId, title, body) => {
  try {
    const tokens = await db.query(
      'SELECT fcm_token FROM device_tokens WHERE userid = $1',
      [userId]
    );

    if (tokens.rows.length === 0) return;

    for (const row of tokens.rows) {
      try {
        await admin.messaging().send({
          token: row.fcm_token,
          notification: { title, body },
        });
      } catch (err) {
        // Remove invalid tokens
        if (
          err.code === 'messaging/invalid-registration-token' ||
          err.code === 'messaging/registration-token-not-registered'
        ) {
          await db.query('DELETE FROM device_tokens WHERE fcm_token = $1', [row.fcm_token]);
        }
      }
    }
  } catch (err) {
    console.error('Push notification error:', err.message);
  }
};

module.exports = {
  getNotifications,
  markAsRead,
  registerToken,
  sendPushToUser
};
