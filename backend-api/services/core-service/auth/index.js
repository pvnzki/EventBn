// Authentication service module within core-service
const prisma = require('../../../lib/database');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

class AuthService {
  // Generate JWT token
  generateToken(payload) {
    return jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '7d' });
  }

  // Verify JWT token
  verifyToken(token) {
    try {
      return jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
      throw new Error('Invalid token');
    }
  }

  // Register new user
async register(userData) {
  try {
    const { name, email, password, phone_number, profile_picture } = userData;

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email }
    });
    if (existingUser) {
      throw new Error('Email already registered');
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 12);

    // Create user
    const user = await prisma.user.create({
      data: {
        name,
        email,
        password_hash: hashedPassword,
        phone_number: phone_number || null,
        profile_picture: profile_picture || null,
        role: "GUEST", // or "USER" or whatever default you want
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

    // Generate token
    const token = this.generateToken({
      userId: user.user_id,
      email: user.email,
      name: user.name,
    });
    console.log("Generated JWT token:", token);
    return {
      user,
      token,
    };
  } catch (error) {
    throw new Error(`Registration failed: ${error.message}`);
  }
}

  // Login user
async login(credentials) {
  try {
    console.log("Login called with:", credentials);
    const { email, password } = credentials;

    // Find user by email
    const user = await prisma.user.findUnique({
      where: { email }
    });

    if (!user) {
      throw new Error('Invalid email or password');
    }
    if (!user.password_hash) {
      throw new Error('User has no password set');
    }

    // Verify password using bcrypt.compare
    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      throw new Error('Invalid email or password');
    }

    // Update last login
    await prisma.user.update({
      where: { user_id: user.user_id },
      data: { updated_at: new Date() }
    });

    // Generate token
    const token = this.generateToken({
      userId: user.user_id,
      email: user.email,
      name: user.name,
    });
    console.log("Generated JWT token:", token);

    return {
      user: {
        user_id: user.user_id,
        name: user.name,
        email: user.email,
        phone_number: user.phone_number,
        profile_picture: user.profile_picture,
        is_active: user.is_active,
        is_email_verified: user.is_email_verified,
        role: user.role,
        created_at: user.created_at,
        updated_at: user.updated_at
      },
      token,
    };
  } catch (error) {
    throw new Error(`Login failed: ${error.message}`);
  }
}

  // Logout user (invalidate token - in real app, you'd maintain a blacklist)
  async logout(token) {
    try {
      // In a production app, you would add this token to a blacklist
      // For now, we'll just verify it's valid
      this.verifyToken(token);
      return { message: 'Logged out successfully' };
    } catch (error) {
      throw new Error(`Logout failed: ${error.message}`);
    }
  }

  // Change password
  async changePassword(userId, passwordData) {
    try {
      const { currentPassword, newPassword } = passwordData;

      // Get user with password
      const user = await prisma.user.findUnique({
        where: { id: userId }
      });

      if (!user) {
        throw new Error('User not found');
      }

      // Verify current password
      const isValidPassword = await bcrypt.compare(currentPassword, user.password);
      if (!isValidPassword) {
        throw new Error('Current password is incorrect');
      }

      // Hash new password
      const hashedNewPassword = await bcrypt.hash(newPassword, 12);

      // Update password
      await prisma.user.update({
        where: { id: userId },
        data: { 
          password: hashedNewPassword,
          updatedAt: new Date(),
        }
      });

      return { message: 'Password changed successfully' };
    } catch (error) {
      throw new Error(`Password change failed: ${error.message}`);
    }
  }

  // Forgot password (generate reset token)
  async forgotPassword(email) {
    try {
      const user = await prisma.user.findUnique({
        where: { email }
      });

      if (!user) {
        // Don't reveal if email exists or not
        return { message: 'If the email exists, a reset link has been sent' };
      }

      // Generate reset token
      const resetToken = jwt.sign(
        { userId: user.id, type: 'password_reset' },
        process.env.JWT_SECRET,
        { expiresIn: '1h' }
      );

      // Store reset token in database
      await prisma.passwordReset.create({
        data: {
          userId: user.id,
          token: resetToken,
          expiresAt: new Date(Date.now() + 3600000), // 1 hour
        }
      });

      // In a real app, you would send this via email
      return { 
        message: 'If the email exists, a reset link has been sent',
        resetToken, // Only for development
      };
    } catch (error) {
      throw new Error(`Password reset failed: ${error.message}`);
    }
  }

  // Reset password with token
  async resetPassword(resetData) {
    try {
      const { token, newPassword } = resetData;

      // Verify reset token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      
      if (decoded.type !== 'password_reset') {
        throw new Error('Invalid reset token');
      }

      // Check if token exists in database and is not expired
      const resetRecord = await prisma.passwordReset.findFirst({
        where: {
          token,
          userId: decoded.userId,
          used: false,
          expiresAt: {
            gt: new Date(),
          }
        }
      });

      if (!resetRecord) {
        throw new Error('Invalid or expired reset token');
      }

      // Hash new password
      const hashedPassword = await bcrypt.hash(newPassword, 12);

      // Update password and mark token as used
      await prisma.$transaction([
        prisma.user.update({
          where: { id: decoded.userId },
          data: { 
            password: hashedPassword,
            updatedAt: new Date(),
          }
        }),
        prisma.passwordReset.update({
          where: { id: resetRecord.id },
          data: { used: true }
        })
      ]);

      return { message: 'Password reset successfully' };
    } catch (error) {
      throw new Error(`Password reset failed: ${error.message}`);
    }
  }

  // Verify email (send verification token)
  async sendEmailVerification(userId) {
    try {
      const user = await prisma.user.findUnique({
        where: { id: userId }
      });

      if (!user) {
        throw new Error('User not found');
      }

      if (user.isVerified) {
        throw new Error('Email already verified');
      }

      // Generate verification token
      const verificationToken = jwt.sign(
        { userId: user.id, type: 'email_verification' },
        process.env.JWT_SECRET,
        { expiresIn: '24h' }
      );

      // Store verification token
      await prisma.emailVerification.create({
        data: {
          userId: user.id,
          token: verificationToken,
          expiresAt: new Date(Date.now() + 86400000), // 24 hours
        }
      });

      // In a real app, you would send this via email
      return { 
        message: 'Verification email sent',
        verificationToken, // Only for development
      };
    } catch (error) {
      throw new Error(`Email verification failed: ${error.message}`);
    }
  }

  // Verify email with token
  async verifyEmail(token) {
    try {
      // Verify token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      
      if (decoded.type !== 'email_verification') {
        throw new Error('Invalid verification token');
      }

      // Check if token exists in database and is not expired
      const verificationRecord = await prisma.emailVerification.findFirst({
        where: {
          token,
          userId: decoded.userId,
          used: false,
          expiresAt: {
            gt: new Date(),
          }
        }
      });

      if (!verificationRecord) {
        throw new Error('Invalid or expired verification token');
      }

      // Update user verification status and mark token as used
      await prisma.$transaction([
        prisma.user.update({
          where: { id: decoded.userId },
          data: { 
            isVerified: true,
            emailVerifiedAt: new Date(),
            updatedAt: new Date(),
          }
        }),
        prisma.emailVerification.update({
          where: { id: verificationRecord.id },
          data: { used: true }
        })
      ]);

      return { message: 'Email verified successfully' };
    } catch (error) {
      throw new Error(`Email verification failed: ${error.message}`);
    }
  }
}

module.exports = new AuthService();
