const express = require('express');
const router = express.Router();
const uploadController = require('../controllers/uploadController');
const { authenticate } = require('../middleware/auth');

// All routes are protected
router.use(authenticate);

// Upload routes
router.post('/images', uploadController.uploadImage.array('images', 5), uploadController.uploadImages);
router.post('/audio', uploadController.uploadAudio.single('audio'), uploadController.uploadAudioFile);
router.post('/document', uploadController.uploadDocument.single('document'), uploadController.uploadDocumentFile);

// File management routes
router.delete('/file', uploadController.deleteFile);
router.get('/file/:publicId', uploadController.getFileInfo);
router.get('/signature', uploadController.generateUploadSignature);

module.exports = router;