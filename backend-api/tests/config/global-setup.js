/**
 * Global Setup for Integration Tests
 * 
 * Runs once before all integration tests.
 */

const { execSync } = require('child_process');

module.exports = async () => {
  console.log('🔧 Setting up integration test environment...');
  
  // Set test environment
  process.env.NODE_ENV = 'test';
  
  try {
    // Ensure test database exists and is clean
    console.log('📦 Preparing test database...');
    
    // Note: In a real setup, you might want to:
    // 1. Create a separate test database
    // 2. Run migrations
    // 3. Set up test data seeds
    
    // For now, we'll rely on the setup in individual tests
    // execSync('npx prisma migrate deploy', { stdio: 'inherit' });
    // execSync('npx prisma db seed', { stdio: 'inherit' });
    
    console.log('✅ Integration test environment ready');
  } catch (error) {
    console.error('❌ Failed to setup test environment:', error);
    process.exit(1);
  }
};