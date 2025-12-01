const express = require('express');
const router = express.Router();
const categoryController = require('../controllers/categoryController');
const { authenticate } = require('../middleware/auth');
const { validateCategory } = require('../utils/validators');

// All routes are protected
router.use(authenticate);

// CRUD operations
router.get('/', categoryController.getCategories);
router.get('/stats', categoryController.getCategoryStats);
router.get('/:id', categoryController.getCategoryById);
router.post('/', validateCategory, categoryController.createCategory);
router.put('/:id', validateCategory, categoryController.updateCategory);
router.delete('/:id', categoryController.deleteCategory);

// Additional operations
router.post('/:id/archive', categoryController.toggleArchive);
router.post('/reorder', categoryController.reorderCategories);

module.exports = router;