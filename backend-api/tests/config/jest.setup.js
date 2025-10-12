process.env.NODE_ENV = 'test';

// Place for shared per-test setup for DB-backed suites if needed
/**
 * Jest Setup for Integration Tests
 * 
 * Global setup that runs before each test file.
 */

// Set test environment variables
process.env.NODE_ENV = 'test';
// Respect values loaded from .env.test by env.load.js; only set fallbacks if missing
if (!process.env.JWT_SECRET) {
  process.env.JWT_SECRET = 'test-jwt-secret-key-for-integration-tests';
}
// Do NOT override DATABASE_URL if already provided via .env.test
// This prevents accidental connection to the wrong DB/port/credentials
if (!process.env.DATABASE_URL) {
  process.env.DATABASE_URL = process.env.TEST_DATABASE_URL || 'postgresql://postgres:postgres@localhost:5433/eventbn_test';
}

// Increase timeout for all tests
jest.setTimeout(30000);

// Global error handler for unhandled promises
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

// Suppress console warnings during tests (optional)
const originalConsoleWarn = console.warn;
console.warn = (...args) => {
  // Suppress specific warnings if needed
  if (args[0] && args[0].includes && args[0].includes('deprecation')) {
    return;
  }
  originalConsoleWarn.apply(console, args);
};

// Mock environment-specific modules if needed
jest.mock('../../lib/cloudinary', () => ({
  uploader: {
    upload: jest.fn().mockResolvedValue({
      public_id: 'test-image-id',
      secure_url: 'https://test.cloudinary.com/test-image.jpg'
    })
  }
}));

// Mock email service if exists
jest.mock('../../services/email', () => ({
  sendEmail: jest.fn().mockResolvedValue({ success: true }),
  sendWelcomeEmail: jest.fn().mockResolvedValue({ success: true }),
  sendBookingConfirmation: jest.fn().mockResolvedValue({ success: true })
}), { virtual: true });

// Mock payment service if exists
jest.mock('../../services/payment', () => ({
  processPayment: jest.fn().mockResolvedValue({
    success: true,
    transaction_id: 'test-transaction-123',
    amount: 100
  }),
  refundPayment: jest.fn().mockResolvedValue({ success: true })
}), { virtual: true });