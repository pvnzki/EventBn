/**
 * Unit Test Environment Setup
 * 
 * This setup ensures unit tests never touch any real database
 */

// DO NOT load .env files - unit tests should be completely mocked
// require('dotenv').config({ path: '.env.test' });

// Set minimal environment for unit tests
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'unit-test-jwt-secret';

// Verify we're running unit tests only
if (!process.env.npm_config_argv || !JSON.stringify(process.env.npm_config_argv).includes('unit')) {
  console.log('🧪 Unit test environment initialized');
  console.log('📝 Note: All database calls are mocked for unit tests');
}

// Ensure no real database connection can be made
process.env.DATABASE_URL = 'unit-tests-should-not-connect-to-database';
process.env.DIRECT_URL = 'unit-tests-should-not-connect-to-database';

// Mock console to reduce noise during unit tests
global.console = {
  ...console,
  log: jest.fn(),
  info: jest.fn(),
  warn: console.warn, // Keep warnings
  error: console.error, // Keep errors
};