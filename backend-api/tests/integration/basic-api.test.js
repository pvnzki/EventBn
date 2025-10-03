/**
 * Basic Authentication API Integration Tests
 * 
 * Simplified integration tests that demonstrate API testing concepts
 * without requiring external database setup.
 */

const {
  app,
  request,
  setupTestDatabase,
  teardownTestDatabase,
  expectSuccessResponse,
  expectErrorResponse,
  expectAuthenticationRequired,
  expectValidationError,
  generateUniqueEmail
} = require('../fixtures/prisma-mock');

describe('Basic API Integration Tests', () => {
  beforeAll(async () => {
    await setupTestDatabase();
  });

  afterAll(async () => {
    await teardownTestDatabase();
    // Force Jest to exit if needed
    if (global.gc) {
      global.gc();
    }
  });

  // Remove the global beforeEach that was clearing data

  describe('Health Check', () => {
    it('should return server health status', async () => {
      const response = await request(app)
        .get('/health');

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('OK');
      expect(response.body.environment).toBe('test');
      expect(response.body.database).toBe('Connected');
    });

    it('should return basic server info', async () => {
      const response = await request(app)
        .get('/');

      expect(response.status).toBe(200);
      expect(response.body.message).toBe('EventBn API Server');
      expect(response.body.environment).toBe('test');
    });
  });

  describe('Authentication Endpoints', () => {
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
          phone_number: userData.phone  // Database field is phone_number
        });
        expect(response.body.data.password).toBeUndefined();
        expect(response.body.token).toBeDefined();
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
    });

    describe('POST /api/auth/login', () => {
      let testUserEmail;
      let testUserPassword;

      beforeEach(async () => {
        testUserEmail = generateUniqueEmail('login');
        testUserPassword = 'password123';
        
        await request(app)
          .post('/api/auth/register')
          .send({
            name: 'Test User',
            email: testUserEmail,
            password: testUserPassword,
            phone: '+1234567890'
          });
      });

      it('should login with valid credentials', async () => {
        const response = await request(app)
          .post('/api/auth/login')
          .send({
            email: testUserEmail,
            password: testUserPassword
          });

        expect(response.status).toBe(200);
        expectSuccessResponse(response);
        expect(response.body.data.email).toBe(testUserEmail);
        expect(response.body.token).toBeDefined();
      });

      it('should reject login with invalid email', async () => {
        const response = await request(app)
          .post('/api/auth/login')
          .send({
            email: 'nonexistent@example.com',
            password: testUserPassword
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
      let userToken;

      beforeEach(async () => {
        const registerResponse = await request(app)
          .post('/api/auth/register')
          .send({
            name: 'Me Test User',
            email: generateUniqueEmail('me'),
            password: 'password123',
            phone: '+1234567890'
          });
        
        userToken = registerResponse.body.token;
      });

      it('should return current user with valid token', async () => {
        const response = await request(app)
          .get('/api/auth/me')
          .set('Authorization', `Bearer ${userToken}`);

        expect(response.status).toBe(200);
        expectSuccessResponse(response);
        expect(response.body.data.name).toBe('Me Test User');
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
    });
  });

  describe('Events Endpoints', () => {
    describe('GET /api/events', () => {
      it('should return events list', async () => {
        const response = await request(app)
          .get('/api/events');

        expect(response.status).toBe(200);
        expectSuccessResponse(response);
        expect(Array.isArray(response.body.data)).toBe(true);
      });

      it('should handle pagination parameters', async () => {
        const response = await request(app)
          .get('/api/events')
          .query({ 
            page: 1, 
            limit: 5 
          });

        expect(response.status).toBe(200);
        expectSuccessResponse(response);
        expect(response.body.data.length).toBeLessThanOrEqual(5);
      });

      it('should filter events by event_type', async () => {
        const response = await request(app)
          .get('/api/events')
          .query({ event_type: 'CONFERENCE' });

        expect(response.status).toBe(200);
        expectSuccessResponse(response);
      });
    });

    describe('GET /api/events/:id', () => {
      it('should return 404 for non-existent event', async () => {
        const response = await request(app)
          .get('/api/events/999999');

        expect(response.status).toBe(404);
        expectErrorResponse(response, 404);
      });
    });

    describe('POST /api/events', () => {
      let organizerToken;

      beforeEach(async () => {
        const registerResponse = await request(app)
          .post('/api/auth/register')
          .send({
            name: 'Test Organizer',
            email: generateUniqueEmail('organizer'),
            password: 'password123',
            phone: '+1234567890',
            role: 'ORGANIZER'
          });
        
        organizerToken = registerResponse.body.token;
      });

      it('should reject event creation without authentication', async () => {
        const eventData = {
          name: 'Test Event',
          description: 'Test Description',
          start_date: '2024-12-01T10:00:00Z',
          end_date: '2024-12-01T18:00:00Z',
          venue: 'Test Venue',
          event_type: 'CONFERENCE'
        };

        const response = await request(app)
          .post('/api/events')
          .send(eventData);

        expectAuthenticationRequired(response);
      });

      it('should reject event creation with missing required fields', async () => {
        const response = await request(app)
          .post('/api/events')
          .set('Authorization', `Bearer ${organizerToken}`)
          .send({
            name: 'Incomplete Event'
            // Missing other required fields
          });

        expectValidationError(response);
      });
    });
  });

  describe('Error Handling', () => {
    it('should return 404 for non-existent routes', async () => {
      const response = await request(app)
        .get('/api/nonexistent');

      expect(response.status).toBe(404);
      expect(response.body.error).toBe('Route not found');
    });

    it('should handle invalid JSON in request body', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send('invalid json')
        .set('Content-Type', 'application/json');

      expect(response.status).toBe(400);
    });
  });

  describe('CORS and Headers', () => {
    it('should include CORS headers', async () => {
      const response = await request(app)
        .get('/health')
        .set('Origin', 'http://localhost:3000'); // Set origin to trigger CORS

      expect(response.headers['access-control-allow-origin']).toBeDefined();
    });

    it('should handle OPTIONS requests', async () => {
      const response = await request(app)
        .options('/api/auth/register');

      expect(response.status).toBe(204);
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
});