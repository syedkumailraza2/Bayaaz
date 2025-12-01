const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');
const {
  validateRegistration,
  validateLogin,
  validateProfileUpdate,
  validatePasswordChange,
  validateEmailChange
} = require('../utils/validators');

// Public routes
router.post('/register', validateRegistration, authController.register);
router.post('/login', validateLogin, authController.login);

// Protected routes
router.get('/profile', authenticate, authController.getProfile);
router.put('/profile', authenticate, validateProfileUpdate, authController.updateProfile);
router.put('/change-password', authenticate, validatePasswordChange, authController.changePassword);
router.put('/change-email', authenticate, validateEmailChange, authController.changeEmail);
router.put('/preferences', authenticate, authController.updatePreferences);
router.delete('/account', authenticate, authController.deleteAccount);
router.post('/refresh-token', authenticate, authController.refreshToken);

module.exports = router;