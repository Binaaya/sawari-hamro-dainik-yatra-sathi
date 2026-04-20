const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const { authenticate } = require('../middleware/auth');
const { operatorUpload } = require('../middleware/upload');

// POST /api/auth/register - Register new user (creates Firebase user + DB record)
router.post('/register', operatorUpload.single('businessDocument'), authController.register);

// POST /api/auth/login - Verify Firebase token and return user data
router.post('/login', authController.login);

// GET /api/auth/me - Get current user profile
router.get('/me', authenticate, authController.getCurrentUser);

// PUT /api/auth/profile - Update user profile
router.put('/profile', authenticate, authController.updateProfile);

// POST /api/auth/verify-token - Verify if token is valid
router.post('/verify-token', authController.verifyToken);

module.exports = router;
