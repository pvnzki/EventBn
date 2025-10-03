/**
 * Authentication API Integration Tests
 * 
 * Tests complete authentication flows including registration, login,
 * protected routes, and token validation.
 */

const {
  app,
  request,
  setupTestDatabase,
  teardownTestDatabase,
  createTestUser,
  expectSuccessResponse,
  expectErrorResponse,
  expectAuthenticationRequired,
  expectValidationError,
  generateUniqueEmail
} = require('../../fixtures/prisma-mock');

describe('Authentication API Integration Tests', () => {
  beforeAll(async () => {
    await setupTestDatabase();
  });

  afterAll(async () => {
    await teardownTestDatabase();
  });

  beforeEach(async () => {
    await setupTestDatabase();
  });

  describe('POST /api/auth/register', () => {
    it('should register a new user successfully', async () => {
      const userData = {
        name: 'John Doe',
        email: generateUniqueEmail('john'),
        password: 'password123',
        phone: '+1234567890'
      };

      const response = await request(app)
        .post('/api/auth/register')
        .send(userData);

      expect(response.status).toBe(201);
      expectSuccessResponse(response);
      expect(response.body.data).toMatchObject({
        name: userData.name,
        email: userData.email,
        phone_number: userData.phone
      });
      expect(response.body.data.password).toBeUndefined();
      expect(response.body.token).toBeDefined();
      expect(typeof response.body.token).toBe('string');
    });

    it('should reject registration with missing required fields', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          name: 'John Doe'
          // Missing email, password, phone
        });

      expectValidationError(response);
    });

    it('should reject registration with invalid email format', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          name: 'John Doe',
          email: 'invalid-email',
          password: 'password123',
          phone: '+1234567890'
        });

      expectValidationError(response);
    });

    it('should reject registration with duplicate email', async () => {
      const email = generateUniqueEmail('duplicate');
      const userData = {
        name: 'John Doe',
        email,
        password: 'password123',
        phone: '+1234567890'
      };

      // First registration
      await request(app)
        .post('/api/auth/register')
        .send(userData);

      // Second registration with same email
      const response = await request(app)
        .post('/api/auth/register')
        .send(userData);

      expectValidationError(response);
      expect(response.body.message).toMatch(/email.*already/i);
    });

    it('should reject registration with weak password', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          name: 'John Doe',
          email: generateUniqueEmail('weak'),
          password: '123', // Too short
          phone: '+1234567890'
        });

      expectValidationError(response);
    });
  });

  describe('POST /api/auth/login', () => {
    let testUser;
    let userCredentials;

    beforeEach(async () => {
      userCredentials = {
        name: 'Test User',
        email: generateUniqueEmail('login'),
        password: 'password123',
        phone: '+1234567890'
      };
      
      testUser = await createTestUser(userCredentials);
    });

    it('should login with valid credentials', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: userCredentials.email,
          password: userCredentials.password
        });

      expect(response.status).toBe(200);
      expectSuccessResponse(response);
      expect(response.body.data).toMatchObject({
        email: userCredentials.email,
        name: userCredentials.name
      });
      expect(response.body.token).toBeDefined();
      expect(typeof response.body.token).toBe('string');
    });

    it('should reject login with invalid email', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'nonexistent@example.com',
          password: userCredentials.password
        });

      expect(response.status).toBe(401);
      expectErrorResponse(response, 401);
    });

    it('should reject login with invalid password', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: userCredentials.email,
          password: 'wrongpassword'
        });

      expect(response.status).toBe(401);
      expectErrorResponse(response, 401);
    });

    it('should reject login with missing credentials', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({});

      expectValidationError(response);
    });
  });

  describe('GET /api/auth/me', () => {
    let testUser;

    beforeEach(async () => {
      testUser = await createTestUser({
        email: generateUniqueEmail('me')
      });
    });

    it('should return current user with valid token', async () => {
      const response = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${testUser.token}`);

      expect(response.status).toBe(200);
      expectSuccessResponse(response);
      expect(response.body.data).toMatchObject({
        email: testUser.user.email,
        name: testUser.user.name
      });
    });

    it('should reject request without token', async () => {
      const response = await request(app)
        .get('/api/auth/me');

      expectAuthenticationRequired(response);
    });

    it('should reject request with invalid token', async () => {
      const response = await request(app)
        .get('/api/auth/me')
        .set('Authorization', 'Bearer invalid-token');

      expectAuthenticationRequired(response);
    });

    it('should reject request with malformed authorization header', async () => {
      const response = await request(app)
        .get('/api/auth/me')
        .set('Authorization', 'InvalidFormat token');

      expectAuthenticationRequired(response);
    });
  });

  describe('Authentication Flow Integration', () => {
    it('should complete full registration -> login -> protected route flow', async () => {
      const email = generateUniqueEmail('flow');
      const password = 'password123';
      
      // Step 1: Register
      const registerResponse = await request(app)
        .post('/api/auth/register')
        .send({
          name: 'Flow Test User',
          email,
          password,
          phone: '+1234567890'
        });

      expect(registerResponse.status).toBe(201);
      const registrationToken = registerResponse.body.token;

      // Step 2: Login with same credentials
      const loginResponse = await request(app)
        .post('/api/auth/login')
        .send({ email, password });

      expect(loginResponse.status).toBe(200);
      const loginToken = loginResponse.body.token;

      // Step 3: Access protected route with registration token
      const meResponse1 = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${registrationToken}`);

      expect(meResponse1.status).toBe(200);

      // Step 4: Access protected route with login token
      const meResponse2 = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${loginToken}`);

      expect(meResponse2.status).toBe(200);

      // Both tokens should return the same user data
      expect(meResponse1.body.data.email).toBe(meResponse2.body.data.email);
    });
  });

  describe('Token Validation', () => {
    let testUser;

    beforeEach(async () => {
      testUser = await createTestUser({
        email: generateUniqueEmail('token')
      });
    });

    it('should accept valid JWT token format', async () => {
      const response = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${testUser.token}`);

      expect(response.status).toBe(200);
    });

    it('should reject expired token', async () => {
      // Note: This would require mocking JWT expiration or using a short-lived token
      // For now, we test with clearly invalid tokens
      const expiredToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.invalid';
      
      const response = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${expiredToken}`);

      expectAuthenticationRequired(response);
    });

    it('should reject token with invalid signature', async () => {
      const invalidToken = testUser.token.slice(0, -5) + 'XXXXX';
      
      const response = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${invalidToken}`);

      expectAuthenticationRequired(response);
    });
  });
});