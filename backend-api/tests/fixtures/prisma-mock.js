/**
 * Integration Test Setup (In-Memory)
 * 
 * Sets up in-memory testing without requiring a real database connection.
 * This demonstrates the integration testing concept while being self-contained.
 */

const request = require('supertest');
const app = require('../../server');

// Mock Prisma for integration tests
jest.mock('../../lib/database', () => ({
  $queryRaw: jest.fn(),
  $executeRawUnsafe: jest.fn(),
  $disconnect: jest.fn(),
  user: {
    create: jest.fn(),
    findUnique: jest.fn(),
    findMany: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
  },
  event: {
    create: jest.fn(),
    findUnique: jest.fn(),
    findMany: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
  },
  organization: {
    create: jest.fn(),
    findUnique: jest.fn(),
    findMany: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
  },
  ticket: {
    create: jest.fn(),
    findUnique: jest.fn(),
    findMany: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
  },
  booking: {
    create: jest.fn(),
    findUnique: jest.fn(),
    findMany: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
  }
}));

// In-memory data store for testing
const testData = {
  users: new Map(),
  events: new Map(),
  organizations: new Map(),
  tickets: new Map(),
  bookings: new Map(),
  nextId: 1
};

const setupTestDatabase = async () => {
  // Clear in-memory data
  testData.users.clear();
  testData.events.clear();
  testData.organizations.clear();
  testData.tickets.clear();
  testData.bookings.clear();
  testData.nextId = 1;
  
  // Setup mock implementations
  const prisma = require('../../lib/database');
  
  // Mock user operations
  prisma.user.create.mockImplementation(async ({ data, select }) => {
    const user = {
      user_id: testData.nextId++,
      ...data,
      email: data.email ? data.email.toLowerCase().trim() : data.email, // Normalize email like the real service
      // Keep the password_hash as passed from the auth service (already hashed)
      created_at: new Date(),
      updated_at: new Date()
    };
    testData.users.set(user.user_id, user);
    
    // If select is specified, return only selected fields
    if (select) {
      const selectedUser = {};
      Object.keys(select).forEach(key => {
        if (select[key] && user[key] !== undefined) {
          selectedUser[key] = user[key];
        }
      });
      return selectedUser;
    }
    
    // Otherwise return all fields except password_hash
    const { password_hash, ...userWithoutPassword } = user;
    return userWithoutPassword;
  });

  prisma.user.findUnique.mockImplementation(async ({ where }) => {
    if (where.email) {
      const normalizedEmail = where.email.toLowerCase().trim();
      const foundUser = Array.from(testData.users.values()).find(u => 
        u.email && u.email.toLowerCase().trim() === normalizedEmail
      );
      return foundUser || null;
    }
    if (where.user_id) {
      return testData.users.get(where.user_id) || null;
    }
    return null;
  });

  prisma.user.findMany.mockImplementation(async ({ where = {}, skip = 0, take = 10 }) => {
    let users = Array.from(testData.users.values());
    
    if (where.role) {
      users = users.filter(u => u.role === where.role);
    }
    
    return users.slice(skip, skip + take);
  });

  // Mock event operations
  prisma.event.create.mockImplementation(async ({ data }) => {
    const event = {
      event_id: testData.nextId++,
      ...data,
      created_at: new Date(),
      updated_at: new Date()
    };
    testData.events.set(event.event_id, event);
    return event;
  });

  prisma.event.findUnique.mockImplementation(async ({ where }) => {
    return testData.events.get(where.event_id) || null;
  });

  prisma.event.findMany.mockImplementation(async ({ where = {}, skip = 0, take = 10 }) => {
    let events = Array.from(testData.events.values());
    
    if (where.status) {
      events = events.filter(e => e.status === where.status);
    }
    if (where.event_type) {
      events = events.filter(e => e.event_type === where.event_type);
    }
    
    return events.slice(skip, skip + take);
  });

  // Mock database health check
  prisma.$queryRaw.mockResolvedValue([{ result: 1 }]);
  prisma.$executeRawUnsafe.mockResolvedValue();
};

const teardownTestDatabase = async () => {
  const prisma = require('../../lib/database');
  
  // Clear all mock calls and reset implementations
  jest.clearAllMocks();
  
  // Disconnect from database
  if (prisma && typeof prisma.$disconnect === 'function') {
    await prisma.$disconnect();
  }
  
  // Clear in-memory data
  testData.users.clear();
  testData.events.clear();
  testData.organizations.clear();
  testData.tickets.clear();
  testData.bookings.clear();
  testData.nextId = 1;
};

// Authentication helpers
const createTestUser = async (userData = {}) => {
  const defaultUser = {
    name: 'Test User',
    email: 'test@example.com',
    password: 'password123',
    phone: '+1234567890',
    role: 'ATTENDEE',
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
    title: 'Test Event',
    description: 'A test event for integration testing',
    start_time: '2024-12-01T10:00:00Z',
    end_time: '2024-12-01T18:00:00Z',
    location: 'Test Venue',
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
    title: `Test Event ${Date.now()}`,
    description: 'Integration test event',
    start_time: baseDate.toISOString(),
    end_time: new Date(baseDate.getTime() + 8 * 60 * 60 * 1000).toISOString(), // 8 hours later
    location: 'Test Venue',
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
  expectSuccessResponse,
  expectErrorResponse,
  expectAuthenticationRequired,
  expectValidationError,
  generateUniqueEmail,
  generateTestEventData,
  testData
};