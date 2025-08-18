// Users module
const prisma = require('../../../lib/database');
const bcrypt = require('bcrypt');

module.exports = {
  // Get single user by ID
  async getUserById(id) {
    try {
      return await prisma.user.findUnique({
        where: { user_id: parseInt(id) },
        select: {
          user_id: true,
          name: true,
          email: true,
          phone_number: true,
          profile_picture: true,
          is_active: true,
          is_email_verified: true,
          role: true,
          created_at: true
        }
      });
    } catch (error) {
      throw new Error(`Failed to fetch user: ${error.message}`);
    }
  },

  // Get user by email (for authentication)
  async getUserByEmail(email) {
    try {
      return await prisma.user.findUnique({
        where: { email: email.toLowerCase() }
      });
    } catch (error) {
      throw new Error(`Failed to fetch user by email: ${error.message}`);
    }
  },

  // Get all users with optional filtering
  async getAllUsers(filters = {}) {
    try {
      const where = {};
      
      if (filters.role) {
        where.role = filters.role;
      }
      
      if (filters.is_active !== undefined) {
        where.is_active = filters.is_active;
      }
      
      if (filters.is_email_verified !== undefined) {
        where.is_email_verified = filters.is_email_verified;
      }
      
      if (filters.search) {
        where.OR = [
          { name: { contains: filters.search, mode: 'insensitive' } },
          { email: { contains: filters.search, mode: 'insensitive' } }
        ];
      }

      return await prisma.user.findMany({
        where,
        select: {
          user_id: true,
          name: true,
          email: true,
          phone_number: true,
          profile_picture: true,
          is_active: true,
          is_email_verified: true,
          role: true,
          created_at: true
        },
        orderBy: { created_at: 'desc' }
      });
    } catch (error) {
      throw new Error(`Failed to fetch users: ${error.message}`);
    }
  },

  // Create new user
  async createUser(data) {
    try {
      // Hash password
      const saltRounds = 12;
      const hashedPassword = await bcrypt.hash(data.password, saltRounds);

      return await prisma.user.create({
        data: {
          name: data.name,
          email: data.email.toLowerCase(),
          password_hash: hashedPassword,
          phone_number: data.phone_number || null,
          profile_picture: data.profile_picture || null,
          role: data.role || 'GUEST',
          is_active: data.is_active !== undefined ? data.is_active : true,
          is_email_verified: data.is_email_verified || false
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
          created_at: true
        }
      });
    } catch (error) {
      if (error.code === 'P2002') {
        throw new Error('User with this email already exists');
      }
      throw new Error(`Failed to create user: ${error.message}`);
    }
  },

  // Update user
  async updateUser(id, data) {
    try {
      const updateData = { ...data };
      delete updateData.user_id;
      delete updateData.created_at;
      delete updateData.password_hash;
      
      // Handle email case conversion
      if (updateData.email) {
        updateData.email = updateData.email.toLowerCase();
      }
      
      // Hash new password if provided
      if (data.password) {
        const saltRounds = 12;
        updateData.password_hash = await bcrypt.hash(data.password, saltRounds);
        delete updateData.password;
      }

      return await prisma.user.update({
        where: { user_id: parseInt(id) },
        data: updateData,
        select: {
          user_id: true,
          name: true,
          email: true,
          phone_number: true,
          profile_picture: true,
          is_active: true,
          is_email_verified: true,
          role: true,
          updated_at: true
        }
      });
    } catch (error) {
      if (error.code === 'P2002') {
        throw new Error('Email already in use by another user');
      }
      throw new Error(`Failed to update user: ${error.message}`);
    }
  },

  // Delete user (soft delete by deactivating)
  async deleteUser(id) {
    try {
      return await prisma.user.update({
        where: { user_id: parseInt(id) },
        data: { is_active: false }
      });
    } catch (error) {
      throw new Error(`Failed to delete user: ${error.message}`);
    }
  },

  // Permanently delete user
  async permanentDeleteUser(id) {
    try {
      return await prisma.user.delete({
        where: { user_id: parseInt(id) }
      });
    } catch (error) {
      throw new Error(`Failed to permanently delete user: ${error.message}`);
    }
  },

  // Verify password
  async verifyPassword(userId, password) {
    try {
      const user = await prisma.user.findUnique({
        where: { user_id: parseInt(userId) },
        select: { password_hash: true }
      });
      
      if (!user) {
        return false;
      }
      
      return await bcrypt.compare(password, user.password_hash);
    } catch (error) {
      throw new Error(`Failed to verify password: ${error.message}`);
    }
  },

  // Update email verification status
  async verifyEmail(userId) {
    try {
      return await prisma.user.update({
        where: { user_id: parseInt(userId) },
        data: { is_email_verified: true }
      });
    } catch (error) {
      throw new Error(`Failed to verify email: ${error.message}`);
    }
  },

  // Get user's organizations
  async getUserOrganizations(userId) {
    try {
      return await prisma.organization.findMany({
        where: { user_id: parseInt(userId) },
        include: {
          _count: {
            select: { events: true }
          }
        },
        orderBy: { created_at: 'desc' }
      });
    } catch (error) {
      throw new Error(`Failed to fetch user organizations: ${error.message}`);
    }
  },

  // Get user's created events
  async getUserEvents(userId) {
    try {
      return await prisma.event.findMany({
        where: { creator_id: parseInt(userId) },
        include: {
          organization: {
            select: {
              organization_id: true,
              name: true
            }
          }
        },
        orderBy: { created_at: 'desc' }
      });
    } catch (error) {
      throw new Error(`Failed to fetch user events: ${error.message}`);
    }
  },

  // Search users
  async searchUsers(query) {
    try {
      return await prisma.user.findMany({
        where: {
          OR: [
            { name: { contains: query, mode: 'insensitive' } },
            { email: { contains: query, mode: 'insensitive' } }
          ],
          is_active: true
        },
        select: {
          user_id: true,
          name: true,
          email: true,
          profile_picture: true,
          role: true
        },
        orderBy: { name: 'asc' }
      });
    } catch (error) {
      throw new Error(`Failed to search users: ${error.message}`);
    }
  }
};
