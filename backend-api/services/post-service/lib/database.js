const { PrismaClient } = require('@prisma/client');

// Create Prisma client for post-service
const prisma = new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['error', 'warn'] : ['error'],
  datasources: {
    db: {
      url: process.env.DATABASE_URL,
    },
  },
});

// Connect to database
async function connectDatabase() {
  try {
    await prisma.$connect();
    // Test the connection
    await prisma.$queryRaw`SELECT 1`;
    console.log('✅ Post Service: Database connected successfully');
    return true;
  } catch (error) {
    console.error('❌ Post Service: Database connection failed:', error);
    console.log('⚠️  Service will continue without database functionality');
    return false;
  }
}

// Graceful shutdown
async function disconnectDatabase() {
  try {
    await prisma.$disconnect();
    console.log('✅ Post Service: Database disconnected');
  } catch (error) {
    console.error('❌ Post Service: Database disconnect failed:', error);
  }
}

// Export prisma client and utilities
module.exports = {
  prisma,
  connectDatabase,
  disconnectDatabase,
  // For backward compatibility
  default: prisma
};

// Handle process termination
process.on('beforeExit', async () => {
  await disconnectDatabase();
});

process.on('SIGINT', async () => {
  await disconnectDatabase();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await disconnectDatabase();
  process.exit(0);
});