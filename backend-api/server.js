require("dotenv").config();

const express = require("express");
const path = require("path");
const cors = require("cors");
const helmet = require("helmet");
const prisma = require("./lib/database");
const { connectRedis } = require("./lib/redis");

// Handle BigInt serialization for JSON responses
BigInt.prototype.toJSON = function () {
  return Number(this);
};

const app = express();

// NOTE: Currently running as a monolith with service modules.
// Services are organized for future microservice separation but share the same process/database.
// To convert to true microservices: split into separate Node.js applications with their own ports.

// Middleware
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ limit: "10mb", extended: true }));

// Security headers via Helmet
// Disable CSP by default to avoid breaking local dev; configure a strict CSP later if needed.
app.use(helmet({
  contentSecurityPolicy: false,
  crossOriginEmbedderPolicy: false,
}));

// In production, add HSTS when serving over HTTPS (handled by reverse proxy/CDN typically)
if (process.env.NODE_ENV === 'production') {
  app.use(helmet.hsts({
    maxAge: 15552000, // 180 days
    includeSubDomains: true,
    preload: false,
  }));
}

// CORS Configuration
let corsOptions = {};

if (process.env.NODE_ENV === "development" || process.env.NODE_ENV === "test") {
  // Development & Test → allow all origins with more permissive settings
  corsOptions = { 
    origin: function(origin, callback) {
      // Allow requests with no origin (like mobile apps or curl requests)
      if (!origin) return callback(null, true);
      
      // Allow any localhost or 127.0.0.1 origin on any port
      if (origin.match(/^http:\/\/localhost:\d+$/) || 
          origin.match(/^http:\/\/127\.0\.0\.1:\d+$/) ||
          origin.includes('flutter') ||
          origin.includes('dart')) {
        return callback(null, true);
      }
      
      return callback(null, true); // Allow all in development
    },
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
    allowedHeaders: ["Content-Type", "Authorization", "X-Requested-With", "Accept", "Origin"],
    preflightContinue: false,
    optionsSuccessStatus: 204
  };
} else {
  // Production → only allow origins from .env
  const allowedOrigins = process.env.CORS_ORIGIN
    ? process.env.CORS_ORIGIN.split(",").map((o) => o.trim())
    : [
        "http://localhost:3000",
        "http://localhost:8080", // Flutter web default
        "http://localhost:54321",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8080",
        "http://10.0.2.2:3000", // Android emulator
        /^http:\/\/localhost:\d+$/,
        /^http:\/\/127\.0\.0\.1:\d+$/,
        "http://localhost:3001",
        "http://localhost:3002",
        "http://localhost:5000",
        "http://localhost:5173", // Vite default
      ];

  corsOptions = {
    origin: allowedOrigins,
    credentials: true,
    optionsSuccessStatus: 200,
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  };
}

app.use(cors(corsOptions));

// Add explicit CORS headers middleware for all requests
app.use((req, res, next) => {
  const origin = req.headers.origin;
  
  // In development, allow any localhost/127.0.0.1 origin
  if (process.env.NODE_ENV === "development" || process.env.NODE_ENV === "test") {
    if (origin && (origin.includes('localhost') || origin.includes('127.0.0.1'))) {
      res.header('Access-Control-Allow-Origin', origin);
    } else if (!origin) {
      res.header('Access-Control-Allow-Origin', '*');
    }
  }
  
  res.header('Access-Control-Allow-Credentials', 'true');
  res.header('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS,PATCH');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  res.header('Vary', 'Origin');
  
  next();
});

// Explicit preflight handling
app.options('*', (req, res) => {
  const origin = req.headers.origin;
  
  // In development, allow any localhost/127.0.0.1 origin
  if (process.env.NODE_ENV === "development" || process.env.NODE_ENV === "test") {
    if (origin && (origin.includes('localhost') || origin.includes('127.0.0.1'))) {
      res.header('Access-Control-Allow-Origin', origin);
    } else {
      res.header('Access-Control-Allow-Origin', '*');
    }
  }
  
  res.header('Access-Control-Allow-Credentials', 'true');
  res.header('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS,PATCH');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  res.header('Vary', 'Origin');
  res.header('Access-Control-Max-Age', '86400'); // 24 hours
  
  return res.sendStatus(204);
});

// Routes
const authRoutes = require("./services/core-service/routes/api");
const eventRoutes = require("./services/core-service/routes/api");
const userRoutes = require("./services/core-service/routes/api");
const organizationRoutes = require("./services/core-service/routes/api");
const paymentRoutes = require("./services/core-service/routes/api");
const ticketRoutes = require("./services/core-service/routes/api");
const seatLockRoutes = require("./services/core-service/routes/api");
const queueRoutes = require("./services/core-service/routes/api");

const analyticsRoutes = require("./services/core-service/routes/api");

// Serve static files (for uploaded images)
app.use("/uploads", express.static(path.join(process.cwd(), "uploads")));

// Basic route
app.get("/", (req, res) => {
  res.json({
    message: "EventBn API Server",
    environment: process.env.NODE_ENV,
    port: process.env.PORT,
    timestamp: new Date().toISOString(),
  });
});

// Health check endpoint
app.get("/health", async (req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;

    res.json({
      status: "OK",
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV,
      uptime: process.uptime(),
      database: "Connected",
      redis: "Connected",
    });
  } catch (error) {
    res.status(500).json({
      status: "ERROR",
      timestamp: new Date().toISOString(),
      database: "Disconnected",
      redis: "Unknown",
      error: error.message,
    });
  }
});

// API routes
app.use("/api/auth", authRoutes);
app.use("/api/events", eventRoutes);
app.use("/api/users", userRoutes);
app.use("/api/organizations", organizationRoutes);
app.use("/api/payments", paymentRoutes);
app.use("/api/tickets", ticketRoutes);
app.use("/api/seat-locks", seatLockRoutes);
app.use("/api/queue", queueRoutes);

app.use("/api/analytics", analyticsRoutes);

// Mount post service routes
const postServiceRoutes = require("./services/post-service/routes/api");
app.use("/api", postServiceRoutes);

// Mount notification service routes
const notificationRoutes2 = require("./services/notification-service/routes/notifications");
app.use("/api/notifications", notificationRoutes2);

// Service health endpoints (prepare for microservice separation)
app.get("/api/services/core/health", async (req, res) => {
  try {
    const coreService = require("./services/core-service");
    const health = await coreService.health();
    res.json(health);
  } catch (error) {
    res.status(500).json({
      service: "core-service",
      status: "error",
      error: error.message,
      timestamp: new Date().toISOString(),
    });
  }
});

app.get("/api/services/post/health", async (req, res) => {
  try {
    const postService = require("./services/post-service");
    const health = await postService.healthCheck();
    res.json(health);
  } catch (error) {
    res.status(500).json({
      service: "post-service",
      status: "error",
      error: error.message,
      timestamp: new Date().toISOString(),
    });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);

  // Handle JSON parsing errors
  if (err instanceof SyntaxError && err.status === 400 && "body" in err) {
    return res.status(400).json({
      success: false,
      message: "Invalid JSON format",
      code: "INVALID_JSON",
    });
  }

  res.status(500).json({
    success: false,
    message:
      process.env.NODE_ENV === "development"
        ? err.message
        : "Internal Server Error",
    code: "SERVER_ERROR",
  });
});

// 404 handler
app.use("*", (req, res) => {
  res.status(404).json({
    error: "Route not found",
    path: req.originalUrl,
    method: req.method,
  });
});

const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || "0.0.0.0"; // Listen on all network interfaces

// Initialize Redis connection
const startServer = async () => {
  try {
    // Connect to Redis
    await connectRedis();

    // Start the server
    const server = app.listen(PORT, HOST, () => {
      console.log(`
\x1b[36m==============================\x1b[0m
\x1b[35m EventBn API Server Started \x1b[0m
\x1b[36m------------------------------\x1b[0m
\x1b[32mEnv:\x1b[0m ${process.env.NODE_ENV || "development"}
\x1b[32mPort:\x1b[0m ${PORT}
\x1b[32mHost:\x1b[0m ${HOST}
\x1b[32mLocal URL:\x1b[0m http://localhost:${PORT}
\x1b[32mNetwork URL:\x1b[0m http://192.168.1.19:${PORT}
\x1b[32mHealth:\x1b[0m /health
\x1b[32mRedis:\x1b[0m Connected
\x1b[36m==============================\x1b[0m
`);
    });
    return server;
  } catch (error) {
    console.error("❌ Failed to start server:", error);
    process.exit(1);
  }
};

// Only start server if not in test mode
if (process.env.NODE_ENV !== 'test' && !module.parent) {
  startServer();
}

module.exports = app;
