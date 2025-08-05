// Users service module within core-service
const prisma = require('../../../lib/database');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

class UserService {
  // Get user by ID
  async getUserById(id) {
    try {
      return await prisma.user.findUnique({ 
        where: { id },
        select: {
          id: true,
          email: true,
          username: true,
          firstName: true,
          lastName: true,
          avatar: true,
          bio: true,
          location: true,
          website: true,
          isVerified: true,
          createdAt: true,
          updatedAt: true,
        }
      });
    } catch (error) {
      throw new Error(`Failed to get user: ${error.message}`);
    }
  }

  // Get user by email
  async getUserByEmail(email) {
    try {
      return await prisma.user.findUnique({ 
        where: { email }
      });
    } catch (error) {
      throw new Error(`Failed to get user by email: ${error.message}`);
    }
  }

  // Create new user
  async createUser(userData) {
    try {
      const { email, password, username, firstName, lastName } = userData;
      
      // Hash password
      const hashedPassword = await bcrypt.hash(password, 12);

      return await prisma.user.create({
        data: {
          email,
          password: hashedPassword,
          username,
          firstName,
          lastName,
        },
        select: {
          id: true,
          email: true,
          username: true,
          firstName: true,
          lastName: true,
          createdAt: true,
        }
      });
    } catch (error) {
      throw new Error(`Failed to create user: ${error.message}`);
    }
  }

  // Update user
  async updateUser(id, updateData) {
    try {
      return await prisma.user.update({
        where: { id },
        data: updateData,
        select: {
          id: true,
          email: true,
          username: true,
          firstName: true,
          lastName: true,
          avatar: true,
          bio: true,
          location: true,
          website: true,
          updatedAt: true,
        }
      });
    } catch (error) {
      throw new Error(`Failed to update user: ${error.message}`);
    }
  }

  // Delete user
  async deleteUser(id) {
    try {
      return await prisma.user.delete({
        where: { id }
      });
    } catch (error) {
      throw new Error(`Failed to delete user: ${error.message}`);
    }
  }

  // Authenticate user
  async authenticateUser(email, password) {
    try {
      const user = await this.getUserByEmail(email);
      if (!user) {
        throw new Error('User not found');
      }

      const isValidPassword = await bcrypt.compare(password, user.password);
      if (!isValidPassword) {
        throw new Error('Invalid password');
      }

      // Generate JWT token
      const token = jwt.sign(
        { userId: user.id, email: user.email },
        process.env.JWT_SECRET,
        { expiresIn: '7d' }
      );

      return {
        user: {
          id: user.id,
          email: user.email,
          username: user.username,
          firstName: user.firstName,
          lastName: user.lastName,
        },
        token
      };
    } catch (error) {
      throw new Error(`Authentication failed: ${error.message}`);
    }
  }

  // Get all users (with pagination)
  async getAllUsers(page = 1, limit = 10) {
    try {
      const skip = (page - 1) * limit;
      
      const [users, total] = await Promise.all([
        prisma.user.findMany({
          skip,
          take: limit,
          select: {
            id: true,
            email: true,
            username: true,
            firstName: true,
            lastName: true,
            avatar: true,
            isVerified: true,
            createdAt: true,
          },
          orderBy: { createdAt: 'desc' }
        }),
        prisma.user.count()
      ]);

      return {
        users,
        pagination: {
          current: page,
          total: Math.ceil(total / limit),
          count: total
        }
      };
    } catch (error) {
      throw new Error(`Failed to get users: ${error.message}`);
    }
  }
}

module.exports = new UserService();
