// Jest setup file - ensures safe test environment
require('dotenv').config({ path: '.env.test' });

// Verify we're in test mode
if (process.env.NODE_ENV !== 'test') {
  console.error('❌ SAFETY CHECK FAILED: NODE_ENV is not "test"');
  console.error('This could result in data loss in your development/production database!');
  process.exit(1);
}

// Verify test database is configured
if (process.env.DATABASE_URL === 'PLEASE_SET_UP_A_SEPARATE_TEST_DATABASE' || 
    !process.env.DATABASE_URL || 
    process.env.DATABASE_URL.includes('supabase.com')) {
  console.error('❌ SAFETY CHECK FAILED: Test database not properly configured');
  console.error('You must set up a separate test database to avoid data loss');
  console.error('Current DATABASE_URL:', process.env.DATABASE_URL);
  process.exit(1);
}

// Set NODE_ENV to test for proper CORS configuration
process.env.NODE_ENV = 'test';

// Set required environment variables for testing
process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-jwt-secret-key-for-testing';

console.log('✅ Test environment safety checks passed');
console.log('📦 Using test database:', process.env.DATABASE_URL);

// Mock console.log/error to reduce test output noise (optional)
// global.console = {
//   ...console,
//   log: jest.fn(),
//   error: jest.fn(),
// };