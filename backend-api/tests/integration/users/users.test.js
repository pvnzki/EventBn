/**
 * Users API Integration Tests
 * 
 * Tests user profile management, relationships, and user-specific operations.
 */

const {
  app,
  request,
  setupTestDatabase,
  teardownTestDatabase,
  createTestUser,
  createTestOrganizer,
  expectSuccessResponse,
  expectErrorResponse,
  expectAuthenticationRequired,
  expectValidationError,
  generateUniqueEmail
} = require('../../fixtures/prisma-mock');

describe('Users API Integration Tests', () => {
  beforeAll(async () => {
    await setupTestDatabase();
  });

  afterAll(async () => {
    await teardownTestDatabase();
  });

  beforeEach(async () => {
    await setupTestDatabase();
  });

  describe('GET /api/users', () => {
    let users = [];

    beforeEach(async () => {
      // Create multiple test users
      for (let i = 1; i <= 5; i++) {
        const user = await createTestUser({
          name: `User ${i}`,
          email: generateUniqueEmail(`user${i}`),
          role: i <= 2 ? 'ORGANIZER' : 'ATTENDEE'
        });
        users.push(user);
      }
    });

    it('should return paginated user list', async () => {
      const response = await request(app)
        .get('/api/users')
        .query({ page: 1, limit: 3 });

      expect(response.status).toBe(200);
      expectSuccessResponse(response);
      expect(Array.isArray(response.body.data)).toBe(true);
      expect(response.body.data.length).toBeLessThanOrEqual(3);

      // Verify user structure
      const user = response.body.data[0];
      expect(user).toHaveProperty('user_id');
      expect(user).toHaveProperty('name');
      expect(user).toHaveProperty('email');
      expect(user.password).toBeUndefined(); // Password should not be exposed
    });

    it('should filter users by role', async () => {
      const response = await request(app)
        .get('/api/users')
        .query({ role: 'ORGANIZER' });

      expect(response.status).toBe(200);
      expectSuccessResponse(response);
      
      response.body.data.forEach(user => {
        expect(user.role).toBe('ORGANIZER');
      });
    });

    it('should search users by name', async () => {
      const response = await request(app)
        .get('/api/users')
        .query({ search: 'User 1' });

      expect(response.status).toBe(200);
      expectSuccessResponse(response);
      
      if (response.body.data.length > 0) {
        expect(response.body.data[0].name).toContain('User 1');
      }
    });

    it('should handle empty results gracefully', async () => {
      const response = await request(app)
        .get('/api/users')
        .query({ search: 'NonExistentUser12345' });

      expect(response.status).toBe(200);
      expectSuccessResponse(response);
      expect(response.body.data).toEqual([]);
    });
  });

  describe('GET /api/users/:id', () => {
    let testUser;

    beforeEach(async () => {
      testUser = await createTestUser({
        name: 'Profile Test User',
        email: generateUniqueEmail('profile')
      });
    });

    it('should return user profile by ID', async () => {
      const response = await request(app)
        .get(`/api/users/${testUser.user.user_id}`);

      expect(response.status).toBe(200);
      expectSuccessResponse(response);
      expect(response.body.data).toMatchObject({
        user_id: testUser.user.user_id,
        name: testUser.user.name,
        email: testUser.user.email
      });
      expect(response.body.data.password).toBeUndefined();
    });

    it('should return 404 for non-existent user', async () => {
      const response = await request(app)
        .get('/api/users/999999');

      expect(response.status).toBe(404);
      expectErrorResponse(response, 404);
    });

    it('should handle invalid user ID format', async () => {
      const response = await request(app)
        .get('/api/users/invalid-id');

      expect(response.status).toBe(500); // Depends on implementation
    });
  });

  describe('PUT /api/users/:id', () => {
    let testUser;
    let otherUser;

    beforeEach(async () => {
      testUser = await createTestUser({
        name: 'Update Test User',
        email: generateUniqueEmail('update')
      });
      
      otherUser = await createTestUser({
        email: generateUniqueEmail('other')
      });
    });

    it('should update own profile with valid data', async () => {
      const updateData = {
        name: 'Updated Name',
        phone_number: '+9876543210',
        bio: 'Updated bio information'
      };

      const response = await request(app)
        .put(`/api/users/${testUser.user.user_id}`)
        .set('Authorization', `Bearer ${testUser.token}`)
        .send(updateData);

      expect(response.status).toBe(200);
      expectSuccessResponse(response);
      expect(response.body.data).toMatchObject(updateData);
    });

    it('should reject update without authentication', async () => {
      const response = await request(app)
        .put(`/api/users/${testUser.user.user_id}`)
        .send({ name: 'Unauthorized Update' });

      expectAuthenticationRequired(response);
    });

    it('should reject update of other user profile', async () => {
      const response = await request(app)
        .put(`/api/users/${otherUser.user.user_id}`)
        .set('Authorization', `Bearer ${testUser.token}`)
        .send({ name: 'Unauthorized Update' });

      expect(response.status).toBe(403);
      expectErrorResponse(response, 403);
    });

    it('should reject invalid email format in update', async () => {
      const response = await request(app)
        .put(`/api/users/${testUser.user.user_id}`)
        .set('Authorization', `Bearer ${testUser.token}`)
        .send({ email: 'invalid-email-format' });

      expectValidationError(response);
    });

    it('should reject duplicate email in update', async () => {
      const response = await request(app)
        .put(`/api/users/${testUser.user.user_id}`)
        .set('Authorization', `Bearer ${testUser.token}`)
        .send({ email: otherUser.user.email });

      expectValidationError(response);
    });

    it('should not allow role changes in regular update', async () => {
      const response = await request(app)
        .put(`/api/users/${testUser.user.user_id}`)
        .set('Authorization', `Bearer ${testUser.token}`)
        .send({ role: 'ADMIN' });

      // Should either ignore the role field or reject the request
      expect(response.status).toBe(200);
      expect(response.body.data.role).not.toBe('ADMIN');
    });
  });

  describe('DELETE /api/users/:id', () => {
    let testUser;
    let otherUser;

    beforeEach(async () => {
      testUser = await createTestUser({
        email: generateUniqueEmail('delete')
      });
      
      otherUser = await createTestUser({
        email: generateUniqueEmail('delete-other')
      });
    });

    it('should delete own account with authentication', async () => {
      const response = await request(app)
        .delete(`/api/users/${testUser.user.user_id}`)
        .set('Authorization', `Bearer ${testUser.token}`);

      expect(response.status).toBe(200);
      expectSuccessResponse(response);

      // Verify user is deleted
      const getResponse = await request(app)
        .get(`/api/users/${testUser.user.user_id}`);
      expect(getResponse.status).toBe(404);
    });

    it('should reject deletion without authentication', async () => {
      const response = await request(app)
        .delete(`/api/users/${testUser.user.user_id}`);

      expectAuthenticationRequired(response);
    });

    it('should reject deletion of other user account', async () => {
      const response = await request(app)
        .delete(`/api/users/${otherUser.user.user_id}`)
        .set('Authorization', `Bearer ${testUser.token}`);

      expect(response.status).toBe(403);
      expectErrorResponse(response, 403);
    });

    it('should return 404 for non-existent user deletion', async () => {
      const response = await request(app)
        .delete('/api/users/999999')
        .set('Authorization', `Bearer ${testUser.token}`);

      expect(response.status).toBe(404);
      expectErrorResponse(response, 404);
    });
  });

  describe('User Profile Management Integration', () => {
    let user;

    beforeEach(async () => {
      user = await createTestUser({
        name: 'Integration User',
        email: generateUniqueEmail('integration')
      });
    });

    it('should complete profile update -> retrieve -> verify flow', async () => {
      const updateData = {
        name: 'Updated Integration User',
        phone_number: '+1234567890',
        bio: 'Integration test bio',
        preferences: {
          notifications: true,
          theme: 'dark'
        }
      };

      // Step 1: Update profile
      const updateResponse = await request(app)
        .put(`/api/users/${user.user.user_id}`)
        .set('Authorization', `Bearer ${user.token}`)
        .send(updateData);

      expect(updateResponse.status).toBe(200);

      // Step 2: Retrieve updated profile
      const getResponse = await request(app)
        .get(`/api/users/${user.user.user_id}`);

      expect(getResponse.status).toBe(200);
      expect(getResponse.body.data).toMatchObject({
        name: updateData.name,
        phone_number: updateData.phone_number,
        bio: updateData.bio
      });

      // Step 3: Verify via /me endpoint
      const meResponse = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${user.token}`);

      expect(meResponse.status).toBe(200);
      expect(meResponse.body.user.name).toBe(updateData.name);
    });

    it('should handle partial profile updates', async () => {
      // Initial state
      const initialResponse = await request(app)
        .get(`/api/users/${user.user.user_id}`);
      
      const initialName = initialResponse.body.data.name;

      // Partial update
      const partialUpdate = await request(app)
        .put(`/api/users/${user.user.user_id}`)
        .set('Authorization', `Bearer ${user.token}`)
        .send({ phone_number: '+9876543210' });

      expect(partialUpdate.status).toBe(200);
      expect(partialUpdate.body.data.phone_number).toBe('+9876543210');
      expect(partialUpdate.body.data.name).toBe(initialName); // Should remain unchanged
    });
  });

  describe('User Search and Filtering', () => {
    beforeEach(async () => {
      // Create users with diverse profiles
      const profiles = [
        { name: 'Alice Johnson', email: generateUniqueEmail('alice'), role: 'ORGANIZER' },
        { name: 'Bob Smith', email: generateUniqueEmail('bob'), role: 'ATTENDEE' },
        { name: 'Charlie Brown', email: generateUniqueEmail('charlie'), role: 'ORGANIZER' },
        { name: 'Diana Prince', email: generateUniqueEmail('diana'), role: 'ATTENDEE' }
      ];

      for (const profile of profiles) {
        await createTestUser(profile);
      }
    });

    it('should search users by partial name match', async () => {
      const response = await request(app)
        .get('/api/users')
        .query({ search: 'john' });

      expect(response.status).toBe(200);
      expectSuccessResponse(response);
      
      const foundUser = response.body.data.find(u => u.name.toLowerCase().includes('johnson'));
      expect(foundUser).toBeDefined();
    });

    it('should combine search and role filter', async () => {
      const response = await request(app)
        .get('/api/users')
        .query({ 
          search: 'alice',
          role: 'ORGANIZER'
        });

      expect(response.status).toBe(200);
      expectSuccessResponse(response);
      
      response.body.data.forEach(user => {
        expect(user.role).toBe('ORGANIZER');
        expect(user.name.toLowerCase()).toContain('alice');
      });
    });

    it('should respect pagination with filters', async () => {
      const response = await request(app)
        .get('/api/users')
        .query({ 
          role: 'ATTENDEE',
          page: 1,
          limit: 1
        });

      expect(response.status).toBe(200);
      expectSuccessResponse(response);
      expect(response.body.data.length).toBeLessThanOrEqual(1);
      
      if (response.body.data.length > 0) {
        expect(response.body.data[0].role).toBe('ATTENDEE');
      }
    });
  });

  describe('Password Management', () => {
    let testUser;

    beforeEach(async () => {
      testUser = await createTestUser({
        email: generateUniqueEmail('password'),
        password: 'oldpassword123'
      });
    });

    it('should update password with valid current password', async () => {
      const passwordUpdate = {
        current_password: 'oldpassword123',
        new_password: 'newpassword456'
      };

      const response = await request(app)
        .put(`/api/users/${testUser.user.user_id}/password`)
        .set('Authorization', `Bearer ${testUser.token}`)
        .send(passwordUpdate);

      expect(response.status).toBe(200);
      expectSuccessResponse(response);

      // Verify login with new password
      const loginResponse = await request(app)
        .post('/api/auth/login')
        .send({
          email: testUser.user.email,
          password: 'newpassword456'
        });

      expect(loginResponse.status).toBe(200);
    });

    it('should reject password update with wrong current password', async () => {
      const passwordUpdate = {
        current_password: 'wrongpassword',
        new_password: 'newpassword456'
      };

      const response = await request(app)
        .put(`/api/users/${testUser.user.user_id}/password`)
        .set('Authorization', `Bearer ${testUser.token}`)
        .send(passwordUpdate);

      expect(response.status).toBe(400);
      expectErrorResponse(response, 400);
    });

    it('should reject weak new password', async () => {
      const passwordUpdate = {
        current_password: 'oldpassword123',
        new_password: '123' // Too weak
      };

      const response = await request(app)
        .put(`/api/users/${testUser.user.user_id}/password`)
        .set('Authorization', `Bearer ${testUser.token}`)
        .send(passwordUpdate);

      expectValidationError(response);
    });
  });
});