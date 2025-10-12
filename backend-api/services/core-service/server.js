require("dotenv").config({ path: "../../.env" });

const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const compression = require("compression");
const rateLimit = require("express-rate-limit");
const path = require("path");

// Database for core-service (local Prisma client)
const prisma = require("./lib/database");
// const coreService = require("./index"); // Temporarily disabled to avoid database conflicts

// Redis
// const { connectRedis } = require("../../lib/redis"); // Disabled for now

// RabbitMQ
const {
  connectToRabbitMQ,
  publishUserEvent,
  getRabbitMQHealth,
} = require("./utils/rabbitmq-publisher");
const {
  startConsumer: startRabbitMQConsumer,
} = require("./utils/rabbitmq-consumer");

// Handle BigInt serialization
BigInt.prototype.toJSON = function () {
  return Number(this);
};

const app = express();

// Security middleware
app.use(
  helmet({
    contentSecurityPolicy: false, // Disable for development
  })
);
app.use(compression());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // limit each IP to 1000 requests per windowMs
  message: "Too many requests from this IP, please try again later.",
});
app.use(limiter);

// Body parsing
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ limit: "10mb", extended: true }));

// CORS Configuration (enhanced for development diagnostics + broader dev ports)
const explicitOrigins = (process.env.CORE_SERVICE_CORS_ORIGINS || "")
  .split(",")
  .map((o) => o.trim())
  .filter(Boolean);

// Default dev origins if none provided
if (explicitOrigins.length === 0) {
  explicitOrigins.push(
    "http://localhost:3000",
    "http://localhost:3001",
    "http://localhost:3002",
    "http://localhost:3003",
    "http://localhost:5173",
    "http://localhost:5174",
    "http://localhost:8080"
  );
}

const LOCALHOST_REGEX = /^https?:\/\/localhost(?::\d+)?$/i;

// For quick troubleshooting you can set CORE_SERVICE_ALLOW_ALL_CORS=true (dev only!)
const allowAllDev = process.env.CORE_SERVICE_ALLOW_ALL_CORS === "true";

const corsOptions = {
  origin: (origin, callback) => {
    if (allowAllDev) {
      if (origin) console.log(`[CORS][DEV-WILDCARD] Allowing ${origin}`);
      return callback(null, true);
    }

    // Allow no-origin requests (mobile apps, curl, Postman)
    if (!origin) return callback(null, true);

    if (LOCALHOST_REGEX.test(origin) || explicitOrigins.includes(origin)) {
      console.log(`[CORS] ✔ Allowed origin: ${origin}`);
      return callback(null, true);
    }

    console.warn(`[CORS] ✖ Blocked origin: ${origin}`);
    return callback(new Error("Not allowed by CORS"));
  },
  credentials: true,
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  allowedHeaders: [
    "Content-Type",
    "Authorization",
    "X-Service-Key",
    "X-Requested-With",
    "Accept",
    "Origin",
  ],
  exposedHeaders: ["X-Service-Name", "X-Service-Version"],
  maxAge: 86400, // 24h to reduce preflights in dev
  optionsSuccessStatus: 204,
  preflightContinue: false,
};

// Attach CORS early
app.use(cors(corsOptions));
app.options("*", cors(corsOptions));

// Safety middleware: ensure any error still returns an ACAO header in dev (best-effort)
app.use((req, res, next) => {
  const origin = req.headers.origin;
  if (allowAllDev && origin && !res.headersSent) {
    res.setHeader("Access-Control-Allow-Origin", origin);
    res.setHeader(
      "Access-Control-Allow-Headers",
      corsOptions.allowedHeaders.join(", ")
    );
    res.setHeader(
      "Access-Control-Allow-Methods",
      corsOptions.methods.join(", ")
    );
    res.setHeader("Access-Control-Allow-Credentials", "true");
  }
  next();
});

// Service identification middleware
app.use((req, res, next) => {
  res.setHeader("X-Service-Name", "core-service");
  res.setHeader("X-Service-Version", "1.0.0");
  next();
});

// ANALYTICS TEST ROUTE - MUST BE BEFORE OTHER ROUTE IMPORTS
app.get("/test-analytics/:organizationId", async (req, res) => {
  try {
    const organizationId = parseInt(req.params.organizationId);
    console.log('=== DIRECT ANALYTICS TEST FOR ORG:', organizationId, '===');
    
    const events = await prisma.event.findMany({
      where: { organization_id: organizationId },
      select: { event_id: true, title: true }
    });
    console.log('EVENTS FOUND:', events.length, events);
    
    const eventIds = events.map(e => e.event_id);
    const ticketCount = await prisma.ticket_purchase.count({
      where: { event_id: { in: eventIds } }
    });
    console.log('TICKET COUNT:', ticketCount);
    
    const result = {
      totalEvents: events.length,
      ticketsSold: ticketCount,
      totalRevenue: 0,
      totalAttendees: ticketCount,
      conversionRate: 0,
      avgTicketPrice: 0,
      revenueGrowth: 0,
      attendeeGrowth: 0
    };
    
    console.log('FINAL RESULT:', result);
    res.json({ success: true, data: result, debug: true });
  } catch (error) {
    console.error('Direct test error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Import route handlers
const apiRoutes = require("./routes/api");
const authRoutes = require("./routes/auth");
const internalRoutes = require("./routes/internal");

// Health check - Always returns 200 for service readiness (no DB check for testing)
app.get("/health", (req, res) => {
  console.log("[CORE-SERVICE] Health check requested");

  // Always return 200 OK for service readiness, regardless of database status
  res.status(200).json({
    service: "core-service",
    status: "ok",
    database: "Skipped",
    rabbitmq: "Disabled",
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  });
});

// API Routes
app.use("/api/v1", apiRoutes); // Versioned API for clients
app.use("/api", apiRoutes); // Legacy API for backward compatibility
app.use("/api/auth", authRoutes); // Auth routes
app.use("/internal/v1", internalRoutes); // Inter-service communication

// Root route for testing
app.get("/", (req, res) => {
  res.json({
    service: "EventBn Core Service",
    status: "running",
    version: "1.0.0",
    health: "/health",
  });
});

// Service info
app.get("/info", (req, res) => {
  res.json({
    service: "EventBn Core Service",
    version: "1.0.0",
    description: "Handles users, events, organizations, tickets",
    port: process.env.CORE_SERVICE_PORT || 3001,
    environment: process.env.NODE_ENV || "development",
    endpoints: [
      "/health",
      "/api/auth/*",
      "/api/users/*",
      "/api/events/*",
      "/api/organizations/*",
      "/api/tickets/*",
    ],
    timestamp: new Date().toISOString(),
  });
});

// API Routes
app.use("/api", apiRoutes); // External API for clients
app.use("/internal/v1", internalRoutes); // Inter-service communication

// Error handling
app.use((err, req, res, next) => {
  console.error(`[CORE-SERVICE ERROR] ${err.stack}`);
  res.status(500).json({
    service: "core-service",
    error: "Internal server error",
    message:
      process.env.NODE_ENV === "development"
        ? err.message
        : "Something went wrong",
    timestamp: new Date().toISOString(),
  });
});

// 404 handler
app.use("*", (req, res) => {
  res.status(404).json({
    service: "core-service",
    error: "Route not found",
    path: req.originalUrl,
    method: req.method,
  });
});

const PORT = process.env.CORE_SERVICE_PORT || 3001;
const HOST = process.env.CORE_SERVICE_HOST || "0.0.0.0";

// Initialize RabbitMQ connections (optional)
const initializeRabbitMQ = async () => {
  try {
    console.log("[CORE-SERVICE] Initializing RabbitMQ...");

    // Connect publisher
    await connectToRabbitMQ();
    console.log("[CORE-SERVICE] ✅ RabbitMQ Publisher connected");

    // Start consumers
    await startRabbitMQConsumer();
    console.log("[CORE-SERVICE] ✅ RabbitMQ Consumers started");

    return true;
  } catch (error) {
    console.warn(
      "[CORE-SERVICE] ⚠️  RabbitMQ not available, continuing without it:",
      error.message
    );
    return false;
  }
};

// Graceful shutdown handler (simplified)
const gracefulShutdown = async () => {
  console.log("[CORE-SERVICE] Initiating graceful shutdown...");

  try {
    await prisma.$disconnect();
    console.log("[CORE-SERVICE] ✅ Graceful shutdown completed");
    process.exit(0);
  } catch (error) {
    console.error("[CORE-SERVICE] ❌ Error during shutdown:", error);
    process.exit(1);
  }
};

// Handle shutdown signals
process.on("SIGINT", gracefulShutdown);
process.on("SIGTERM", gracefulShutdown);

app.listen(PORT, HOST, async () => {
  console.log(`
\x1b[36m===============================\x1b[0m
\x1b[35m EventBn Core Service Started \x1b[0m
\x1b[36m-------------------------------\x1b[0m
\x1b[32mService:\x1b[0m Core Service (Users, Events, Orgs, Tickets)
\x1b[32mPort:\x1b[0m ${PORT}
\x1b[32mHost:\x1b[0m ${HOST}
\x1b[32mEnv:\x1b[0m ${process.env.NODE_ENV || "development"}
\x1b[32mURL:\x1b[0m http://localhost:${PORT}
\x1b[32mHealth:\x1b[0m http://localhost:${PORT}/health
\x1b[36m===============================\x1b[0m
`);

  // Database connection test
  try {
    // Use different query to avoid prepared statement conflicts with post-service
    await prisma.$executeRaw`SELECT 'core-service' as service`;
    console.log("\x1b[32m✅ Database connection established\x1b[0m");
  } catch (error) {
    console.error(
      "\x1b[31m❌ Database connection failed:",
      error.message,
      "\x1b[0m"
    );
  }

  // Initialize Redis for seat locking - Disabled for now
  /*
  try {
    console.log("\x1b[34m⏳ Initializing Redis...\x1b[0m");
    await connectRedis();
    console.log("\x1b[32m✅ Redis connected successfully\x1b[0m");
  } catch (error) {
    console.error(
      "\x1b[31m❌ Redis connection failed:",
      error.message,
      "\x1b[0m"
    );
    console.log(
      "\x1b[33m⚠️  Continuing without Redis (seat locking disabled)\x1b[0m"
    );
  }
  */

  // Initialize RabbitMQ if enabled
  if (process.env.RABBITMQ_ENABLED === "true") {
    try {
      console.log("\x1b[34m⏳ Initializing RabbitMQ Publisher...\x1b[0m");
      const rabbitMQConnected = await connectToRabbitMQ();
      if (rabbitMQConnected) {
        console.log(
          "\x1b[32m✅ RabbitMQ Publisher connected successfully\x1b[0m"
        );

        // Start RabbitMQ consumer for handling user data requests
        console.log("\x1b[34m⏳ Starting RabbitMQ Consumer...\x1b[0m");
        const consumerStarted = await startRabbitMQConsumer();
        if (consumerStarted) {
          console.log(
            "\x1b[32m✅ RabbitMQ Consumer started successfully\x1b[0m"
          );
        } else {
          console.log("\x1b[33m⚠️  RabbitMQ Consumer failed to start\x1b[0m");
        }
      } else {
        console.log(
          "\x1b[33m⚠️  RabbitMQ connection failed, continuing without it\x1b[0m"
        );
      }
    } catch (error) {
      console.error(
        "\x1b[31m❌ RabbitMQ initialization error:",
        error.message,
        "\x1b[0m"
      );
      console.log("\x1b[33m⚠️  Continuing without RabbitMQ\x1b[0m");
    }
  } else {
    console.log("\x1b[33m⚠️  RabbitMQ disabled by configuration\x1b[0m");
  }

  console.log("\x1b[32m🚀 Core Service ready as microservice!\x1b[0m");
});

module.exports = app;
