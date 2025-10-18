// Load environment variables from .env.test for DB-backed Jest runs
const path = require('path');
const dotenv = require('dotenv');

const testEnvPath = path.join(__dirname, '../../.env.test');
const result = dotenv.config({ path: testEnvPath });
if (result.error) {
  // Not fatal; tests may inject via process.env elsewhere
  console.warn('Warning: Failed to load .env.test in env.load.js');
}

process.env.NODE_ENV = process.env.NODE_ENV || 'test';
