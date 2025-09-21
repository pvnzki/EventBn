const { PrismaClient } = require("@prisma/client");

let prisma;

// Initialize Prisma Client with proper configuration
function initializePrisma() {
  if (!prisma) {
    prisma = new PrismaClient({
      log: ["query", "info", "warn", "error"],
      errorFormat: "pretty",
      datasources: {
        db: {
          url: process.env.DATABASE_URL,
        },
      },
      // Disable prepared statements to avoid conflicts with other services
      __internal: {
        engine: {
          enableEngineDebugMode: false,
        },
      },
    });
  }
  return prisma;
}

// Connect to database with retry logic
async function connectDatabase(retryAttempts = 5, delayMs = 3000) {
  if (!prisma) {
    prisma = initializePrisma();
  }

  for (let attempt = 1; attempt <= retryAttempts; attempt++) {
    try {
      console.log(
        `🔄 Database connection attempt ${attempt}/${retryAttempts}...`
      );

      // Test the connection
      await prisma.$connect();
      console.log("✓ Database connected successfully");
      return true;
    } catch (error) {
      console.error(
        `✗ Database connection attempt ${attempt} failed:`,
        error.message
      );

      if (attempt === retryAttempts) {
        console.error("❌ All database connection attempts failed");
        return false;
      }

      console.log(`⏳ Waiting ${delayMs}ms before retry...`);
      await new Promise((resolve) => setTimeout(resolve, delayMs));

      // Increase delay for next attempt (exponential backoff)
      delayMs = Math.min(delayMs * 1.5, 10000);
    }
  }

  return false;
}

// Disconnect from database
async function disconnectDatabase() {
  try {
    if (prisma) {
      await prisma.$disconnect();
      console.log("✓ Database disconnected successfully");
    }
  } catch (error) {
    console.error("✗ Database disconnect failed:", error);
  }
}

// Get Prisma client instance
function getPrismaClient() {
  if (!prisma) {
    prisma = initializePrisma();
  }
  return prisma;
}

module.exports = {
  prisma: getPrismaClient(),
  connectDatabase,
  disconnectDatabase,
  initializePrisma,
};
