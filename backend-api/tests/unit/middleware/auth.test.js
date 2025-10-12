const authMiddleware = require('../../../middleware/auth');
const jwt = require('jsonwebtoken');
const prisma = require('../../../lib/database');

// Mock dependencies
jest.mock('jsonwebtoken', () => ({
  verify: jest.fn(),
}));

jest.mock('../../../lib/database', () => ({
  user: {
    findUnique: jest.fn(),
  },
}));

// Mock environment variables
const originalEnv = process.env;
beforeAll(() => {
  process.env.JWT_SECRET = 'test-jwt-secret';
});

afterAll(() => {
  process.env = originalEnv;
});

describe('Auth Middleware', () => {
  let req, res, next;

  beforeEach(() => {
    jest.clearAllMocks();
    
    // Mock request object
    req = {
      headers: {},
      params: {},
      body: {},
      user: null
    };

    // Mock response object
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis()
    };

    // Mock next function
    next = jest.fn();
  });

  describe('authenticateToken', () => {
    const mockUser = {
      user_id: 1,
      name: 'John Doe',
      email: 'john@example.com',
      phone_number: '+1234567890',
      profile_picture: 'https://example.com/pic.jpg',
      is_email_verified: true,
      role: 'USER'
    };

    const mockDecodedToken = {
      userId: 1,
      email: 'john@example.com',
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 3600
    };

    it('should authenticate valid token and set user in request', async () => {
      req.headers.authorization = 'Bearer valid-jwt-token';
      jwt.verify.mockReturnValueOnce(mockDecodedToken);
      prisma.user.findUnique.mockResolvedValueOnce(mockUser);

      await authMiddleware.authenticateToken(req, res, next);

      expect(jwt.verify).toHaveBeenCalledWith('valid-jwt-token', 'test-jwt-secret');
      expect(prisma.user.findUnique).toHaveBeenCalledWith({
        where: { user_id: 1 },
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
      expect(req.user).toEqual(mockUser);
      expect(next).toHaveBeenCalledTimes(1);
      expect(res.status).not.toHaveBeenCalled();
    });

    it('should return 401 when no authorization header provided', async () => {
      req.headers = {}; // No authorization header

      await authMiddleware.authenticateToken(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Access token required',
        code: 'NO_TOKEN'
      });
      expect(next).not.toHaveBeenCalled();
    });

    it('should return 401 when authorization header is malformed', async () => {
      req.headers.authorization = 'InvalidHeader'; // No Bearer prefix

      await authMiddleware.authenticateToken(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Access token required',
        code: 'NO_TOKEN'
      });
      expect(next).not.toHaveBeenCalled();
    });

    it('should return 401 when Bearer token is empty', async () => {
      req.headers.authorization = 'Bearer '; // Empty token

      await authMiddleware.authenticateToken(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Access token required',
        code: 'NO_TOKEN'
      });
    });

    it('should return 403 when token is invalid', async () => {
      req.headers.authorization = 'Bearer invalid-token';
      jwt.verify.mockImplementationOnce(() => {
        const error = new Error('invalid signature');
        error.name = 'JsonWebTokenError';
        throw error;
      });

      await authMiddleware.authenticateToken(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Invalid token',
        code: 'INVALID_TOKEN'
      });
      expect(next).not.toHaveBeenCalled();
    });

    it('should return 403 when token is expired', async () => {
      req.headers.authorization = 'Bearer expired-token';
      jwt.verify.mockImplementationOnce(() => {
        const error = new Error('jwt expired');
        error.name = 'TokenExpiredError';
        throw error;
      });

      await authMiddleware.authenticateToken(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Token expired',
        code: 'TOKEN_EXPIRED'
      });
      expect(next).not.toHaveBeenCalled();
    });

    it('should return 401 when user not found in database', async () => {
      req.headers.authorization = 'Bearer valid-token';
      jwt.verify.mockReturnValueOnce(mockDecodedToken);
      prisma.user.findUnique.mockResolvedValueOnce(null);

      await authMiddleware.authenticateToken(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'User not found',
        code: 'USER_NOT_FOUND'
      });
      expect(next).not.toHaveBeenCalled();
    });

    it('should return 500 when database error occurs', async () => {
      req.headers.authorization = 'Bearer valid-token';
      jwt.verify.mockReturnValueOnce(mockDecodedToken);
      prisma.user.findUnique.mockRejectedValueOnce(new Error('Database connection failed'));

      const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

      await authMiddleware.authenticateToken(req, res, next);

      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Authentication error',
        code: 'AUTH_ERROR'
      });
      expect(consoleSpy).toHaveBeenCalledWith('🚨 JWT Authentication error:', expect.any(Object));
      expect(next).not.toHaveBeenCalled();

      consoleSpy.mockRestore();
    });

    it('should handle Bearer token correctly', async () => {
      req.headers.authorization = 'Bearer valid-token-format';
      jwt.verify.mockReturnValueOnce(mockDecodedToken);
      prisma.user.findUnique.mockResolvedValueOnce(mockUser);

      await authMiddleware.authenticateToken(req, res, next);

      expect(jwt.verify).toHaveBeenCalledWith('valid-token-format', 'test-jwt-secret');
      expect(next).toHaveBeenCalledTimes(1);
    });

    it('should only allow TEST_MODE in test environment', async () => {
      const originalNodeEnv = process.env.NODE_ENV;
      const originalTestMode = process.env.TEST_MODE;
      
      // Set production environment
      process.env.NODE_ENV = 'production';
      process.env.TEST_MODE = 'true';
      
      req.headers.authorization = 'Bearer test-token';
      const testDecodedToken = {
        userId: 1,
        email: 'test@test.com',
        name: 'Test User'
      };
      
      jwt.verify.mockReturnValueOnce(testDecodedToken);
      prisma.user.findUnique.mockResolvedValueOnce(mockUser);

      await authMiddleware.authenticateToken(req, res, next);

      // Should use database lookup in production, not test mode
      expect(prisma.user.findUnique).toHaveBeenCalled();
      expect(req.user).toEqual(mockUser);
      
      // Restore environment
      process.env.NODE_ENV = originalNodeEnv;
      process.env.TEST_MODE = originalTestMode;
    });
  });

  describe('optionalAuth', () => {
    const mockUser = {
      user_id: 1,
      name: 'John Doe',
      email: 'john@example.com',
      phone_number: '+1234567890',
      profile_picture: 'https://example.com/pic.jpg',
      is_email_verified: true,
      role: 'USER'
    };

    const mockDecodedToken = {
      userId: 1,
      email: 'john@example.com'
    };

    it('should set user when valid token provided', async () => {
      req.headers.authorization = 'Bearer valid-token';
      jwt.verify.mockReturnValueOnce(mockDecodedToken);
      prisma.user.findUnique.mockResolvedValueOnce(mockUser);

      await authMiddleware.optionalAuth(req, res, next);

      expect(jwt.verify).toHaveBeenCalledWith('valid-token', 'test-jwt-secret');
      expect(prisma.user.findUnique).toHaveBeenCalledWith({
        where: { user_id: 1 },
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
      expect(req.user).toEqual(mockUser);
      expect(next).toHaveBeenCalledTimes(1);
    });

    it('should set user to null when no token provided', async () => {
      req.headers = {}; // No authorization header

      await authMiddleware.optionalAuth(req, res, next);

      expect(req.user).toBeNull();
      expect(next).toHaveBeenCalledTimes(1);
      expect(jwt.verify).not.toHaveBeenCalled();
    });

    it('should set user to null when token is invalid', async () => {
      req.headers.authorization = 'Bearer invalid-token';
      jwt.verify.mockImplementationOnce(() => {
        throw new Error('Invalid token');
      });
      prisma.user.findUnique.mockClear(); // Clear any previous mocks

      await authMiddleware.optionalAuth(req, res, next);

      expect(req.user).toBeNull();
      expect(next).toHaveBeenCalledTimes(1);
    });

    it('should set user to null when user not found in database', async () => {
      req.headers.authorization = 'Bearer valid-token';
      jwt.verify.mockReturnValueOnce(mockDecodedToken);
      prisma.user.findUnique.mockResolvedValueOnce(null);

      await authMiddleware.optionalAuth(req, res, next);

      expect(req.user).toBeNull();
      expect(next).toHaveBeenCalledTimes(1);
    });

    it('should handle database errors gracefully', async () => {
      req.headers.authorization = 'Bearer valid-token';
      jwt.verify.mockReturnValueOnce(mockDecodedToken);
      prisma.user.findUnique.mockRejectedValueOnce(new Error('DB error'));

      await authMiddleware.optionalAuth(req, res, next);

      expect(req.user).toBeNull();
      expect(next).toHaveBeenCalledTimes(1);
    });
  });

  describe('requireVerified', () => {
    it('should proceed when user is authenticated and verified', () => {
      req.user = {
        user_id: 1,
        email: 'john@example.com',
        is_email_verified: true
      };

      authMiddleware.requireVerified(req, res, next);

      expect(next).toHaveBeenCalledTimes(1);
      expect(res.status).not.toHaveBeenCalled();
    });

    it('should return 401 when user is not authenticated', () => {
      req.user = null;

      authMiddleware.requireVerified(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Authentication required',
        code: 'AUTH_REQUIRED'
      });
      expect(next).not.toHaveBeenCalled();
    });

    it('should return 403 when user is not verified', () => {
      req.user = {
        user_id: 1,
        email: 'john@example.com',
        is_email_verified: false
      };

      authMiddleware.requireVerified(req, res, next);

      expect(res.status).toHaveBeenCalledWith(403);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Email verification required',
        code: 'EMAIL_NOT_VERIFIED'
      });
      expect(next).not.toHaveBeenCalled();
    });

    it('should return 401 when user is undefined', () => {
      req.user = undefined;

      authMiddleware.requireVerified(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Authentication required',
        code: 'AUTH_REQUIRED'
      });
    });
  });

  describe('requireOwnership', () => {
    it('should proceed when user owns the resource (default userIdField)', () => {
      req.user = { user_id: 1 };
      req.params.user_id = '1'; // String from URL parameter

      const middleware = authMiddleware.requireOwnership();
      middleware(req, res, next);

      expect(next).toHaveBeenCalledTimes(1);
      expect(res.status).not.toHaveBeenCalled();
    });

    it('should proceed when user owns the resource (custom userIdField)', () => {
      req.user = { user_id: 1 };
      req.params.ownerId = '1';

      const middleware = authMiddleware.requireOwnership('ownerId');
      middleware(req, res, next);

      expect(next).toHaveBeenCalledTimes(1);
    });

    it('should proceed when resource userId is in request body', () => {
      req.user = { user_id: 1 };
      req.body.user_id = '1';

      const middleware = authMiddleware.requireOwnership();
      middleware(req, res, next);

      expect(next).toHaveBeenCalledTimes(1);
    });

    it('should return 401 when user is not authenticated', () => {
      req.user = null;
      req.params.user_id = '1';

      const middleware = authMiddleware.requireOwnership();
      middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Authentication required',
        code: 'AUTH_REQUIRED'
      });
      expect(next).not.toHaveBeenCalled();
    });

    it('should return 403 when user does not own the resource', () => {
      req.user = { user_id: 1 };
      req.params.user_id = '2'; // Different user ID

      const middleware = authMiddleware.requireOwnership();
      middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(403);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Access denied',
        code: 'ACCESS_DENIED'
      });
      expect(next).not.toHaveBeenCalled();
    });

    it('should handle string vs number comparison correctly', () => {
      req.user = { user_id: 1 };
      req.params.user_id = '1'; // String version

      const middleware = authMiddleware.requireOwnership();
      middleware(req, res, next);

      // Should now pass with proper type conversion
      expect(next).toHaveBeenCalledTimes(1);
      expect(res.status).not.toHaveBeenCalled();
    });

    it('should return 403 when resource userId is missing', () => {
      req.user = { user_id: 1 };
      req.params = {}; // No user_id
      req.body = {}; // No user_id

      const middleware = authMiddleware.requireOwnership();
      middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(403);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Access denied',
        code: 'ACCESS_DENIED'
      });
    });

    it('should return 403 when resource userId is invalid', () => {
      req.user = { user_id: 1 };
      req.params.user_id = 'invalid'; // Non-numeric value

      const middleware = authMiddleware.requireOwnership();
      middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(403);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: 'Access denied',
        code: 'ACCESS_DENIED'
      });
    });
  });
});