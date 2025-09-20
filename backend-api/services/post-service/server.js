require("dotenv").config();

const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const compression = require("compression");
const rateLimit = require("express-rate-limit");

// Database and services
const { prisma, connectDatabase } = require("./lib/database");
const postService = require("./index");

// RabbitMQ services
const {
  connectToRabbitMQ,
  getRabbitMQHealth,
  closeRabbitMQ,
} = require("./utils/rabbitmq-publisher");
const {
  startConsumer: startRabbitMQConsumer,
  closeRabbitMQ: closeRabbitMQConsumer,
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

// Rate limiting for social media endpoints (more permissive)
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 2000, // Higher limit for social feeds
  message: "Too many requests from this IP, please try again later.",
});
app.use(limiter);

// Body parsing with higher limits for media uploads
app.use(express.json({ limit: "50mb" }));
app.use(express.urlencoded({ limit: "50mb", extended: true }));

// CORS Configuration
const corsOptions = {
  origin: process.env.POST_SERVICE_CORS_ORIGINS?.split(",") || [
    "http://localhost:3000",
    "http://localhost:3001", // core-service
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
  res.setHeader("X-Service-Name", "post-service");
  res.setHeader("X-Service-Version", "1.0.0");
  next();
});

// Import route handlers
const apiRoutes = require("./routes/api");
const internalRoutes = require("./routes/internal");

// API Routes
app.use("/api/v1", apiRoutes); // External API for clients
app.use("/internal/v1", internalRoutes); // Inter-service communication

// Health check endpoints - Always returns 200 for service readiness
app.get("/health", async (req, res) => {
  let databaseStatus = "Connected";
  let rabbitMQHealth = "Unknown";
  let health = { service: "post-service", status: "ok" };

  try {
    await prisma.$queryRaw`SELECT 1`;
    databaseStatus = "Connected";
  } catch (error) {
    databaseStatus = "Disconnected";
    console.warn(`[POST-SERVICE] Database check failed: ${error.message}`);
  }

  try {
    // Get service health if available
    if (postService && typeof postService.health === "function") {
      health = await postService.health();
    }

    // Check RabbitMQ health only if enabled
    const isRabbitMQEnabled = process.env.RABBITMQ_ENABLED === "true";
    if (isRabbitMQEnabled) {
      rabbitMQHealth = await getRabbitMQHealth();
    } else {
      rabbitMQHealth = "Disabled";
    }
  } catch (error) {
    console.warn(
      `[POST-SERVICE] Service health check failed: ${error.message}`
    );
    rabbitMQHealth = "Disconnected";
  }

  // Always return 200 OK for service readiness, regardless of database status
  res.status(200).json({
    ...health,
    database: databaseStatus,
    rabbitmq: rabbitMQHealth,
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  });
});

app.get("/health/ready", async (req, res) => {
  try {
    // Check database connectivity
    let databaseCheck = "connected";
    try {
      await prisma.$queryRaw`SELECT 1`;
    } catch {
      databaseCheck = "disconnected";
    }

    // Check RabbitMQ status
    const isRabbitMQEnabled = process.env.RABBITMQ_ENABLED === "true";
    const rabbitmqCheck = isRabbitMQEnabled ? "connected" : "disabled";

    // Get service health if available
    let health = { status: "ready" };
    if (postService && typeof postService.health === "function") {
      health = await postService.health();
    }

    res.json({
      status: "ready",
      service: "post-service",
      checks: {
        database: databaseCheck,
        rabbitmq: rabbitmqCheck,
        core_service: "unknown",
      },
    });
  } catch (error) {
    console.error("[HEALTH] Service not ready:", error);
    res.status(503).json({
      status: "not_ready",
      service: "post-service",
      error: error.message,
    });
  }
});

app.get("/health/live", (req, res) => {
  res.json({
    status: "alive",
    service: "post-service",
  });
});

// Service info
app.get("/", (req, res) => {
  res.json({
    service: "EventBn Post Service",
    version: "1.0.0",
    description: "Handles social media posts, comments, likes, and feeds",
    port: process.env.POST_SERVICE_PORT || 3002,
    environment: process.env.NODE_ENV || "development",
    endpoints: [
      "/health",
      "/api/v1/posts/*",
      "/api/v1/feeds/*",
      "/api/v1/comments/*",
      "/api/v1/likes/*",
      "/internal/v1/*",
    ],
    integrations: {
      core_service: process.env.CORE_SERVICE_URL || "http://localhost:3001",
      rabbitmq: "Connected",
    },
    timestamp: new Date().toISOString(),
  });
});

// Error handling
app.use((err, req, res, next) => {
  console.error(`[POST-SERVICE ERROR] ${err.stack}`);
  res.status(500).json({
    service: "post-service",
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
    service: "post-service",
    error: "Route not found",
    path: req.originalUrl,
    method: req.method,
  });
});

const PORT = process.env.POST_SERVICE_PORT || 3002;
const HOST = process.env.POST_SERVICE_HOST || "0.0.0.0";

// Initialize RabbitMQ connections (optional)
const initializeRabbitMQ = async () => {
  // Check if RabbitMQ is enabled
  const isRabbitMQEnabled = process.env.RABBITMQ_ENABLED === "true";

  if (!isRabbitMQEnabled) {
    console.log("[POST-SERVICE] ⚠️  RabbitMQ disabled by configuration");
    return false;
  }

  try {
    console.log("[POST-SERVICE] Initializing RabbitMQ...");

    // Connect publisher
    await connectToRabbitMQ();
    console.log("[POST-SERVICE] ✅ RabbitMQ Publisher connected");

    // Start consumers
    await startRabbitMQConsumer();
    console.log("[POST-SERVICE] ✅ RabbitMQ Consumers started");

    return true;
  } catch (error) {
    console.error("[POST-SERVICE] ❌ RabbitMQ initialization failed:", error);
    return false;
  }
};

// Graceful shutdown handler
const gracefulShutdown = async () => {
  console.log("[POST-SERVICE] Initiating graceful shutdown...");

  try {
    // Only close RabbitMQ connections if they were initialized
    const isRabbitMQEnabled = process.env.RABBITMQ_ENABLED === "true";
    if (isRabbitMQEnabled) {
      await closeRabbitMQ();
      await closeRabbitMQConsumer();
    }

    await prisma.$disconnect();

    console.log("[POST-SERVICE] ✅ Graceful shutdown completed");
    process.exit(0);
  } catch (error) {
    console.error("[POST-SERVICE] ❌ Error during shutdown:", error);
    process.exit(1);
  }
};

// Handle shutdown signals
process.on("SIGINT", gracefulShutdown);
process.on("SIGTERM", gracefulShutdown);

app.listen(PORT, HOST, async () => {
  console.log(`
\x1b[36m===============================\x1b[0m
\x1b[35m EventBn Post Service Started \x1b[0m
\x1b[36m-------------------------------\x1b[0m
\x1b[32mService:\x1b[0m Post Service (Social Media, Feeds)
\x1b[32mPort:\x1b[0m ${PORT}
\x1b[32mHost:\x1b[0m ${HOST}
\x1b[32mEnv:\x1b[0m ${process.env.NODE_ENV || "development"}
\x1b[32mURL:\x1b[0m http://localhost:${PORT}
\x1b[32mHealth:\x1b[0m http://localhost:${PORT}/health
\x1b[32mCore Service:\x1b[0m ${
    process.env.CORE_SERVICE_URL || "http://localhost:3001"
  }
\x1b[36m===============================\x1b[0m
`);

  // Initialize database connection
  let databaseReady = false;
  try {
    databaseReady = await connectDatabase();
    if (databaseReady) {
      console.log(
        "\x1b[32m✅ Post Service: Database connection established\x1b[0m"
      );
    }
  } catch (error) {
    console.error("\x1b[31m❌ Post Service: Database connection failed\x1b[0m");
    console.log(
      "\x1b[33m⚠️  Post Service: Continuing without database...\x1b[0m"
    );
  }

  // Initialize RabbitMQ after server starts
  let rabbitMQReady = false;
  try {
    rabbitMQReady = await initializeRabbitMQ();
  } catch (error) {
    console.log(
      "\x1b[33m⚠️  Post Service: RabbitMQ initialization skipped\x1b[0m"
    );
  }

  if (rabbitMQReady && databaseReady) {
    console.log("\x1b[32m🚀 Post Service: All systems ready!\x1b[0m");
  } else {
    console.log(
      "\x1b[33m⚠️  Post Service: Running with limited functionality\x1b[0m"
    );
  }

  console.log("\x1b[32m🎉 Post Service is ready to accept requests!\x1b[0m");
});

module.exports = app;
