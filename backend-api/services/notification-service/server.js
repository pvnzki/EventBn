require("dotenv").config();

const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");

// Database
const prisma = require("./lib/database");

// RabbitMQ Consumer (Observer)
const {
  connectNotificationRabbitMQ,
  startNotificationConsumer,
  getNotificationRabbitMQHealth,
  closeNotificationRabbitMQ,
} = require("./utils/rabbitmq-consumer");

// Firebase Admin SDK
const { initializeFirebase } = require("./services/fcmSender");

// Routes
const notificationRoutes = require("./routes/notifications");

// Handle BigInt serialization
BigInt.prototype.toJSON = function () {
  return Number(this);
};

const app = express();

// ── CORS ──────────────────────────────────────────────────────────────

const isOriginAllowed = (origin) => {
  if (!origin) return true;
  const allowed = (process.env.NOTIFICATION_SERVICE_CORS_ORIGINS || '').split(',').filter(Boolean);
  if (allowed.length === 0) {
    // Defaults when no env var is set
    allowed.push(
      "http://localhost:3000",
      "http://127.0.0.1:3000",
      "http://localhost:3001",
      "http://127.0.0.1:3001",
      "http://localhost:8080",
      "http://127.0.0.1:8080"
    );
  }
  if (process.env.NODE_ENV === "development") {
    if (
      /^http:\/\/localhost:\d+$/.test(origin) ||
      /^http:\/\/127\.0\.0\.1:\d+$/.test(origin)
    ) {
      return true;
    }
  }
  return allowed.includes(origin);
};

app.use((req, res, next) => {
  const origin = req.headers.origin;
  if (isOriginAllowed(origin)) {
    if (origin) {
      res.header("Access-Control-Allow-Origin", origin);
      res.header("Vary", "Origin");
    }
    res.header("Access-Control-Allow-Credentials", "true");
    res.header(
      "Access-Control-Allow-Methods",
      "GET,POST,PUT,DELETE,OPTIONS,PATCH"
    );
    res.header(
      "Access-Control-Allow-Headers",
      "Content-Type,Authorization,X-Service-Key,X-Requested-With,Accept,Origin"
    );
    if (req.method === "OPTIONS") {
      return res.status(204).end();
    }
  }
  next();
});

// ── Security & Parsing ────────────────────────────────────────────────

app.use(helmet({ contentSecurityPolicy: false }));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 1000,
  message: "Too many requests from this IP, please try again later.",
});
app.use(limiter);

app.use(express.json({ limit: "1mb" }));
app.use(express.urlencoded({ limit: "1mb", extended: true }));

// ── Routes ────────────────────────────────────────────────────────────

app.use("/api/notifications", notificationRoutes);

// ── Health Check ──────────────────────────────────────────────────────

app.get("/health", async (req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    const rabbitHealth = await getNotificationRabbitMQHealth();

    res.json({
      status: "healthy",
      service: "notification-service",
      timestamp: new Date().toISOString(),
      database: "connected",
      rabbitmq: rabbitHealth.status,
    });
  } catch (error) {
    res.status(503).json({
      status: "unhealthy",
      service: "notification-service",
      error: error.message,
    });
  }
});

// ── Start Server ──────────────────────────────────────────────────────

const PORT = process.env.NOTIFICATION_SERVICE_PORT || 3003;

async function startServer() {
  try {
    // Test database connection
    await prisma.$queryRaw`SELECT 1`;
    console.log("✅ [NOTIFICATION-SERVICE] Database connected");

    // Initialize Firebase Admin SDK for push notifications
    try {
      initializeFirebase();
      console.log("✅ [NOTIFICATION-SERVICE] Firebase Admin SDK initialized");
    } catch (fbError) {
      console.warn("⚠️ [NOTIFICATION-SERVICE] Firebase not configured:", fbError.message);
      console.warn("   Push notifications will be disabled");
    }

    // Initialize RabbitMQ Consumer (Observer)
    if (process.env.RABBITMQ_ENABLED === "true") {
      try {
        await connectNotificationRabbitMQ();
        await startNotificationConsumer();
        console.log(
          "✅ [NOTIFICATION-SERVICE] RabbitMQ consumer (Observer) started"
        );
      } catch (mqError) {
        console.warn(
          "⚠️ [NOTIFICATION-SERVICE] RabbitMQ not available:",
          mqError.message
        );
        console.warn(
          "   Notification service will work without RabbitMQ (REST API only)"
        );
      }
    } else {
      console.log(
        "ℹ️ [NOTIFICATION-SERVICE] RabbitMQ disabled, running REST API only"
      );
    }

    app.listen(PORT, () => {
      console.log(
        `🔔 [NOTIFICATION-SERVICE] Running on port ${PORT}`
      );
    });
  } catch (error) {
    console.error(
      "❌ [NOTIFICATION-SERVICE] Failed to start:",
      error
    );
    process.exit(1);
  }
}

// ── Graceful Shutdown ─────────────────────────────────────────────────

const shutdown = async (signal) => {
  console.log(
    `\n${signal} received. Shutting down notification-service gracefully...`
  );
  try {
    await closeNotificationRabbitMQ();
    await prisma.$disconnect();
    console.log("[NOTIFICATION-SERVICE] Shutdown complete");
    process.exit(0);
  } catch (error) {
    console.error("[NOTIFICATION-SERVICE] Error during shutdown:", error);
    process.exit(1);
  }
};

process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));

startServer();

module.exports = app;
