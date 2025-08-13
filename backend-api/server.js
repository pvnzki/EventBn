require("dotenv").config();

const express = require("express");
const cors = require("cors");
const prisma = require("./lib/database");

const app = express();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// CORS Configuration
let corsOptions = {};

if (process.env.NODE_ENV === "development") {
  // Development → allow all origins
  corsOptions = { origin: true, credentials: true };
} else {
  // Production → only allow origins from .env
  const allowedOrigins = process.env.CORS_ORIGIN
    ? process.env.CORS_ORIGIN.split(",").map(o => o.trim())
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

// Routes
const authRoutes = require("./routes/auth");
const eventRoutes = require("./routes/events");
const userRoutes = require("./routes/users");
const organizationRoutes = require("./routes/organizations");

// Serve static files (for uploaded images)
app.use("/uploads", express.static("uploads"));

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

// API routes
app.use("/api/auth", authRoutes);
app.use("/api/events", eventRoutes);
app.use("/api/users", userRoutes);
app.use("/api/organizations", organizationRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: "Something went wrong!",
    message:
      process.env.NODE_ENV === "Dev" ? err.message : "Internal Server Error",
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

app.listen(PORT, () => {
  console.log(`
\x1b[36m==============================\x1b[0m
\x1b[35m EventBn API Server Started \x1b[0m
\x1b[36m------------------------------\x1b[0m
\x1b[32mEnv:\x1b[0m ${process.env.NODE_ENV || "development"}
\x1b[32mPort:\x1b[0m ${PORT}
\x1b[32mURL:\x1b[0m http://localhost:${PORT}
\x1b[32mHealth:\x1b[0m /health
\x1b[36m==============================\x1b[0m
`);
});

module.exports = app;
