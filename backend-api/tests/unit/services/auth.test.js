const authService = require('../../../services/core-service/auth/index');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const prisma = require('../../../lib/database');

// Mock dependencies
jest.mock('../../../lib/database', () => ({
  user: {
    findUnique: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
  },
  organization: {
    findFirst: jest.fn(),
  },
  passwordReset: {
    create: jest.fn(),
    findFirst: jest.fn(),
    update: jest.fn(),
  },
  emailVerification: {
    create: jest.fn(),
    findFirst: jest.fn(),
    update: jest.fn(),
  },
  $transaction: jest.fn(),
}));

jest.mock('bcrypt', () => ({
  hash: jest.fn(),
  compare: jest.fn(),
}));

jest.mock('jsonwebtoken', () => ({
  sign: jest.fn(),
  verify: jest.fn(),
}));

// Mock environment variables
const originalEnv = process.env;
beforeAll(() => {
  process.env.JWT_SECRET = 'test-jwt-secret';
});

afterAll(() => {
  process.env = originalEnv;
});

describe('Auth Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('generateToken', () => {
    it('should generate JWT token with correct payload and options', () => {
      const mockToken = 'mocked-jwt-token';
      const payload = { userId: 1, email: 'test@example.com', name: 'Test User' };
      
      jwt.sign.mockReturnValueOnce(mockToken);

      const result = authService.generateToken(payload);

      expect(jwt.sign).toHaveBeenCalledWith(
        payload,
        'test-jwt-secret',
        { expiresIn: '7d' }
      );
      expect(result).toBe(mockToken);
    });
  });

  describe('verifyToken', () => {
    it('should verify and return decoded token for valid token', () => {
      const mockToken = 'valid-token';
      const mockDecoded = { userId: 1, email: 'test@example.com' };
      
      jwt.verify.mockReturnValueOnce(mockDecoded);

      const result = authService.verifyToken(mockToken);

      expect(jwt.verify).toHaveBeenCalledWith(mockToken, 'test-jwt-secret');
      expect(result).toEqual(mockDecoded);
    });

    it('should throw error for invalid token', () => {
      const mockToken = 'invalid-token';
      
      jwt.verify.mockImplementationOnce(() => {
        throw new Error('jwt malformed');
      });

      expect(() => authService.verifyToken(mockToken))
        .toThrow('Invalid token');
    });
  });

  describe('register', () => {
    const userData = {
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
      phone_number: '+1234567890',
      profile_picture: 'https://example.com/pic.jpg'
    };

    const mockUser = {
      user_id: 1,
      name: 'Test User',
      email: 'test@example.com',
      phone_number: '+1234567890',
      profile_picture: 'https://example.com/pic.jpg',
      is_active: true,
      is_email_verified: false,
      role: 'GUEST',
      created_at: new Date(),
      updated_at: new Date()
    };

    it('should register new user successfully', async () => {
      const mockToken = 'generated-token';
      const hashedPassword = 'hashed-password';

      prisma.user.findUnique.mockResolvedValueOnce(null); // User doesn't exist
      bcrypt.hash.mockResolvedValueOnce(hashedPassword);
      prisma.user.create.mockResolvedValueOnce(mockUser);
      jwt.sign.mockReturnValueOnce(mockToken);

      const result = await authService.register(userData);

      expect(prisma.user.findUnique).toHaveBeenCalledWith({
        where: { email: 'test@example.com' }
      });
      expect(bcrypt.hash).toHaveBeenCalledWith('password123', 12);
      expect(prisma.user.create).toHaveBeenCalledWith({
        data: {
          name: 'Test User',
          email: 'test@example.com',
          password_hash: hashedPassword,
          phone_number: '+1234567890',
          profile_picture: 'https://example.com/pic.jpg',
          role: 'ATTENDEE',
          is_active: true,
          is_email_verified: false
        },
        select: {
          user_id: true,
          name: true,
          email: true,
          phone_number: true,
          profile_picture: true,
          is_active: true,
          is_email_verified: true,
          role: true,
          created_at: true,
          updated_at: true
        }
      });
      expect(jwt.sign).toHaveBeenCalledWith({
        userId: 1,
        email: 'test@example.com',
        name: 'Test User'
      }, 'test-jwt-secret', { expiresIn: '7d' });
      expect(result).toEqual({
        user: mockUser,
        token: mockToken
      });
    });

    it('should register user with minimal data (no phone and profile picture)', async () => {
      const minimalUserData = {
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123'
      };

      prisma.user.findUnique.mockResolvedValueOnce(null);
      bcrypt.hash.mockResolvedValueOnce('hashed-password');
      prisma.user.create.mockResolvedValueOnce(mockUser);
      jwt.sign.mockReturnValueOnce('token');

      await authService.register(minimalUserData);

      expect(prisma.user.create).toHaveBeenCalledWith({
        data: {
          name: 'Test User',
          email: 'test@example.com',
          password_hash: 'hashed-password',
          phone_number: null,
          profile_picture: null,
          role: 'ATTENDEE',
          is_active: true,
          is_email_verified: false
        },
        select: expect.any(Object)
      });
    });

    it('should throw error if email already exists', async () => {
      prisma.user.findUnique.mockResolvedValueOnce({ email: 'test@example.com' });

      await expect(authService.register(userData))
        .rejects
        .toThrow('Email already registered');
    });

    it('should throw error if database fails during user creation', async () => {
      prisma.user.findUnique.mockResolvedValueOnce(null);
      bcrypt.hash.mockResolvedValueOnce('hashed-password');
      prisma.user.create.mockRejectedValueOnce(new Error('DB error'));

      await expect(authService.register(userData))
        .rejects
        .toThrow('Registration failed: DB error');
    });

    it('should throw error if password hashing fails', async () => {
      prisma.user.findUnique.mockResolvedValueOnce(null);
      bcrypt.hash.mockRejectedValueOnce(new Error('Hashing failed'));

      await expect(authService.register(userData))
        .rejects
        .toThrow('Registration failed: Hashing failed');
    });
  });

  describe('login', () => {
    const credentials = {
      email: 'test@example.com',
      password: 'password123'
    };

    const mockUser = {
      user_id: 1,
      name: 'Test User',
      email: 'test@example.com',
      password_hash: 'hashed-password',
      phone_number: '+1234567890',
      profile_picture: 'https://example.com/pic.jpg',
      is_active: true,
      is_email_verified: true,
      role: 'USER',
      created_at: new Date(),
      updated_at: new Date()
    };

    it('should login user successfully', async () => {
      const mockToken = 'login-token';

      prisma.user.findUnique.mockResolvedValueOnce(mockUser);
      bcrypt.compare.mockResolvedValueOnce(true);
      prisma.user.update.mockResolvedValueOnce(mockUser);
      jwt.sign.mockReturnValueOnce(mockToken);

      const result = await authService.login(credentials);

      expect(prisma.user.findUnique).toHaveBeenCalledWith({
        where: { email: 'test@example.com' }
      });
      expect(bcrypt.compare).toHaveBeenCalledWith('password123', 'hashed-password');
      expect(prisma.user.update).toHaveBeenCalledWith({
        where: { user_id: 1 },
        data: { updated_at: expect.any(Date) }
      });
      expect(result).toEqual({
        user: {
          user_id: 1,
          name: 'Test User',
          email: 'test@example.com',
          phone_number: '+1234567890',
          profile_picture: 'https://example.com/pic.jpg',
          is_active: true,
          is_email_verified: true,
          role: 'USER',
          created_at: mockUser.created_at,
          updated_at: mockUser.updated_at
        },
        token: mockToken
      });
    });

    it('should login organizer and include organization_id', async () => {
      const organizerUser = { ...mockUser, role: 'ORGANIZER' };
      const mockOrganization = { organization_id: 5 };

      prisma.user.findUnique.mockResolvedValueOnce(organizerUser);
      bcrypt.compare.mockResolvedValueOnce(true);
      prisma.user.update.mockResolvedValueOnce(organizerUser);
      prisma.organization.findFirst.mockResolvedValueOnce(mockOrganization);
      jwt.sign.mockReturnValueOnce('token');

      const result = await authService.login(credentials);

      expect(prisma.organization.findFirst).toHaveBeenCalledWith({
        where: { user_id: 1 },
        select: { organization_id: true }
      });
      expect(result.user).toEqual(expect.objectContaining({
        organization_id: 5
      }));
    });

    it('should login organizer without organization_id if no organization found', async () => {
      const organizerUser = { ...mockUser, role: 'ORGANIZER' };

      prisma.user.findUnique.mockResolvedValueOnce(organizerUser);
      bcrypt.compare.mockResolvedValueOnce(true);
      prisma.user.update.mockResolvedValueOnce(organizerUser);
      prisma.organization.findFirst.mockResolvedValueOnce(null);
      jwt.sign.mockReturnValueOnce('token');

      const result = await authService.login(credentials);

      expect(result.user).not.toHaveProperty('organization_id');
    });

    it('should throw error if user not found', async () => {
      prisma.user.findUnique.mockResolvedValueOnce(null);

      await expect(authService.login(credentials))
        .rejects
        .toThrow('Login failed: Invalid email or password');
    });

    it('should throw error if user has no password set', async () => {
      const userWithoutPassword = { ...mockUser, password_hash: null };
      prisma.user.findUnique.mockResolvedValueOnce(userWithoutPassword);

      await expect(authService.login(credentials))
        .rejects
        .toThrow('Login failed: Account setup incomplete');
    });

    it('should throw error if password is invalid', async () => {
      prisma.user.findUnique.mockResolvedValueOnce(mockUser);
      bcrypt.compare.mockResolvedValueOnce(false);

      await expect(authService.login(credentials))
        .rejects
        .toThrow('Login failed: Invalid email or password');
    });

    it('should throw error if database fails', async () => {
      prisma.user.findUnique.mockRejectedValueOnce(new Error('DB error'));

      await expect(authService.login(credentials))
        .rejects
        .toThrow('Login failed: DB error');
    });
  });

  describe('logout', () => {
    it('should logout successfully with valid token', async () => {
      const mockToken = 'valid-token';
      const mockDecoded = { userId: 1 };
      
      jwt.verify.mockReturnValueOnce(mockDecoded);

      const result = await authService.logout(mockToken);

      expect(jwt.verify).toHaveBeenCalledWith(mockToken, 'test-jwt-secret');
      expect(result).toEqual({ message: 'Logged out successfully' });
    });

    it('should throw error for invalid token', async () => {
      const mockToken = 'invalid-token';
      
      jwt.verify.mockImplementationOnce(() => {
        throw new Error('Invalid token');
      });

      await expect(authService.logout(mockToken))
        .rejects
        .toThrow('Logout failed: Invalid token');
    });
  });

  describe('changePassword', () => {
    const userId = 1;
    const passwordData = {
      currentPassword: 'oldPassword123',
      newPassword: 'newPassword123'
    };

    const mockUser = {
      id: 1,
      password: 'hashed-old-password'
    };

    it('should change password successfully', async () => {
      const hashedNewPassword = 'hashed-new-password';

      prisma.user.findUnique.mockResolvedValueOnce(mockUser);
      bcrypt.compare.mockResolvedValueOnce(true);
      bcrypt.hash.mockResolvedValueOnce(hashedNewPassword);
      prisma.user.update.mockResolvedValueOnce({});

      const result = await authService.changePassword(userId, passwordData);

      expect(prisma.user.findUnique).toHaveBeenCalledWith({
        where: { id: 1 }
      });
      expect(bcrypt.compare).toHaveBeenCalledWith('oldPassword123', 'hashed-old-password');
      expect(bcrypt.hash).toHaveBeenCalledWith('newPassword123', 12);
      expect(prisma.user.update).toHaveBeenCalledWith({
        where: { id: 1 },
        data: {
          password: hashedNewPassword,
          updatedAt: expect.any(Date)
        }
      });
      expect(result).toEqual({ message: 'Password changed successfully' });
    });

    it('should throw error if user not found', async () => {
      prisma.user.findUnique.mockResolvedValueOnce(null);

      await expect(authService.changePassword(userId, passwordData))
        .rejects
        .toThrow('Password change failed: User not found');
    });

    it('should throw error if current password is incorrect', async () => {
      prisma.user.findUnique.mockResolvedValueOnce(mockUser);
      bcrypt.compare.mockResolvedValueOnce(false);

      await expect(authService.changePassword(userId, passwordData))
        .rejects
        .toThrow('Password change failed: Current password is incorrect');
    });

    it('should throw error if database fails', async () => {
      prisma.user.findUnique.mockRejectedValueOnce(new Error('DB error'));

      await expect(authService.changePassword(userId, passwordData))
        .rejects
        .toThrow('Password change failed: DB error');
    });
  });

  describe('forgotPassword', () => {
    const email = 'test@example.com';
    const mockUser = { id: 1, email };

    it('should create password reset token for existing user', async () => {
      const mockResetToken = 'reset-token';

      prisma.user.findUnique.mockResolvedValueOnce(mockUser);
      jwt.sign.mockReturnValueOnce(mockResetToken);
      prisma.passwordReset.create.mockResolvedValueOnce({});

      const result = await authService.forgotPassword(email);

      expect(prisma.user.findUnique).toHaveBeenCalledWith({
        where: { email }
      });
      expect(jwt.sign).toHaveBeenCalledWith(
        { userId: 1, type: 'password_reset' },
        'test-jwt-secret',
        { expiresIn: '1h' }
      );
      expect(prisma.passwordReset.create).toHaveBeenCalledWith({
        data: {
          userId: 1,
          token: mockResetToken,
          expiresAt: expect.any(Date)
        }
      });
      expect(result).toEqual({
        message: 'If the email exists, a reset link has been sent',
        resetToken: mockResetToken
      });
    });

    it('should return generic message for non-existent user', async () => {
      prisma.user.findUnique.mockResolvedValueOnce(null);

      const result = await authService.forgotPassword(email);

      expect(result).toEqual({
        message: 'If the email exists, a reset link has been sent'
      });
      expect(jwt.sign).not.toHaveBeenCalled();
      expect(prisma.passwordReset.create).not.toHaveBeenCalled();
    });

    it('should throw error if database fails', async () => {
      prisma.user.findUnique.mockRejectedValueOnce(new Error('DB error'));

      await expect(authService.forgotPassword(email))
        .rejects
        .toThrow('Password reset failed: DB error');
    });
  });

  describe('resetPassword', () => {
    const resetData = {
      token: 'reset-token',
      newPassword: 'newPassword123'
    };

    const mockDecoded = { userId: 1, type: 'password_reset' };
    const mockResetRecord = {
      id: 1,
      token: 'reset-token',
      userId: 1,
      used: false,
      expiresAt: new Date(Date.now() + 3600000)
    };

    it('should reset password successfully', async () => {
      const hashedPassword = 'hashed-new-password';

      jwt.verify.mockReturnValueOnce(mockDecoded);
      prisma.passwordReset.findFirst.mockResolvedValueOnce(mockResetRecord);
      bcrypt.hash.mockResolvedValueOnce(hashedPassword);
      
      // Mock the transaction operations
      const updateUser = prisma.user.update({
        where: { id: 1 },
        data: {
          password: hashedPassword,
          updatedAt: expect.any(Date)
        }
      });
      const updateResetRecord = prisma.passwordReset.update({
        where: { id: 1 },
        data: { used: true }
      });
      
      prisma.$transaction.mockResolvedValueOnce([{}, {}]);

      const result = await authService.resetPassword(resetData);

      expect(jwt.verify).toHaveBeenCalledWith('reset-token', 'test-jwt-secret');
      expect(prisma.passwordReset.findFirst).toHaveBeenCalledWith({
        where: {
          token: 'reset-token',
          userId: 1,
          used: false,
          expiresAt: { gt: expect.any(Date) }
        }
      });
      expect(bcrypt.hash).toHaveBeenCalledWith('newPassword123', 12);
      expect(prisma.$transaction).toHaveBeenCalledWith(expect.any(Array));
      expect(result).toEqual({ message: 'Password reset successfully' });
    });

    it('should throw error for invalid token type', async () => {
      const invalidDecoded = { userId: 1, type: 'invalid_type' };
      jwt.verify.mockReturnValueOnce(invalidDecoded);

      await expect(authService.resetPassword(resetData))
        .rejects
        .toThrow('Password reset failed: Invalid reset token');
    });

    it('should throw error for expired or used token', async () => {
      jwt.verify.mockReturnValueOnce(mockDecoded);
      prisma.passwordReset.findFirst.mockResolvedValueOnce(null);

      await expect(authService.resetPassword(resetData))
        .rejects
        .toThrow('Password reset failed: Invalid or expired reset token');
    });

    it('should throw error if JWT verification fails', async () => {
      jwt.verify.mockImplementationOnce(() => {
        throw new Error('JWT malformed');
      });

      await expect(authService.resetPassword(resetData))
        .rejects
        .toThrow('Password reset failed: JWT malformed');
    });

    it('should throw error if database transaction fails', async () => {
      jwt.verify.mockReturnValueOnce(mockDecoded);
      prisma.passwordReset.findFirst.mockResolvedValueOnce(mockResetRecord);
      bcrypt.hash.mockResolvedValueOnce('hashed-password');
      prisma.$transaction.mockRejectedValueOnce(new Error('Transaction failed'));

      await expect(authService.resetPassword(resetData))
        .rejects
        .toThrow('Password reset failed: Transaction failed');
    });
  });

  describe('sendEmailVerification', () => {
    const userId = 1;
    const mockUser = {
      id: 1,
      email: 'test@example.com',
      isVerified: false
    };

    it('should send email verification for unverified user', async () => {
      const mockVerificationToken = 'verification-token';

      prisma.user.findUnique.mockResolvedValueOnce(mockUser);
      jwt.sign.mockReturnValueOnce(mockVerificationToken);
      prisma.emailVerification.create.mockResolvedValueOnce({});

      const result = await authService.sendEmailVerification(userId);

      expect(prisma.user.findUnique).toHaveBeenCalledWith({
        where: { id: 1 }
      });
      expect(jwt.sign).toHaveBeenCalledWith(
        { userId: 1, type: 'email_verification' },
        'test-jwt-secret',
        { expiresIn: '24h' }
      );
      expect(prisma.emailVerification.create).toHaveBeenCalledWith({
        data: {
          userId: 1,
          token: mockVerificationToken,
          expiresAt: expect.any(Date)
        }
      });
      expect(result).toEqual({
        message: 'Verification email sent',
        verificationToken: mockVerificationToken
      });
    });

    it('should throw error if user not found', async () => {
      prisma.user.findUnique.mockResolvedValueOnce(null);

      await expect(authService.sendEmailVerification(userId))
        .rejects
        .toThrow('Email verification failed: User not found');
    });

    it('should throw error if email already verified', async () => {
      const verifiedUser = { ...mockUser, isVerified: true };
      prisma.user.findUnique.mockResolvedValueOnce(verifiedUser);

      await expect(authService.sendEmailVerification(userId))
        .rejects
        .toThrow('Email verification failed: Email already verified');
    });

    it('should throw error if database fails', async () => {
      prisma.user.findUnique.mockRejectedValueOnce(new Error('DB error'));

      await expect(authService.sendEmailVerification(userId))
        .rejects
        .toThrow('Email verification failed: DB error');
    });
  });

  describe('verifyEmail', () => {
    const verificationToken = 'verification-token';
    const mockDecoded = { userId: 1, type: 'email_verification' };
    const mockVerificationRecord = {
      id: 1,
      token: verificationToken,
      userId: 1,
      used: false,
      expiresAt: new Date(Date.now() + 86400000)
    };

    it('should verify email successfully', async () => {
      jwt.verify.mockReturnValueOnce(mockDecoded);
      prisma.emailVerification.findFirst.mockResolvedValueOnce(mockVerificationRecord);
      prisma.$transaction.mockResolvedValueOnce([{}, {}]);

      const result = await authService.verifyEmail(verificationToken);

      expect(jwt.verify).toHaveBeenCalledWith(verificationToken, 'test-jwt-secret');
      expect(prisma.emailVerification.findFirst).toHaveBeenCalledWith({
        where: {
          token: verificationToken,
          userId: 1,
          used: false,
          expiresAt: { gt: expect.any(Date) }
        }
      });
      expect(prisma.$transaction).toHaveBeenCalledWith(expect.any(Array));
      expect(result).toEqual({ message: 'Email verified successfully' });
    });

    it('should throw error for invalid token type', async () => {
      const invalidDecoded = { userId: 1, type: 'invalid_type' };
      jwt.verify.mockReturnValueOnce(invalidDecoded);

      await expect(authService.verifyEmail(verificationToken))
        .rejects
        .toThrow('Email verification failed: Invalid verification token');
    });

    it('should throw error for expired or used verification token', async () => {
      jwt.verify.mockReturnValueOnce(mockDecoded);
      prisma.emailVerification.findFirst.mockResolvedValueOnce(null);

      await expect(authService.verifyEmail(verificationToken))
        .rejects
        .toThrow('Email verification failed: Invalid or expired verification token');
    });

    it('should throw error if JWT verification fails', async () => {
      jwt.verify.mockImplementationOnce(() => {
        throw new Error('JWT malformed');
      });

      await expect(authService.verifyEmail(verificationToken))
        .rejects
        .toThrow('Email verification failed: JWT malformed');
    });

    it('should throw error if database transaction fails', async () => {
      jwt.verify.mockReturnValueOnce(mockDecoded);
      prisma.emailVerification.findFirst.mockResolvedValueOnce(mockVerificationRecord);
      prisma.$transaction.mockRejectedValueOnce(new Error('Transaction failed'));

      await expect(authService.verifyEmail(verificationToken))
        .rejects
        .toThrow('Email verification failed: Transaction failed');
    });
  });
});