const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Middleware to authenticate user using JWT
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.header('Authorization');

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        message: 'Access denied. No token provided or invalid format.'
      });
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix

    if (!token) {
      return res.status(401).json({
        message: 'Access denied. Token missing.'
      });
    }

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(decoded.userId).select('-password');

      if (!user) {
        return res.status(401).json({
          message: 'Invalid token. User not found.'
        });
      }

      req.user = user;
      next();
    } catch (jwtError) {
      if (jwtError.name === 'TokenExpiredError') {
        return res.status(401).json({
          message: 'Token expired. Please login again.'
        });
      }

      if (jwtError.name === 'JsonWebTokenError') {
        return res.status(401).json({
          message: 'Invalid token.'
        });
      }

      throw jwtError;
    }
  } catch (error) {
    console.error('Authentication error:', error);
    res.status(500).json({
      message: 'Server error during authentication.'
    });
  }
};

// Middleware to check if user has premium subscription
const requirePremium = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({
      message: 'Authentication required.'
    });
  }

  if (req.user.subscription.type !== 'premium') {
    return res.status(403).json({
      message: 'Premium subscription required for this feature.'
    });
  }

  next();
};

// Middleware to check resource ownership
const checkOwnership = (resourceModel) => {
  return async (req, res, next) => {
    try {
      const resourceId = req.params.id || req.params.lyricId;
      const resource = await resourceModel.findById(resourceId);

      if (!resource) {
        return res.status(404).json({
          message: 'Resource not found.'
        });
      }

      if (resource.userId.toString() !== req.user._id.toString()) {
        return res.status(403).json({
          message: 'Access denied. You do not own this resource.'
        });
      }

      req.resource = resource;
      next();
    } catch (error) {
      console.error('Ownership check error:', error);
      res.status(500).json({
        message: 'Server error while checking ownership.'
      });
    }
  };
};

// Optional authentication - doesn't fail if no token
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.header('Authorization');

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next();
    }

    const token = authHeader.substring(7);

    if (!token) {
      return next();
    }

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(decoded.userId).select('-password');

      if (user) {
        req.user = user;
      }
    } catch (jwtError) {
      // Ignore token errors for optional auth
    }

    next();
  } catch (error) {
    console.error('Optional authentication error:', error);
    next();
  }
};

module.exports = {
  authenticate,
  requirePremium,
  checkOwnership,
  optionalAuth
};