/**
 * For a detailed explanation regarding each configuration property, visit:
 * https://jestjs.io/docs/configuration
 */

module.exports = {
  clearMocks: true,
  collectCoverage: true,
  coverageDirectory: "coverage",
  coverageProvider: "v8",
  forceExit: true,
  detectOpenHandles: true,
  testTimeout: 30000,
  testEnvironment: "node",
  setupFilesAfterEnv: ["<rootDir>/tests/config/test-env.js"],
  
  // Test patterns for different test types
  testMatch: [
    "<rootDir>/tests/**/*.test.js"
  ],
  
  // Test environment setup for integration tests
  globalSetup: "<rootDir>/tests/config/global-setup.js",
  globalTeardown: "<rootDir>/tests/config/global-teardown.js",
  
  // Coverage settings
  collectCoverageFrom: [
    "**/*.js",
    "!**/node_modules/**",
    "!**/tests/**",
    "!**/coverage/**",
    "!jest.config.js"
  ]
};
