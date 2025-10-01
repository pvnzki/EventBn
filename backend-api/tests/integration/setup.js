/**
 * Integration Test Setup
 * 
 * Sets up test database, authentication helpers, and common utilities
 * for API integration testing.
 */

const request = require('supertest');
const app = require('../../server');
const prisma = require('../../lib/database');

// Test database setup
const setupTestDatabase = async () => {
  // CRITICAL SAFETY CHECK: Only allow database truncation in test environment
  if (process.env.NODE_ENV !== 'test') {
    throw new Error(`
❌ CRITICAL ERROR: Attempted to truncate database in ${process.env.NODE_ENV} environment!
This operation will DELETE ALL DATA from your database.

To run integration tests safely:
1. Set NODE_ENV=test
2. Configure a separate test database in .env.test
3. Never run integration tests against production/development databases

Current DATABASE_URL: ${process.env.DATABASE_URL?.substring(0, 50)}...
    `);
  }

  // Additional safety check: Ensure we're not using production database URLs
  const dbUrl = process.env.DATABASE_URL || '';
  if (dbUrl.includes('supabase.com') && !dbUrl.includes('test')) {
    console.warn(`
⚠️  WARNING: You appear to be using a Supabase database for testing.
Make sure this is a dedicated TEST database, not your production database!
Current database: ${dbUrl.substring(0, 50)}...
    `);
  }

  // Clean up database before tests
  const tablenames = await prisma.$queryRaw`
    SELECT tablename FROM pg_tables WHERE schemaname='public'
  `;
  
  const tables = tablenames
    .map(({ tablename }) => tablename)
    .filter(name => name !== '_prisma_migrations')
    .map(name => `"public"."${name}"`)
    .join(', ');

  if (tables.length > 0) {
    try {
      console.log(`🧹 Cleaning test database tables: ${tables}`);
      await prisma.$executeRawUnsafe(`TRUNCATE TABLE ${tables} CASCADE;`);
      console.log('✅ Test database cleaned successfully');
    } catch (error) {
      console.log('❌ Error cleaning database:', error.message);
      throw error;
    }
  }
};

const teardownTestDatabase = async () => {
  await prisma.$disconnect();
};

// Authentication helpers
const createTestUser = async (userData = {}) => {
  const defaultUser = {
    name: 'Test User',
    email: 'test@example.com',
    password: 'password123',
    phone: '+1234567890',
    ...userData
  };

  const response = await request(app)
    .post('/api/auth/register')
    .send(defaultUser);

  return {
    user: response.body.data,
    token: response.body.token,
    response
  };
};

const createTestOrganizer = async (userData = {}) => {
  const organizerData = {
    name: 'Test Organizer',
    email: 'organizer@example.com',
    password: 'password123',
    phone: '+1234567890',
    role: 'ORGANIZER',
    ...userData
  };

  return await createTestUser(organizerData);
};

const createTestEvent = async (token, eventData = {}) => {
  const defaultEvent = {
    name: 'Test Event',
    description: 'A test event for integration testing',
    start_date: '2024-12-01T10:00:00Z',
    end_date: '2024-12-01T18:00:00Z',
    venue: 'Test Venue',
    address: '123 Test Street, Test City',
    event_type: 'CONFERENCE',
    status: 'ACTIVE',
    max_attendees: 100,
    ticket_types: [
      {
        type: 'General',
        price: 50,
        available_quantity: 80
      }
    ],
    seat_map: [],
    ...eventData
  };

  const response = await request(app)
    .post('/api/events')
    .set('Authorization', `Bearer ${token}`)
    .send(defaultEvent);

  return {
    event: response.body.data,
    response
  };
};

const createTestOrganization = async (token, orgData = {}) => {
  const defaultOrg = {
    name: 'Test Organization',
    description: 'A test organization',
    website: 'https://test.com',
    contact_email: 'contact@test.com',
    contact_phone: '+1234567890',
    ...orgData
  };

  const response = await request(app)
    .post('/api/organizations')
    .set('Authorization', `Bearer ${token}`)
    .send(defaultOrg);

  return {
    organization: response.body.data,
    response
  };
};

// Common test assertions
const expectSuccessResponse = (response) => {
  expect(response.body.success).toBe(true);
  expect(response.body.data).toBeDefined();
};

const expectErrorResponse = (response, statusCode) => {
  expect(response.status).toBe(statusCode);
  expect(response.body.success).toBe(false);
  expect(response.body.message).toBeDefined();
};

const expectAuthenticationRequired = (response) => {
  expectErrorResponse(response, 401);
  expect(response.body.message).toMatch(/token|auth|unauthorized/i);
};

const expectValidationError = (response) => {
  expectErrorResponse(response, 400);
};

// Test data generators
const generateUniqueEmail = (prefix = 'test') => {
  return `${prefix}${Date.now()}${Math.random().toString(36).substr(2, 5)}@example.com`;
};

const generateTestEventData = (overrides = {}) => {
  const baseDate = new Date();
  baseDate.setDate(baseDate.getDate() + 30); // 30 days from now

  return {
    name: `Test Event ${Date.now()}`,
    description: 'Integration test event',
    start_date: baseDate.toISOString(),
    end_date: new Date(baseDate.getTime() + 8 * 60 * 60 * 1000).toISOString(), // 8 hours later
    venue: 'Test Venue',
    address: '123 Test Street',
    event_type: 'CONFERENCE',
    status: 'ACTIVE',
    max_attendees: 100,
    ticket_types: [
      {
        type: 'General',
        price: 50,
        available_quantity: 80
      }
    ],
    seat_map: [],
    ...overrides
  };
};

module.exports = {
  app,
  request,
  setupTestDatabase,
  teardownTestDatabase,
  createTestUser,
  createTestOrganizer,
  createTestEvent,
  createTestOrganization,
  expectSuccessResponse,
  expectErrorResponse,
  expectAuthenticationRequired,
  expectValidationError,
  generateUniqueEmail,
  generateTestEventData
};