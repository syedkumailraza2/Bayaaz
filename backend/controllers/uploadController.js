const cloudinary = require('cloudinary').v2;
const multer = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary');

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

// Configure storage for different file types
const createStorage = (folder) => {
  return new CloudinaryStorage({
    cloudinary: cloudinary,
    params: {
      folder: `bayaaz/${folder}`,
      resource_type: 'auto',
      allowed_formats: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'mp3', 'wav', 'ogg', 'pdf'],
      transformation: folder === 'images' ? [
        { width: 1200, height: 1200, crop: 'limit', quality: 'auto' }
      ] : []
    }
  });
};

// Create upload middleware for different file types
const uploadImage = multer({
  storage: createStorage('images'),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB
    files: 5 // Max 5 files at once
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only JPEG, PNG, GIF, and WebP images are allowed.'), false);
    }
  }
});

const uploadAudio = multer({
  storage: createStorage('audio'),
  limits: {
    fileSize: 50 * 1024 * 1024, // 50MB
    files: 1 // Max 1 audio file at once
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/mp3'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only MP3, WAV, and OGG audio files are allowed.'), false);
    }
  }
});

const uploadDocument = multer({
  storage: createStorage('documents'),
  limits: {
    fileSize: 20 * 1024 * 1024, // 20MB
    files: 1 // Max 1 document at once
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['application/pdf', 'text/plain', 'application/msword'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only PDF, TXT, and DOC files are allowed.'), false);
    }
  }
});

// Upload images
const uploadImages = async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        message: 'No images uploaded'
      });
    }

    const uploadedImages = req.files.map(file => ({
      type: 'image',
      url: file.path,
      publicId: file.filename,
      fileName: file.originalname,
      fileSize: file.size,
      mimeType: file.mimetype,
      uploadedAt: new Date()
    }));

    res.status(201).json({
      message: 'Images uploaded successfully',
      files: uploadedImages
    });
  } catch (error) {
    console.error('Upload images error:', error);
    res.status(500).json({
      message: 'Server error while uploading images',
      error: error.message
    });
  }
};

// Upload audio
const uploadAudioFile = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        message: 'No audio file uploaded'
      });
    }

    const uploadedAudio = {
      type: 'audio',
      url: req.file.path,
      publicId: req.file.filename,
      fileName: req.file.originalname,
      fileSize: req.file.size,
      mimeType: req.file.mimetype,
      uploadedAt: new Date()
    };

    res.status(201).json({
      message: 'Audio file uploaded successfully',
      file: uploadedAudio
    });
  } catch (error) {
    console.error('Upload audio error:', error);
    res.status(500).json({
      message: 'Server error while uploading audio file',
      error: error.message
    });
  }
};

// Upload document
const uploadDocumentFile = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        message: 'No document uploaded'
      });
    }

    const uploadedDocument = {
      type: 'document',
      url: req.file.path,
      publicId: req.file.filename,
      fileName: req.file.originalname,
      fileSize: req.file.size,
      mimeType: req.file.mimetype,
      uploadedAt: new Date()
    };

    res.status(201).json({
      message: 'Document uploaded successfully',
      file: uploadedDocument
    });
  } catch (error) {
    console.error('Upload document error:', error);
    res.status(500).json({
      message: 'Server error while uploading document',
      error: error.message
    });
  }
};

// Delete file from Cloudinary
const deleteFile = async (req, res) => {
  try {
    const { publicId, type } = req.body;

    if (!publicId) {
      return res.status(400).json({
        message: 'Public ID is required'
      });
    }

    // Determine resource type based on file type
    let resourceType = 'image';
    if (type === 'audio') resourceType = 'video';
    if (type === 'document') resourceType = 'raw';

    const result = await cloudinary.uploader.destroy(publicId, {
      resource_type: resourceType,
      invalidate: true
    });

    if (result.result === 'ok' || result.result === 'not found') {
      res.json({
        message: 'File deleted successfully'
      });
    } else {
      res.status(500).json({
        message: 'Failed to delete file',
        result
      });
    }
  } catch (error) {
    console.error('Delete file error:', error);
    res.status(500).json({
      message: 'Server error while deleting file',
      error: error.message
    });
  }
};

// Get file info
const getFileInfo = async (req, res) => {
  try {
    const { publicId } = req.params;

    if (!publicId) {
      return res.status(400).json({
        message: 'Public ID is required'
      });
    }

    const result = await cloudinary.api.resource(publicId, {
      resource_type: 'auto'
    });

    res.json({
      file: {
        publicId: result.public_id,
        url: result.secure_url,
        format: result.format,
        size: result.bytes,
        createdAt: result.created_at,
        resourceType: result.resource_type,
        metadata: result
      }
    });
  } catch (error) {
    console.error('Get file info error:', error);
    if (error.http_code === 404) {
      return res.status(404).json({
        message: 'File not found'
      });
    }
    res.status(500).json({
      message: 'Server error while fetching file info',
      error: error.message
    });
  }
};

// Generate upload signature for direct client uploads
const generateUploadSignature = async (req, res) => {
  try {
    const { folder, type } = req.query;

    const timestamp = Math.round(new Date().getTime() / 1000);
    const params = {
      timestamp,
      folder: `bayaaz/${folder || 'general'}`,
      use_filename: true,
      unique_filename: true
    };

    const signature = cloudinary.utils.api_sign_request(
      params,
      process.env.CLOUDINARY_API_SECRET
    );

    res.json({
      signature,
      timestamp,
      cloudName: process.env.CLOUDINARY_CLOUD_NAME,
      apiKey: process.env.CLOUDINARY_API_KEY,
      folder: params.folder
    });
  } catch (error) {
    console.error('Generate signature error:', error);
    res.status(500).json({
      message: 'Server error while generating upload signature',
      error: error.message
    });
  }
};

// Upload middleware exports
module.exports = {
  // Controller functions
  uploadImages,
  uploadAudioFile,
  uploadDocumentFile,
  deleteFile,
  getFileInfo,
  generateUploadSignature,

  // Middleware functions
  uploadImage,
  uploadAudio,
  uploadDocument
};