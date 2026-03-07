const jwt = require('jsonwebtoken');
require('dotenv').config();

// Create test JWT tokens for multi-user testing
const JWT_SECRET = process.env.JWT_SECRET;

if (!JWT_SECRET) {
  console.error('JWT_SECRET not found in environment variables');
  process.exit(1);
}

// Create tokens for test users
const userA = {
  userId: 124,
  email: 'organizer@eventbn.com',
  name: 'John Event Organizer'
};

const userB = {
  userId: 125,
  email: 'sarah.wilson@email.com',
  name: 'Sarah Wilson'
};

const tokenA = jwt.sign(userA, JWT_SECRET, { expiresIn: '24h' });
const tokenB = jwt.sign(userB, JWT_SECRET, { expiresIn: '24h' });

console.log('Generated JWT tokens for testing:');
console.log('');
console.log('User A Token:');
console.log(tokenA);
console.log('');
console.log('User B Token:');
console.log(tokenB);
console.log('');
console.log('Copy these tokens into your test-multi-user.js file');

// Verify the tokens work
try {
  const decodedA = jwt.verify(tokenA, JWT_SECRET);
  const decodedB = jwt.verify(tokenB, JWT_SECRET);
  
  console.log('Token verification successful:');
  console.log('User A decoded:', decodedA);
  console.log('User B decoded:', decodedB);
} catch (error) {
  console.error('Token verification failed:', error);
}