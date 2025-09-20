require("dotenv").config();

const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const compression = require("compression");
const rateLimit = require("express-rate-limit");
const path = require("path");

// Database for core-service
const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();
// const coreService = require("./index"); // Temporarily disabled to avoid database conflicts

// RabbitMQ - Temporarily disabled for testing
// const { connectToRabbitMQ, publishUserEvent } = require("./utils/rabbitmq-publisher");

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

// CORS Configuration
const corsOptions = {
  origin: process.env.CORE_SERVICE_CORS_ORIGINS?.split(",") || [
    "http://localhost:3000",
    "http://localhost:3002", // post-service
    "http://localhost:8080",
    /^http:\/\/localhost:\d+$/,
  ],
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization", "X-Service-Key"],
};
app.use(cors(corsOptions));

// Service identification middleware
app.use((req, res, next) => {
  res.setHeader("X-Service-Name", "core-service");
  res.setHeader("X-Service-Version", "1.0.0");
  next();
});

// Import route handlers
const apiRoutes = require("./routes/api");
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

// API Routes (temporarily disabled for testing)
// app.use('/api/v1', apiRoutes);           // External API for clients
// app.use('/internal/v1', internalRoutes); // Inter-service communication

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
    await prisma.$queryRaw`SELECT 1`;
    console.log("\x1b[32m✅ Database connection established\x1b[0m");
  } catch (error) {
    console.error(
      "\x1b[31m❌ Database connection failed:",
      error.message,
      "\x1b[0m"
    );
  }

  // RabbitMQ temporarily disabled for testing
  console.log("\x1b[33m⚠️  RabbitMQ disabled for testing\x1b[0m");

  console.log("\x1b[32m🚀 Core Service ready as microservice!\x1b[0m");
});

module.exports = app;
