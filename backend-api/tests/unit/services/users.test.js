// Unit tests for users service
const usersService = require('../../../services/core-service/users');
const bcrypt = require('bcrypt');

// Mock the database
jest.mock('../../../lib/database', () => ({
  user: {
    findUnique: jest.fn(),
    findMany: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    delete: jest.fn()
  },
  organization: {
    findMany: jest.fn()
  },
  event: {
    findMany: jest.fn()
  }
}));

// Mock bcrypt
jest.mock('bcrypt', () => ({
  hash: jest.fn(),
  compare: jest.fn()
}));

const db = require('../../../lib/database');

describe('Users Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('getUserById', () => {
    it('should return user data for a valid ID', async () => {
      const mockUser = {
        user_id: 1,
        name: 'John Doe',
        email: 'john@example.com',
        phone_number: '+1234567890',
        profile_picture: null,
        is_active: true,
        is_email_verified: true,
        role: 'USER',
        created_at: new Date('2024-01-01')
      };

      db.user.findUnique.mockResolvedValueOnce(mockUser);

      const result = await usersService.getUserById(1);
      
      expect(db.user.findUnique).toHaveBeenCalledWith({
        where: { user_id: 1 },
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
      expect(result).toEqual(mockUser);
    });

    it('should return null for non-existent user', async () => {
      db.user.findUnique.mockResolvedValueOnce(null);

      const result = await usersService.getUserById(999);
      
      expect(result).toBeNull();
    });

    it('should throw error if database fails', async () => {
      db.user.findUnique.mockRejectedValueOnce(new Error('DB error'));

      await expect(usersService.getUserById(1))
        .rejects
        .toThrow('Failed to fetch user: DB error');
    });

    it('should handle string ID by converting to integer', async () => {
      const mockUser = { user_id: 1, name: 'John Doe' };
      db.user.findUnique.mockResolvedValueOnce(mockUser);

      await usersService.getUserById('1');
      
      expect(db.user.findUnique).toHaveBeenCalledWith({
        where: { user_id: 1 },
        select: expect.any(Object)
      });
    });
  });

  describe('getUserByEmail', () => {
    it('should return user data for a valid email', async () => {
      const mockUser = {
        user_id: 1,
        name: 'John Doe',
        email: 'john@example.com',
        password_hash: 'hashedpassword'
      };

      db.user.findUnique.mockResolvedValueOnce(mockUser);

      const result = await usersService.getUserByEmail('John@Example.com');
      
      expect(db.user.findUnique).toHaveBeenCalledWith({
        where: { email: 'john@example.com' }
      });
      expect(result).toEqual(mockUser);
    });

    it('should convert email to lowercase', async () => {
      db.user.findUnique.mockResolvedValueOnce(null);

      await usersService.getUserByEmail('JOHN@EXAMPLE.COM');
      
      expect(db.user.findUnique).toHaveBeenCalledWith({
        where: { email: 'john@example.com' }
      });
    });

    it('should return null for non-existent email', async () => {
      db.user.findUnique.mockResolvedValueOnce(null);

      const result = await usersService.getUserByEmail('nonexistent@example.com');
      
      expect(result).toBeNull();
    });

    it('should throw error if database fails', async () => {
      db.user.findUnique.mockRejectedValueOnce(new Error('DB error'));

      await expect(usersService.getUserByEmail('john@example.com'))
        .rejects
        .toThrow('Failed to fetch user by email: DB error');
    });
  });

  describe('getAllUsers', () => {
    const mockUsers = [
      { user_id: 1, name: 'John Doe', email: 'john@example.com', role: 'USER' },
      { user_id: 2, name: 'Jane Smith', email: 'jane@example.com', role: 'ADMIN' }
    ];

    it('should return all users when no filters provided', async () => {
      db.user.findMany.mockResolvedValueOnce(mockUsers);

      const result = await usersService.getAllUsers();
      
      expect(db.user.findMany).toHaveBeenCalledWith({
        where: {},
        select: expect.any(Object),
        orderBy: { created_at: 'desc' }
      });
      expect(result).toEqual(mockUsers);
    });

    it('should filter users by role', async () => {
      db.user.findMany.mockResolvedValueOnce([mockUsers[1]]);

      const result = await usersService.getAllUsers({ role: 'ADMIN' });
      
      expect(db.user.findMany).toHaveBeenCalledWith({
        where: { role: 'ADMIN' },
        select: expect.any(Object),
        orderBy: { created_at: 'desc' }
      });
      expect(result).toEqual([mockUsers[1]]);
    });

    it('should filter users by is_active status', async () => {
      db.user.findMany.mockResolvedValueOnce(mockUsers);

      await usersService.getAllUsers({ is_active: true });
      
      expect(db.user.findMany).toHaveBeenCalledWith({
        where: { is_active: true },
        select: expect.any(Object),
        orderBy: { created_at: 'desc' }
      });
    });

    it('should filter users by email verification status', async () => {
      db.user.findMany.mockResolvedValueOnce(mockUsers);

      await usersService.getAllUsers({ is_email_verified: false });
      
      expect(db.user.findMany).toHaveBeenCalledWith({
        where: { is_email_verified: false },
        select: expect.any(Object),
        orderBy: { created_at: 'desc' }
      });
    });

    it('should search users by name and email', async () => {
      db.user.findMany.mockResolvedValueOnce([mockUsers[0]]);

      await usersService.getAllUsers({ search: 'john' });
      
      expect(db.user.findMany).toHaveBeenCalledWith({
        where: {
          OR: [
            { name: { contains: 'john', mode: 'insensitive' } },
            { email: { contains: 'john', mode: 'insensitive' } }
          ]
        },
        select: expect.any(Object),
        orderBy: { created_at: 'desc' }
      });
    });

    it('should combine multiple filters', async () => {
      db.user.findMany.mockResolvedValueOnce([]);

      await usersService.getAllUsers({ 
        role: 'USER', 
        is_active: true, 
        search: 'john' 
      });
      
      expect(db.user.findMany).toHaveBeenCalledWith({
        where: {
          role: 'USER',
          is_active: true,
          OR: [
            { name: { contains: 'john', mode: 'insensitive' } },
            { email: { contains: 'john', mode: 'insensitive' } }
          ]
        },
        select: expect.any(Object),
        orderBy: { created_at: 'desc' }
      });
    });

    it('should throw error if database fails', async () => {
      db.user.findMany.mockRejectedValueOnce(new Error('DB error'));

      await expect(usersService.getAllUsers())
        .rejects
        .toThrow('Failed to fetch users: DB error');
    });
  });

  describe('createUser', () => {
    const userData = {
      name: 'John Doe',
      email: 'John@Example.com',
      password: 'password123',
      phone_number: '+1234567890',
      role: 'USER'
    };

    const hashedPassword = 'hashedpassword123';
    const mockCreatedUser = {
      user_id: 1,
      name: 'John Doe',
      email: 'john@example.com',
      phone_number: '+1234567890',
      profile_picture: null,
      is_active: true,
      is_email_verified: false,
      role: 'USER',
      created_at: new Date('2024-01-01')
    };

    beforeEach(() => {
      bcrypt.hash.mockResolvedValue(hashedPassword);
      db.user.create.mockResolvedValue(mockCreatedUser);
    });

    it('should create user with hashed password', async () => {
      const result = await usersService.createUser(userData);
      
      expect(bcrypt.hash).toHaveBeenCalledWith('password123', 12);
      expect(db.user.create).toHaveBeenCalledWith({
        data: {
          name: 'John Doe',
          email: 'john@example.com',
          password_hash: hashedPassword,
          phone_number: '+1234567890',
          profile_picture: null,
          role: 'USER',
          is_active: true,
          is_email_verified: false
        },
        select: expect.any(Object)
      });
      expect(result).toEqual(mockCreatedUser);
    });

    it('should create user with default values', async () => {
      const minimalData = {
        name: 'John Doe',
        email: 'john@example.com',
        password: 'password123'
      };

      await usersService.createUser(minimalData);
      
      expect(db.user.create).toHaveBeenCalledWith({
        data: {
          name: 'John Doe',
          email: 'john@example.com',
          password_hash: hashedPassword,
          phone_number: null,
          profile_picture: null,
          role: 'GUEST',
          is_active: true,
          is_email_verified: false
        },
        select: expect.any(Object)
      });
    });

    it('should handle custom is_active and is_email_verified values', async () => {
      const customData = {
        ...userData,
        is_active: false,
        is_email_verified: true
      };

      await usersService.createUser(customData);
      
      expect(db.user.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          is_active: false,
          is_email_verified: true
        }),
        select: expect.any(Object)
      });
    });

    it('should throw error for duplicate email', async () => {
      const duplicateError = new Error('Unique constraint failed');
      duplicateError.code = 'P2002';
      db.user.create.mockRejectedValueOnce(duplicateError);

      await expect(usersService.createUser(userData))
        .rejects
        .toThrow('User with this email already exists');
    });

    it('should throw error if database fails', async () => {
      db.user.create.mockRejectedValueOnce(new Error('DB error'));

      await expect(usersService.createUser(userData))
        .rejects
        .toThrow('Failed to create user: DB error');
    });

    it('should throw error if password hashing fails', async () => {
      bcrypt.hash.mockRejectedValueOnce(new Error('Hash error'));

      await expect(usersService.createUser(userData))
        .rejects
        .toThrow('Hash error');
    });
  });

  describe('updateUser', () => {
    const userId = 1;
    const updateData = {
      name: 'John Updated',
      email: 'johnupdated@example.com',
      phone_number: '+0987654321'
    };

    const mockUpdatedUser = {
      user_id: 1,
      name: 'John Updated',
      email: 'johnupdated@example.com',
      phone_number: '+0987654321',
      profile_picture: null,
      is_active: true,
      is_email_verified: true,
      role: 'USER',
      updated_at: new Date('2024-01-02')
    };

    beforeEach(() => {
      db.user.update.mockResolvedValue(mockUpdatedUser);
    });

    it('should update user successfully', async () => {
      const result = await usersService.updateUser(userId, updateData);
      
      expect(db.user.update).toHaveBeenCalledWith({
        where: { user_id: 1 },
        data: {
          name: 'John Updated',
          email: 'johnupdated@example.com',
          phone_number: '+0987654321'
        },
        select: expect.any(Object)
      });
      expect(result).toEqual(mockUpdatedUser);
    });

    it('should convert email to lowercase', async () => {
      await usersService.updateUser(userId, { 
        email: 'JOHN@EXAMPLE.COM' 
      });
      
      expect(db.user.update).toHaveBeenCalledWith({
        where: { user_id: 1 },
        data: { email: 'john@example.com' },
        select: expect.any(Object)
      });
    });

    it('should hash new password when provided', async () => {
      const hashedPassword = 'newhashedpassword';
      bcrypt.hash.mockResolvedValueOnce(hashedPassword);

      await usersService.updateUser(userId, { 
        name: 'John',
        password: 'newpassword123' 
      });
      
      expect(bcrypt.hash).toHaveBeenCalledWith('newpassword123', 12);
      expect(db.user.update).toHaveBeenCalledWith({
        where: { user_id: 1 },
        data: { 
          name: 'John',
          password_hash: hashedPassword
        },
        select: expect.any(Object)
      });
    });

    it('should remove restricted fields from update data', async () => {
      await usersService.updateUser(userId, {
        name: 'John',
        user_id: 999, // Should be removed
        created_at: new Date(), // Should be removed
        password_hash: 'direct_hash' // Should be removed
      });
      
      expect(db.user.update).toHaveBeenCalledWith({
        where: { user_id: 1 },
        data: { name: 'John' },
        select: expect.any(Object)
      });
    });

    it('should handle string userId by converting to integer', async () => {
      await usersService.updateUser('1', updateData);
      
      expect(db.user.update).toHaveBeenCalledWith({
        where: { user_id: 1 },
        data: expect.any(Object),
        select: expect.any(Object)
      });
    });

    it('should throw error for duplicate email', async () => {
      const duplicateError = new Error('Unique constraint failed');
      duplicateError.code = 'P2002';
      db.user.update.mockRejectedValueOnce(duplicateError);

      await expect(usersService.updateUser(userId, updateData))
        .rejects
        .toThrow('Email already in use by another user');
    });

    it('should throw error if database fails', async () => {
      db.user.update.mockRejectedValueOnce(new Error('DB error'));

      await expect(usersService.updateUser(userId, updateData))
        .rejects
        .toThrow('Failed to update user: DB error');
    });
  });

  describe('deleteUser', () => {
    it('should soft delete user by setting is_active to false', async () => {
      const mockResult = { user_id: 1, is_active: false };
      db.user.update.mockResolvedValueOnce(mockResult);

      const result = await usersService.deleteUser(1);
      
      expect(db.user.update).toHaveBeenCalledWith({
        where: { user_id: 1 },
        data: { is_active: false }
      });
      expect(result).toEqual(mockResult);
    });

    it('should handle string userId by converting to integer', async () => {
      db.user.update.mockResolvedValueOnce({ user_id: 1 });

      await usersService.deleteUser('1');
      
      expect(db.user.update).toHaveBeenCalledWith({
        where: { user_id: 1 },
        data: { is_active: false }
      });
    });

    it('should throw error if database fails', async () => {
      db.user.update.mockRejectedValueOnce(new Error('DB error'));

      await expect(usersService.deleteUser(1))
        .rejects
        .toThrow('Failed to delete user: DB error');
    });
  });

  describe('permanentDeleteUser', () => {
    it('should permanently delete user', async () => {
      const mockResult = { user_id: 1 };
      db.user.delete.mockResolvedValueOnce(mockResult);

      const result = await usersService.permanentDeleteUser(1);
      
      expect(db.user.delete).toHaveBeenCalledWith({
        where: { user_id: 1 }
      });
      expect(result).toEqual(mockResult);
    });

    it('should handle string userId by converting to integer', async () => {
      db.user.delete.mockResolvedValueOnce({ user_id: 1 });

      await usersService.permanentDeleteUser('1');
      
      expect(db.user.delete).toHaveBeenCalledWith({
        where: { user_id: 1 }
      });
    });

    it('should throw error if database fails', async () => {
      db.user.delete.mockRejectedValueOnce(new Error('DB error'));

      await expect(usersService.permanentDeleteUser(1))
        .rejects
        .toThrow('Failed to permanently delete user: DB error');
    });
  });

  describe('verifyPassword', () => {
    const userId = 1;
    const password = 'password123';
    const hashedPassword = 'hashedpassword123';

    it('should return true for correct password', async () => {
      db.user.findUnique.mockResolvedValueOnce({ 
        password_hash: hashedPassword 
      });
      bcrypt.compare.mockResolvedValueOnce(true);

      const result = await usersService.verifyPassword(userId, password);
      
      expect(db.user.findUnique).toHaveBeenCalledWith({
        where: { user_id: 1 },
        select: { password_hash: true }
      });
      expect(bcrypt.compare).toHaveBeenCalledWith(password, hashedPassword);
      expect(result).toBe(true);
    });

    it('should return false for incorrect password', async () => {
      db.user.findUnique.mockResolvedValueOnce({ 
        password_hash: hashedPassword 
      });
      bcrypt.compare.mockResolvedValueOnce(false);

      const result = await usersService.verifyPassword(userId, 'wrongpassword');
      
      expect(result).toBe(false);
    });

    it('should return false if user not found', async () => {
      db.user.findUnique.mockResolvedValueOnce(null);

      const result = await usersService.verifyPassword(999, password);
      
      expect(result).toBe(false);
      expect(bcrypt.compare).not.toHaveBeenCalled();
    });

    it('should handle string userId by converting to integer', async () => {
      db.user.findUnique.mockResolvedValueOnce({ 
        password_hash: hashedPassword 
      });
      bcrypt.compare.mockResolvedValueOnce(true);

      await usersService.verifyPassword('1', password);
      
      expect(db.user.findUnique).toHaveBeenCalledWith({
        where: { user_id: 1 },
        select: { password_hash: true }
      });
    });

    it('should throw error if database fails', async () => {
      db.user.findUnique.mockRejectedValueOnce(new Error('DB error'));

      await expect(usersService.verifyPassword(userId, password))
        .rejects
        .toThrow('Failed to verify password: DB error');
    });
  });

  describe('verifyEmail', () => {
    it('should set email verification to true', async () => {
      const mockResult = { 
        user_id: 1, 
        is_email_verified: true 
      };
      db.user.update.mockResolvedValueOnce(mockResult);

      const result = await usersService.verifyEmail(1);
      
      expect(db.user.update).toHaveBeenCalledWith({
        where: { user_id: 1 },
        data: { is_email_verified: true }
      });
      expect(result).toEqual(mockResult);
    });

    it('should handle string userId by converting to integer', async () => {
      db.user.update.mockResolvedValueOnce({ user_id: 1 });

      await usersService.verifyEmail('1');
      
      expect(db.user.update).toHaveBeenCalledWith({
        where: { user_id: 1 },
        data: { is_email_verified: true }
      });
    });

    it('should throw error if database fails', async () => {
      db.user.update.mockRejectedValueOnce(new Error('DB error'));

      await expect(usersService.verifyEmail(1))
        .rejects
        .toThrow('Failed to verify email: DB error');
    });
  });

  describe('getUserOrganizations', () => {
    const userId = 1;
    const mockOrganizations = [
      {
        organization_id: 1,
        name: 'Org 1',
        user_id: 1,
        _count: { events: 5 },
        created_at: new Date('2024-01-01')
      },
      {
        organization_id: 2,
        name: 'Org 2',
        user_id: 1,
        _count: { events: 3 },
        created_at: new Date('2024-01-02')
      }
    ];

    it('should return user organizations with event counts', async () => {
      db.organization.findMany.mockResolvedValueOnce(mockOrganizations);

      const result = await usersService.getUserOrganizations(userId);
      
      expect(db.organization.findMany).toHaveBeenCalledWith({
        where: { user_id: 1 },
        include: {
          _count: {
            select: { events: true }
          }
        },
        orderBy: { created_at: 'desc' }
      });
      expect(result).toEqual(mockOrganizations);
    });

    it('should return empty array if user has no organizations', async () => {
      db.organization.findMany.mockResolvedValueOnce([]);

      const result = await usersService.getUserOrganizations(userId);
      
      expect(result).toEqual([]);
    });

    it('should handle string userId by converting to integer', async () => {
      db.organization.findMany.mockResolvedValueOnce([]);

      await usersService.getUserOrganizations('1');
      
      expect(db.organization.findMany).toHaveBeenCalledWith({
        where: { user_id: 1 },
        include: expect.any(Object),
        orderBy: { created_at: 'desc' }
      });
    });

    it('should throw error if database fails', async () => {
      db.organization.findMany.mockRejectedValueOnce(new Error('DB error'));

      await expect(usersService.getUserOrganizations(userId))
        .rejects
        .toThrow('Failed to fetch user organizations: DB error');
    });
  });

  describe('getUserEvents', () => {
    const userId = 1;
    const mockEvents = [
      {
        event_id: 1,
        title: 'Event 1',
        creator_id: 1,
        organization: {
          organization_id: 1,
          name: 'Org 1'
        },
        created_at: new Date('2024-01-01')
      },
      {
        event_id: 2,
        title: 'Event 2',
        creator_id: 1,
        organization: {
          organization_id: 2,
          name: 'Org 2'
        },
        created_at: new Date('2024-01-02')
      }
    ];

    it('should return user created events with organization info', async () => {
      db.event.findMany.mockResolvedValueOnce(mockEvents);

      const result = await usersService.getUserEvents(userId);
      
      expect(db.event.findMany).toHaveBeenCalledWith({
        where: { creator_id: 1 },
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
      expect(result).toEqual(mockEvents);
    });

    it('should return empty array if user has no events', async () => {
      db.event.findMany.mockResolvedValueOnce([]);

      const result = await usersService.getUserEvents(userId);
      
      expect(result).toEqual([]);
    });

    it('should handle string userId by converting to integer', async () => {
      db.event.findMany.mockResolvedValueOnce([]);

      await usersService.getUserEvents('1');
      
      expect(db.event.findMany).toHaveBeenCalledWith({
        where: { creator_id: 1 },
        include: expect.any(Object),
        orderBy: { created_at: 'desc' }
      });
    });

    it('should throw error if database fails', async () => {
      db.event.findMany.mockRejectedValueOnce(new Error('DB error'));

      await expect(usersService.getUserEvents(userId))
        .rejects
        .toThrow('Failed to fetch user events: DB error');
    });
  });

  describe('searchUsers', () => {
    const query = 'john';
    const mockUsers = [
      {
        user_id: 1,
        name: 'John Doe',
        email: 'john@example.com',
        profile_picture: null,
        role: 'USER'
      },
      {
        user_id: 2,
        name: 'Johnny Smith',
        email: 'johnny@example.com',
        profile_picture: 'avatar.jpg',
        role: 'USER'
      }
    ];

    it('should search users by name and email', async () => {
      db.user.findMany.mockResolvedValueOnce(mockUsers);

      const result = await usersService.searchUsers(query);
      
      expect(db.user.findMany).toHaveBeenCalledWith({
        where: {
          OR: [
            { name: { contains: 'john', mode: 'insensitive' } },
            { email: { contains: 'john', mode: 'insensitive' } }
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
      expect(result).toEqual(mockUsers);
    });

    it('should return empty array if no users match', async () => {
      db.user.findMany.mockResolvedValueOnce([]);

      const result = await usersService.searchUsers('nonexistent');
      
      expect(result).toEqual([]);
    });

    it('should only return active users', async () => {
      db.user.findMany.mockResolvedValueOnce([]);

      await usersService.searchUsers(query);
      
      expect(db.user.findMany).toHaveBeenCalledWith({
        where: expect.objectContaining({
          is_active: true
        }),
        select: expect.any(Object),
        orderBy: { name: 'asc' }
      });
    });

    it('should throw error if database fails', async () => {
      db.user.findMany.mockRejectedValueOnce(new Error('DB error'));

      await expect(usersService.searchUsers(query))
        .rejects
        .toThrow('Failed to search users: DB error');
    });
  });
});