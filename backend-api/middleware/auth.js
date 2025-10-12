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
    
    console.log('🔍 JWT decoded payload:', {
      userId: decoded.userId,
      email: decoded.email,
      name: decoded.name,
      iat: decoded.iat,
      exp: decoded.exp
    });
    
    // Check if this is a test environment (only with @test.com emails or explicit TEST_MODE_MOCK)
    const isTestMode = process.env.NODE_ENV === 'test' && 
                      (process.env.TEST_MODE_MOCK === 'true' || decoded.email?.includes('@test.com'));
    
    if (isTestMode) {
      // For testing: create mock user object from JWT payload without database lookup
      // SECURITY: Only allow in actual test environment
      console.log('🧪 Test mode: Using mock user from JWT payload');
      req.user = {
        user_id: decoded.userId,
        name: decoded.name || `Test User ${decoded.userId}`,
        email: decoded.email,
        phone_number: null,
        profile_picture: null,
        is_email_verified: true,
        role: 'GUEST'
      };
      
      console.log('✅ Mock user created for testing:', {
        user_id: req.user.user_id,
        name: req.user.name,
        email: req.user.email
      });
      
      next();
      return;
    }
    
    // Production mode: Get user from database
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
      console.error('🚨 User not found in database:', {
        requestedUserId: decoded.userId,
        decodedPayload: decoded
      });
      return res.status(401).json({ 
        success: false,
        message: 'User not found',
        code: 'USER_NOT_FOUND'
      });
    }

    console.log('✅ User authenticated successfully:', {
      user_id: user.user_id,
      name: user.name,
      email: user.email
    });

    // Add user to request object
    req.user = user;
    next();
  } catch (error) {
    console.error('🚨 JWT Authentication error:', {
      errorName: error.name,
      errorMessage: error.message,
      stack: error.stack
    });
    
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
    
    // Convert both to numbers for proper comparison (URL params are strings)
    const userIdNum = parseInt(req.user.user_id);
    const resourceUserIdNum = parseInt(resourceUserId);
    
    if (isNaN(resourceUserIdNum) || userIdNum !== resourceUserIdNum) {
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
