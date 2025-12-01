const express = require('express');
const router = express.Router();
const lyricController = require('../controllers/lyricController');
const { authenticate } = require('../middleware/auth');
const { validateLyric } = require('../utils/validators');

// All routes are protected
router.use(authenticate);

// CRUD operations
router.post('/', validateLyric, lyricController.createLyric);
router.get('/', lyricController.getLyrics);
router.get('/stats', lyricController.getLyricsStats);
router.get('/:id', lyricController.getLyricById);
router.put('/:id', validateLyric, lyricController.updateLyric);
router.delete('/:id', lyricController.deleteLyric);

// Favorite and Pin operations
router.post('/:id/favorite', lyricController.toggleFavorite);
router.post('/:id/pin', lyricController.togglePin);

// Version history
router.get('/:id/versions', lyricController.getVersionHistory);
router.post('/:id/versions/:versionIndex/restore', lyricController.restoreVersion);

module.exports = router;