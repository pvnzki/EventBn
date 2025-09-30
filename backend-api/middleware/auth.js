// Authentication middleware
const jwt = require('jsonwebtoken');
const prisma = require('../lib/database');

// Verify JWT token
const authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.status(401).json({ 
        success: false,
        message: 'Access token required',
        code: 'NO_TOKEN'
      });
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Get user from database
    const user = await prisma.user.findUnique({
      where: { user_id: decoded.userId },
      select: {
        user_id: true,
        name: true,
        email: true,
        phone_number: true,
        profile_picture: true,
        is_email_verified: true,
        role: true,
      }
    });

    if (!user) {
      return res.status(401).json({ 
        success: false,
        message: 'User not found',
        code: 'USER_NOT_FOUND'
      });
    }

    // Add user to request object
    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ 
        success: false,
        message: 'Invalid token',
        code: 'INVALID_TOKEN'
      });
    } else if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ 
        success: false,
        message: 'Token expired',
        code: 'TOKEN_EXPIRED'
      });
    }
    
    return res.status(500).json({ 
      success: false,
      message: 'Authentication error',
      code: 'AUTH_ERROR'
    });
  }
};

// Optional authentication (won't fail if no token)
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      req.user = null;
      return next();
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await prisma.user.findUnique({
      where: { user_id: decoded.userId },
      select: {
        user_id: true,
        name: true,
        email: true,
        phone_number: true,
        profile_picture: true,
        is_email_verified: true,
        role: true,
      }
    });

    req.user = user;
    next();
  } catch (error) {
    // Don't fail on optional auth
    req.user = null;
    next();
  }
};

// Check if user is verified
const requireVerified = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ 
      success: false,
      message: 'Authentication required',
      code: 'AUTH_REQUIRED'
    });
  }

  if (!req.user.is_email_verified) {
    return res.status(403).json({ 
      success: false,
      message: 'Email verification required',
      code: 'EMAIL_NOT_VERIFIED'
    });
  }

  next();
};

// Check if user has organizer role
const requireOrganizer = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ 
      success: false,
      message: 'Authentication required',
      code: 'AUTH_REQUIRED'
    });
  }

  if (req.user.role !== 'ORGANIZER') {
    return res.status(403).json({ 
      success: false,
      message: 'Organizer access required',
      code: 'ORGANIZER_REQUIRED'
    });
  }

  next();
};

// Check if user owns resource
const requireOwnership = (userIdField = 'user_id') => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ 
        success: false,
        message: 'Authentication required',
        code: 'AUTH_REQUIRED'
      });
    }

    const resourceUserId = req.params[userIdField] || req.body[userIdField];
    
    if (req.user.user_id !== parseInt(resourceUserId)) {
      return res.status(403).json({ 
        success: false,
        message: 'Access denied',
        code: 'ACCESS_DENIED'
      });
    }

    next();
  };
};

module.exports = {
  authenticateToken,
  optionalAuth,
  requireVerified,
  requireOrganizer,
  requireOwnership,
};
