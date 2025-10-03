// Jest setup file
// Set NODE_ENV to test for proper CORS configuration
process.env.NODE_ENV = 'test';

// Set required environment variables for testing
process.env.JWT_SECRET = 'test-jwt-secret-key-for-testing';

// Mock console.log/error to reduce test output noise (optional)
// global.console = {
//   ...console,
//   log: jest.fn(),
//   error: jest.fn(),
// };