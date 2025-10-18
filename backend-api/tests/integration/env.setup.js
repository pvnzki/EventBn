/**
 * Environment Setup for Integration Tests
 * 
 * This file ensures that integration tests run with the correct environment
 * configuration and use a separate test database.
 */

const path = require('path');
const dotenv = require('dotenv');

// Force NODE_ENV to 'test' for integration tests
process.env.NODE_ENV = 'test';

// Load test environment variables from .env.test
const testEnvPath = path.join(__dirname, '../../.env.test');
const result = dotenv.config({ path: testEnvPath });

if (result.error) {
  console.error(`
❌ CRITICAL ERROR: Failed to load test environment configuration!

Could not load .env.test file from: ${testEnvPath}

This is required to prevent integration tests from using your development database.
Please ensure .env.test exists and contains a separate test database configuration.
  `);
  process.exit(1);
}

// Validate that test database URL is configured
const testDbUrl = process.env.DATABASE_URL;
if (!testDbUrl || testDbUrl.includes('PLEASE_SET_UP')) {
  console.error(`
❌ CRITICAL ERROR: Test database not configured!

Your .env.test file contains placeholder database URLs. This means integration 
tests cannot run safely without risking data loss in your development database.

Please configure a separate test database in .env.test before running integration tests.

Options:
1. Set up a local PostgreSQL database for testing
2. Create a separate Supabase project for testing
3. Use SQLite for lightweight testing

Current DATABASE_URL: ${testDbUrl}
  `);
  process.exit(1);
}

console.log(`
✅ Integration test environment configured
📍 NODE_ENV: ${process.env.NODE_ENV}
🗄️  Test Database: ${testDbUrl.substring(0, 50)}...
`);