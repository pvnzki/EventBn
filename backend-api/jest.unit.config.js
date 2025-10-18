/**
 * Jest Configuration for Unit Tests Only
 * 
 * This config ensures unit tests are completely isolated from the database
 */

module.exports = {
  clearMocks: true,
  testEnvironment: "node",
  setupFilesAfterEnv: ["<rootDir>/tests/config/unit-test-env.js"],
  
  // Only run unit tests
  testMatch: [
    "<rootDir>/tests/unit/**/*.test.js"
  ],
  
  // Ignore integration tests completely
  testPathIgnorePatterns: [
    "<rootDir>/tests/integration/",
    "<rootDir>/node_modules/"
  ],
  
  // Coverage settings for unit tests only
  collectCoverageFrom: [
    "controllers/**/*.js",
    "middleware/**/*.js", 
    "services/**/*.js",
    "lib/**/*.js",
    "!**/node_modules/**",
    "!**/tests/**"
  ],
  
  // Faster execution for unit tests
  testTimeout: 10000,
  detectOpenHandles: false,
  forceExit: false
};