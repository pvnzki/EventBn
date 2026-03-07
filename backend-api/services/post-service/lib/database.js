const { PrismaClient } = require("@prisma/client");

let prisma;

function buildDatabaseUrl() {
  let url = process.env.DATABASE_URL || "";
  // Append ?pgbouncer=true if DISABLE_PREPARED_STMTS flag set and param not present
  if (
    process.env.PRISMA_CLIENT_DISABLE_PREPARED_STATEMENTS === "1" &&
    url &&
    !url.includes("pgbouncer=true")
  ) {
    url += (url.includes("?") ? "&" : "?") + "pgbouncer=true";
  }
  return url;
}

// Initialize Prisma Client with proper configuration
function initializePrisma() {
  if (!prisma) {
    const disablePrepared =
      process.env.PRISMA_CLIENT_DISABLE_PREPARED_STATEMENTS === "1";
    const dbUrl = buildDatabaseUrl();
    if (dbUrl && dbUrl !== process.env.DATABASE_URL) {
      console.log(
        "[POST-SERVICE][DB] Using modified DATABASE_URL with pgbouncer param appended"
      );
    }
    console.log(
      `[POST-SERVICE][DB] Prepared statements disabled: ${disablePrepared}`
    );
    prisma = new PrismaClient({
      log: ["query", "info", "warn", "error"],
      errorFormat: "pretty",
      datasources: {
        db: {
          url: dbUrl,
        },
      },
      // Disable prepared statements to avoid conflicts with other services
      __internal: {
        engine: {
          enableEngineDebugMode: false,
        },
      },
      ...(disablePrepared
        ? {
            __internal: {
              ...({} || {}),
              engine: { enableEngineDebugMode: false },
            },
          }
        : {}),
    });
    // Prisma currently uses prepared statements internally; the env var turns them off without extra client options.
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

// ── DB Keep-alive ─────────────────────────────────────────────────────
// NeonDB free-tier suspends compute after 5 min idle.
// Ping every 4 min to keep connections alive and avoid stale-pool errors.
const DB_KEEPALIVE_MS = 4 * 60 * 1000; // 4 minutes
let _keepAliveTimer = null;

function startDbKeepAlive() {
  if (_keepAliveTimer) return;
  const client = getPrismaClient();
  _keepAliveTimer = setInterval(async () => {
    try {
      await client.$queryRaw`SELECT 1`;
    } catch (e) {
      console.warn("[POST-DB] Keep-alive ping failed:", e.message);
      try { await client.$disconnect(); } catch (_) {}
    }
  }, DB_KEEPALIVE_MS);
  if (_keepAliveTimer.unref) _keepAliveTimer.unref();
}

startDbKeepAlive();

module.exports = {
  prisma: getPrismaClient(),
  connectDatabase,
  disconnectDatabase,
  initializePrisma,
};
