const express = require('express');
const router = express.Router();
const notificationsController = require('../controllers/notifications.controller');
const { authenticate } = require('../middleware/auth');

// All routes require authentication
router.use(authenticate);

// GET /api/notifications - Get user's notifications
router.get('/', notificationsController.getNotifications);

// PUT /api/notifications/:id/read - Mark notification as read
router.put('/:id/read', notificationsController.markAsRead);

// POST /api/notifications/register-token - Register FCM token
router.post('/register-token', notificationsController.registerToken);

module.exports = router;
