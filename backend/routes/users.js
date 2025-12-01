const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticate } = require('../middleware/auth');

// All routes are protected
router.use(authenticate);

router.get('/dashboard', userController.getDashboard);
router.get('/search', userController.searchContent);
router.get('/export', userController.exportData);
router.post('/import', userController.importData);
router.get('/settings', userController.getSettings);
router.put('/settings', userController.updateSettings);
router.post('/sync', userController.syncData);

module.exports = router;