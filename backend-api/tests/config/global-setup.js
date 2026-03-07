/**
 * Global Setup for Integration Tests
 * 
 * Runs once before all integration tests.
 */

const { execSync } = require('child_process');
const path = require('path');
const dotenv = require('dotenv');

module.exports = async () => {
  console.log('🔧 Setting up integration test environment...');
  
  // Set test environment
  process.env.NODE_ENV = 'test';
  // Load test env vars for Prisma and server
  const testEnvPath = path.join(__dirname, '../../.env.test');
  dotenv.config({ path: testEnvPath });
  
  try {
    // Ensure test database exists and is clean
    console.log('📦 Preparing test database...');
    
    // Sync Prisma schema for DB-backed tests
    // Using db push to keep test setup fast and simple
    execSync('npx prisma db push --force-reset', { stdio: 'inherit' });
    
    console.log('✅ Integration test environment ready');
  } catch (error) {
    console.error('❌ Failed to setup test environment:', error);
    process.exit(1);
  }
};