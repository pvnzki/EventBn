/**
 * Jest Configuration for DB-Backed Integration Tests
 */

module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/tests/integration-db/**/*.test.js'],
  setupFiles: ['<rootDir>/tests/config/env.load.js'],
  setupFilesAfterEnv: ['<rootDir>/tests/config/jest.setup.js'],
  testTimeout: 60000,
  verbose: true,
  maxWorkers: 1,
  forceExit: true,
  detectOpenHandles: true,
  globalSetup: '<rootDir>/tests/config/global-setup.js',
  globalTeardown: '<rootDir>/tests/config/global-teardown.js',
  moduleDirectories: ['node_modules', '<rootDir>']
};
