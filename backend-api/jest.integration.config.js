/**
 * Jest Configuration for Integration Tests
 * 
 * Separate configuration for integration tests with longer timeouts
 * and database setup requirements.
 */

module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/tests/integration/**/*.test.js'],
  setupFilesAfterEnv: ['<rootDir>/tests/integration/jest.setup.js'],
  testTimeout: 30000, // 30 seconds for integration tests
  verbose: true,
  collectCoverage: false, // Integration tests focus on behavior, not coverage
  maxWorkers: 1, // Run integration tests sequentially to avoid database conflicts
  forceExit: true,
  detectOpenHandles: true,
  
  // Global setup and teardown
  globalSetup: '<rootDir>/tests/integration/global-setup.js',
  globalTeardown: '<rootDir>/tests/integration/global-teardown.js',
  
  // Test environment options
  testEnvironmentOptions: {
    NODE_ENV: 'test'
  },
  
  // Module paths and mocking
  moduleDirectories: ['node_modules', '<rootDir>'],
  
  // Coverage settings (if needed)
  coveragePathIgnorePatterns: [
    '/node_modules/',
    '/tests/',
    '/coverage/'
  ],
  
  // Reporter options
  reporters: [
    'default'
  ]
};