require("dotenv").config();

const express = require("express");
const cors = require("cors");
const prisma = require("./lib/database");

// Import services
const coreService = require("./services/core-service");
const postService = require("./services/post-service");

// Import routes
const apiRoutes = require("./routes/api");

const app = express();

// Middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// CORS Configuration
const corsOptions = {
  origin: process.env.CORS_ORIGIN?.split(",") || [
    "http://localhost:3000",
    "http://10.0.2.2:3000", // Android emulator
    "http://192.168.1.104:3000"
  ],
  credentials: true,
  optionsSuccessStatus: 200,
};
app.use(cors(corsOptions));

// Serve static files (for uploaded images)
app.use("/uploads", express.static("uploads"));

// API Routes
app.use("/api/v1", apiRoutes);

// Root route
app.get("/", (req, res) => {
  res.json({
    message: "EventBn Backend API",
    version: "1.0.0",
    environment: process.env.NODE_ENV,
    services: {
      "core-service": "running",
      "post-service": "running",
    },
    endpoints: {
      health: "/api/v1/health",
      auth: "/api/v1/auth/*",
      users: "/api/v1/users/*",
      organizations: "/api/v1/organizations/*",
      events: "/api/v1/events/*",
      tickets: "/api/v1/tickets/*",
      posts: "/api/v1/posts/*",
    }
  });
});

// Legacy health check (keep for compatibility)
app.get("/health", async (req, res) => {
  try {
    // Test database connection
    await prisma.$queryRaw`SELECT 1`;

    res.json({
      status: "OK",
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV,
      uptime: process.uptime(),
      database: "Connected",
    });
  } catch (error) {
    res.status(500).json({
      status: "ERROR",
      timestamp: new Date().toISOString(),
      database: "Disconnected",
      error: error.message,
    });
  }
});

// 404 handler
app.use("*", (req, res) => {
  res.status(404).json({
    error: "Route not found",
    path: req.originalUrl,
    method: req.method,
  });
});

// Global error handler
app.use((error, req, res, next) => {
  console.error("Global error handler:", error);
  
  // Prisma error handling
  if (error.code === 'P2002') {
    return res.status(400).json({
      error: "Duplicate entry",
      field: error.meta?.target?.[0] || "unknown",
    });
  }
  
  if (error.code === 'P2025') {
    return res.status(404).json({
      error: "Record not found",
    });
  }

  // JWT error handling
  if (error.name === 'JsonWebTokenError') {
    return res.status(401).json({
      error: "Invalid token",
    });
  }

  if (error.name === 'TokenExpiredError') {
    return res.status(401).json({
      error: "Token expired",
    });
  }

  // Default error
  res.status(500).json({
    error: process.env.NODE_ENV === 'Dev' ? error.message : "Internal server error",
  });
});

// Initialize services and start server
const PORT = process.env.PORT || 3000;

async function startServer() {
  try {
    // Test database connection
    await prisma.$connect();
    console.log("✅ Database connected successfully");

    // Initialize services
    await coreService.initialize();
    await postService.initialize();
    console.log("✅ All services initialized");

    // Start server
    app.listen(PORT, () => {
      console.log(`🚀 Server running on port ${PORT}`);
      console.log(`📊 Environment: ${process.env.NODE_ENV}`);
      console.log(`🌐 API Base URL: http://localhost:${PORT}/api/v1`);
      console.log(`📖 API Documentation: http://localhost:${PORT}`);
      
      if (process.env.NODE_ENV === 'Dev') {
        console.log('\n🔧 Available Services:');
        console.log('   - Core Service: Users, Organizations, Events, Tickets, Auth');
        console.log('   - Post Service: Posts, Comments, Likes, Shares');
        console.log('\n📋 Key Endpoints:');
        console.log('   - Health: GET /api/v1/health');
        console.log('   - Register: POST /api/v1/auth/register');
        console.log('   - Login: POST /api/v1/auth/login');
        console.log('   - Events: GET /api/v1/events');
        console.log('   - Posts Feed: GET /api/v1/posts/feed');
      }
    });
  } catch (error) {
    console.error("❌ Failed to start server:", error);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n🔄 Shutting down gracefully...');
  await prisma.$disconnect();
  console.log('✅ Database disconnected');
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\n� Shutting down gracefully...');
  await prisma.$disconnect();
  console.log('✅ Database disconnected');
  process.exit(0);
});

startServer();

module.exports = app;
