const express = require("express");
const router = express.Router();
// const coreService = require("../index"); // Disabled to prevent circular dependencies
const jwt = require("jsonwebtoken");
const prisma = require("../lib/database");
const speakeasy = require("speakeasy");
const bcrypt = require("bcrypt");

// Import seat lock service at the top level
const seatLockService = require("../seat-locks/seatLockService");

// Import email service
const emailService = require("../email");

// Authentication middleware (production style)
const authenticateUser = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res
        .status(401)
        .json({ success: false, error: "Unauthorized: Bearer token required" });
    }
    const token = authHeader.slice(7);
    if (!process.env.JWT_SECRET) {
      return res
        .status(500)
        .json({ success: false, error: "JWT secret not configured" });
    }
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    // Standardize userId
    req.userId = decoded.userId || decoded.user_id || decoded.id;
    if (!req.userId) {
      return res.status(401).json({
        success: false,
        error: "Invalid token payload (missing userId)",
      });
    }
    next();
  } catch (e) {
    return res.status(401).json({
      success: false,
      error: "Invalid or expired token",
      message: e.message,
    });
  }
};

// Sample fallback events (used when DB or service layer unavailable)
const FALLBACK_EVENTS = [
  {
    event_id: 1001,
    title: "Sample Tech Conference",
    description: "A placeholder tech conference event used in fallback mode.",
    category: "Technology",
    location: "Virtual",
    start_date: new Date(Date.now() + 86400000).toISOString(),
    end_date: new Date(Date.now() + 90000000).toISOString(),
    banner_url: null,
    created_at: new Date().toISOString(),
    _fallback: true,
  },
  {
    event_id: 1002,
    title: "Community Music Festival",
    description: "Fallback music festival event for development mode.",
    category: "Music",
    location: "Colombo",
    start_date: new Date(Date.now() + 172800000).toISOString(),
    end_date: new Date(Date.now() + 181440000).toISOString(),
    banner_url: null,
    created_at: new Date().toISOString(),
    _fallback: true,
  },
];
console.log("[CORE-SERVICE] Fallback events loaded:", FALLBACK_EVENTS.length);

// Helper utilities (mirroring monolith transformations) --------------------
function formatDisplayDate(dateTime) {
  if (!dateTime) return "";
  const date = new Date(dateTime);
  if (isNaN(date.getTime())) return "";
  const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
  const months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];
  const dayName = days[date.getDay()];
  const monthName = months[date.getMonth()];
  const day = date.getDate();
  const hours = date.getHours();
  const minutes = date.getMinutes();
  const time = `${hours % 12 || 12}:${minutes.toString().padStart(2, "0")} ${
    hours >= 12 ? "PM" : "AM"
  }`;
  return `${dayName}, ${monthName} ${day} • ${time}`;
}

function deriveDisplayPrice(event) {
  // Simple heuristic; could be replaced with real ticket pricing aggregation
  const category = event.category || "General";
  const base = category.length * 3 + 15;
  return `$${base}`;
}

function placeholderImageForCategory(category) {
  const images = {
    Music:
      "https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=400&h=200&fit=crop",
    Entertainment:
      "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=200&fit=crop",
    Sports:
      "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=200&fit=crop",
    Technology:
      "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=400&h=200&fit=crop",
    Education:
      "https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=400&h=200&fit=crop",
    Food: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&h=180&fit=crop",
  };
  return (
    images[category] ||
    "https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=300&h=180&fit=crop"
  );
}

// Debug endpoint to test database connection
router.get("/debug/db-test", async (req, res) => {
  try {
    console.log("[DEBUG] Testing database connection...");

    // Test basic connectivity
    const result = await prisma.$queryRaw`SELECT 1 as test`;
    console.log("[DEBUG] Basic query result:", result);

    // Test user count
    const userCount = await prisma.user.count();
    console.log("[DEBUG] User count:", userCount);

    // Test if TicketPurchase table exists
    const ticketCount = await prisma.ticket_purchase.count();
    console.log("[DEBUG] Ticket purchase count:", ticketCount);

    res.json({
      success: true,
      database: "connected",
      userCount,
      ticketCount,
      message: "Database connection successful",
    });
  } catch (e) {
    console.error("[DEBUG] Database test failed:", e);
    res.status(500).json({
      success: false,
      error: "Database test failed",
      message: e.message,
      stack: process.env.NODE_ENV === "development" ? e.stack : undefined,
    });
  }
});

// Public auth routes (no authentication required)
router.post("/auth/login", async (req, res) => {
  console.log("🚀 [DEBUG] /auth/login endpoint hit!");
  try {
    const { email, password } = req.body || {};
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        error: "Email and password are required",
        message: "Email and password are required",
      });
    }

    // Direct database authentication
    const bcrypt = require("bcrypt");

    console.log(`[AUTH] Querying user data for: ${email}`);

    let user;
    try {
      user = await prisma.user.findUnique({
        where: { email: email.toLowerCase() },
        select: {
          user_id: true,
          name: true,
          email: true,
          password_hash: true,
          role: true,
          is_active: true,
          profile_picture: true,
          two_factor_enabled: true,
        },
      });
      console.log(`[AUTH] Prisma query successful`);
    } catch (prismaError) {
      console.error(`[AUTH] Prisma error:`, prismaError.message);
      // Fallback query without two_factor_method
      user = await prisma.user.findUnique({
        where: { email: email.toLowerCase() },
        select: {
          user_id: true,
          name: true,
          email: true,
          password_hash: true,
          role: true,
          is_active: true,
          profile_picture: true,
          two_factor_enabled: true,
        },
      });
      console.log(`[AUTH] Fallback query successful`);
    }

    console.log(`[AUTH] User found: ${user ? "YES" : "NO"}`);
    if (user) {
      console.log(
        `[AUTH] User data: ${JSON.stringify({
          user_id: user.user_id,
          email: user.email,
          two_factor_enabled: user.two_factor_enabled,
          two_factor_method: user.two_factor_method || "app",
        })}`
      );
    }

    if (!user) {
      return res.status(401).json({
        success: false,
        error: "Invalid email or password",
        message: "Invalid email or password",
      });
    }

    if (!user.is_active) {
      return res.status(401).json({
        success: false,
        error: "Account is inactive",
        message: "Account is inactive",
      });
    }

    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        error: "Invalid email or password",
        message: "Invalid email or password",
      });
    }

    // Check if 2FA is enabled
    console.log(
      `[AUTH] User 2FA status for ${user.email}: enabled=${user.two_factor_enabled}`
    );

    if (user.two_factor_enabled) {
      console.log(`[AUTH] 2FA required for user ${user.email}`);
      return res.status(200).json({
        success: false,
        requiresTwoFactor: true,
        twoFactorMethod: "app", // Default to app method
        message: "2FA required",
      });
    }

    console.log(`[AUTH] 2FA not enabled, proceeding with normal login`);

    // Generate JWT token
    const tokenPayload = {
      userId: user.user_id,
      email: user.email,
      name: user.name,
      role: user.role,
    };

    const token = jwt.sign(tokenPayload, process.env.JWT_SECRET, {
      expiresIn: "7d",
    });

    const userData = {
      id: user.user_id,
      user_id: user.user_id,
      name: user.name,
      email: user.email,
      role: user.role,
      profile_picture: user.profile_picture,
    };

    res.status(200).json({
      success: true,
      message: "Login successful",
      token: token,
      data: userData,
      user: userData,
      service: "core-service",
    });
  } catch (error) {
    console.error("[API] Login error:", error);
    res
      .status(500)
      .json({ success: false, error: "Login failed", message: error.message });
  }
});

// 2FA Login endpoint
router.post("/auth/login/2fa", async (req, res) => {
  try {
    const { email, password, twoFactorCode } = req.body || {};
    if (!email || !password || !twoFactorCode) {
      return res.status(400).json({
        success: false,
        error: "Email, password, and 2FA code are required",
        message: "Email, password, and 2FA code are required",
      });
    }

    const bcrypt = require("bcrypt");

    const user = await prisma.user.findUnique({
      where: { email: email.toLowerCase() },
      select: {
        user_id: true,
        name: true,
        email: true,
        password_hash: true,
        role: true,
        is_active: true,
        profile_picture: true,
        two_factor_enabled: true,
        two_factor_secret: true,
      },
    });

    if (!user) {
      return res.status(401).json({
        success: false,
        error: "Invalid email or password",
        message: "Invalid email or password",
      });
    }

    if (!user.is_active) {
      return res.status(401).json({
        success: false,
        error: "Account is inactive",
        message: "Account is inactive",
      });
    }

    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        error: "Invalid email or password",
        message: "Invalid email or password",
      });
    }

    if (!user.two_factor_enabled || !user.two_factor_secret) {
      return res.status(400).json({
        success: false,
        error: "2FA not enabled for this account",
        message: "2FA not enabled for this account",
      });
    }

    // Verify 2FA code
    const verified = speakeasy.totp.verify({
      secret: user.two_factor_secret,
      encoding: "base32",
      token: twoFactorCode,
      window: 2,
    });

    if (!verified) {
      return res.status(400).json({
        success: false,
        error: "Invalid 2FA code",
        message: "Invalid 2FA code",
      });
    }
    // Check 2FA method
    if (user.two_factor_method === "app") {
      if (!user.two_factor_secret) {
        return res.status(400).json({
          success: false,
          error: "2FA app not set up",
          message: "2FA app not set up",
        });
      }
      // Verify TOTP
      const verified = speakeasy.totp.verify({
        secret: user.two_factor_secret,
        encoding: "base32",
        token: twoFactorCode,
        window: 2,
      });
      if (!verified) {
        return res.status(400).json({
          success: false,
          error: "Invalid 2FA code",
          message: "Invalid 2FA code",
        });
      }
    } else if (user.two_factor_method === "email") {
      // Verify email OTP
      if (!user.email_otp_code || user.email_otp_code !== twoFactorCode) {
        return res.status(400).json({
          success: false,
          error: "Invalid OTP",
          message: "Invalid OTP",
        });
      }
      if (
        !user.email_otp_expires_at ||
        new Date() > user.email_otp_expires_at
      ) {
        return res.status(400).json({
          success: false,
          error: "OTP expired",
          message: "OTP expired",
        });
      }
      // Optionally clear OTP after use
      await prisma.user.update({
        where: { user_id: user.user_id },
        data: { email_otp_code: null, email_otp_expires_at: null },
      });
    } else {
      return res.status(400).json({
        success: false,
        error: "Unknown 2FA method",
        message: "Unknown 2FA method",
      });
    }

    // Generate JWT token
    const tokenPayload = {
      userId: user.user_id,
      email: user.email,
      name: user.name,
      role: user.role,
    };

    const token = jwt.sign(tokenPayload, process.env.JWT_SECRET, {
      expiresIn: "7d",
    });

    const userData = {
      id: user.user_id,
      user_id: user.user_id,
      name: user.name,
      email: user.email,
      role: user.role,
      profile_picture: user.profile_picture,
    };

    res.status(200).json({
      success: true,
      message: "Login successful",
      token: token,
      data: userData,
      user: userData,
      service: "core-service",
    });
  } catch (error) {
    console.error("[API] 2FA Login error:", error);
    res.status(500).json({
      success: false,
      error: "Login failed",
      message: error.message,
    });
  }
});

// (Removed) /auth/dev-login - development shortcut deleted for production parity

router.post("/auth/register", async (req, res) => {
  try {
    const { name, email, password, phone_number, profile_picture } =
      req.body || {};
    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        error: "Name, email, and password are required",
        message: "Name, email, and password are required",
      });
    }

    // Direct database registration
    const bcrypt = require("bcrypt");

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email: email.toLowerCase() },
    });

    if (existingUser) {
      return res.status(400).json({
        success: false,
        error: "User with this email already exists",
        message: "User with this email already exists",
      });
    }

    // Hash password
    const saltRounds = 12;
    const password_hash = await bcrypt.hash(password, saltRounds);

    // Create user
    const newUser = await prisma.user.create({
      data: {
        name: name.trim(),
        email: email.toLowerCase().trim(),
        password_hash,
        phone_number: phone_number?.trim() || null,
        profile_picture: profile_picture?.trim() || null,
        is_active: true,
        is_email_verified: false,
        role: "USER",
      },
      select: {
        user_id: true,
        name: true,
        email: true,
        role: true,
        profile_picture: true,
        created_at: true,
      },
    });

    // Generate JWT token
    const tokenPayload = {
      userId: newUser.user_id,
      email: newUser.email,
      name: newUser.name,
      role: newUser.role,
    };

    const token = jwt.sign(tokenPayload, process.env.JWT_SECRET, {
      expiresIn: "7d",
    });

    const userData = {
      id: newUser.user_id,
      user_id: newUser.user_id,
      name: newUser.name,
      email: newUser.email,
      role: newUser.role,
      profile_picture: newUser.profile_picture,
      created_at: newUser.created_at,
    };

    res.status(201).json({
      success: true,
      message: "User registered successfully",
      token: token,
      data: userData,
      user: userData,
      service: "core-service",
    });
  } catch (error) {
    console.error("[API] Registration error:", error);
    res.status(500).json({
      success: false,
      error: "Registration failed",
      message: error.message,
    });
  }
});

// 2FA and Security endpoints (require authentication for most)
router.post("/auth/2fa/generate", authenticateUser, async (req, res) => {
  try {
    const userId = req.userId;
    if (!userId) {
      return res.status(401).json({ success: false, error: "Unauthorized" });
    }

    // Generate TOTP secret
    const secret = speakeasy.generateSecret({
      name: `EventBn (${req.user.email})`,
      issuer: "EventBn",
    });

    // Generate backup codes
    const backupCodes = [];
    for (let i = 0; i < 10; i++) {
      backupCodes.push(
        Math.random().toString(36).substring(2, 10).toUpperCase()
      );
    }

    // Enable 2FA immediately
    await prisma.user.update({
      where: { user_id: userId },
      data: {
        two_factor_secret: secret.base32,
        two_factor_enabled: true, // Enable immediately
        two_factor_method: "app",
        two_factor_backup_codes: JSON.stringify(backupCodes),
      },
    });

    // Generate QR code URL
    const qrCodeUrl = secret.otpauth_url;

    res.json({
      success: true,
      qrCode: qrCodeUrl,
      secret: secret.base32,
      backupCodes: backupCodes,
    });
  } catch (error) {
    console.error("[API] 2FA Setup error:", error);
    res.status(500).json({ success: false, error: "2FA setup failed" });
  }
});

// Keep this endpoint for backward compatibility, but it's no longer used in the main flow
router.post("/auth/2fa/verify", authenticateUser, async (req, res) => {
  try {
    const userId = req.userId;
    const { token } = req.body;

    if (!userId || !token) {
      return res.status(400).json({ success: false, error: "Token required" });
    }

    const user = await prisma.user.findUnique({
      where: { user_id: userId },
      select: { two_factor_secret: true, two_factor_enabled: true },
    });

    if (!user?.two_factor_secret) {
      return res.status(400).json({ success: false, error: "2FA not set up" });
    }

    const verified = speakeasy.totp.verify({
      secret: user.two_factor_secret,
      encoding: "base32",
      token: token,
      window: 2,
    });

    if (verified) {
      res.json({
        success: true,
        message: "Token verified successfully",
        alreadyEnabled: user.two_factor_enabled,
      });
    } else {
      res.status(400).json({ success: false, error: "Invalid token" });
    }
  } catch (error) {
    console.error("[API] 2FA Verify error:", error);
    res.status(500).json({ success: false, error: "2FA verification failed" });
  }
});

router.post("/auth/2fa/disable", authenticateUser, async (req, res) => {
  try {
    const userId = req.userId;
    const { password } = req.body;

    if (!userId) {
      return res.status(401).json({ success: false, message: "Unauthorized" });
    }

    if (!password) {
      return res
        .status(400)
        .json({ success: false, message: "Password required" });
    }

    // Verify password before disabling 2FA
    const user = await prisma.user.findUnique({
      where: { user_id: userId },
      select: { password_hash: true },
    });

    const bcrypt = require("bcrypt");
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);

    if (!isPasswordValid) {
      return res
        .status(400)
        .json({ success: false, message: "Invalid password" });
    }

    await prisma.user.update({
      where: { user_id: userId },
      data: {
        two_factor_enabled: false,
        two_factor_secret: null,
        two_factor_backup_codes: null,
      },
    });

    res.json({ success: true, message: "2FA disabled successfully" });
  } catch (error) {
    console.error("[API] 2FA Disable error:", error);
    res.status(500).json({ success: false, message: "2FA disable failed" });
  }
});

// Get security settings
router.get("/auth/security-settings", authenticateUser, async (req, res) => {
  try {
    const userId = req.userId;

    if (!userId) {
      return res.status(401).json({ success: false, message: "Unauthorized" });
    }

    const user = await prisma.user.findUnique({
      where: { user_id: userId },
      select: {
        two_factor_enabled: true,
        two_factor_method: true,
        updated_at: true,
      },
    });

    if (!user) {
      return res
        .status(404)
        .json({ success: false, message: "User not found" });
    }

    res.json({
      success: true,
      twoFactorEnabled: user.two_factor_enabled || false,
      twoFactorMethod: user.two_factor_method || "app",
      lastPasswordChange: user.updated_at
        ? user.updated_at.toISOString()
        : null,
    });
  } catch (error) {
    console.error("[API] Security settings error:", error);
    res
      .status(500)
      .json({ success: false, message: "Failed to fetch security settings" });
  }
});

// Send email OTP for 2FA login
router.post("/auth/2fa/send-email-otp", async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res
        .status(400)
        .json({ success: false, message: "Email and password required" });
    }

    // Verify user credentials first
    const bcrypt = require("bcrypt");
    const user = await prisma.user.findUnique({
      where: { email: email.toLowerCase() },
      select: {
        user_id: true,
        name: true,
        email: true,
        password_hash: true,
        two_factor_enabled: true,
        two_factor_method: true,
      },
    });

    if (!user || !user.two_factor_enabled) {
      return res
        .status(400)
        .json({ success: false, message: "2FA not enabled for this user" });
    }

    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      return res
        .status(401)
        .json({ success: false, message: "Invalid credentials" });
    }

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiryTime = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

    // Store OTP in database (you might want to create a separate table for this)
    await prisma.user.update({
      where: { user_id: user.user_id },
      data: {
        email_otp_code: otp,
        email_otp_expires_at: expiryTime,
      },
    });

    // Send email with OTP
    try {
      await emailService.sendEmail({
        to: user.email,
        subject: "Your EventBn 2FA OTP",
        text: `Your OTP code is: ${otp}. It expires in 5 minutes.`,
      });
    } catch (err) {
      console.error("[2FA] Failed to send OTP email:", err);
      return res
        .status(500)
        .json({ success: false, message: "Failed to send OTP email" });
    }
    console.log(`[2FA] Email OTP for ${email}: ${otp}`); // For debugging

    res.json({
      success: true,
      message: "OTP sent to your email address",
      // In development, return OTP for testing
      ...(process.env.NODE_ENV === "development" && { otp: otp }),
    });
  } catch (error) {
    console.error("[API] Send email OTP error:", error);
    res.status(500).json({ success: false, message: "Failed to send OTP" });
  }
});

// Verify email OTP for 2FA login
router.post("/auth/2fa/verify-email-otp", async (req, res) => {
  try {
    const { email, password, otp } = req.body;

    if (!email || !password || !otp) {
      return res
        .status(400)
        .json({ success: false, message: "Email, password, and OTP required" });
    }

    // Verify user and OTP
    const bcrypt = require("bcrypt");
    const user = await prisma.user.findUnique({
      where: { email: email.toLowerCase() },
      select: {
        user_id: true,
        name: true,
        email: true,
        password_hash: true,
        two_factor_enabled: true,
        email_otp_code: true,
        email_otp_expires_at: true,
        role: true,
        profile_picture: true,
      },
    });

    if (!user || !user.two_factor_enabled) {
      return res
        .status(400)
        .json({ success: false, message: "Invalid request" });
    }

    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      return res
        .status(401)
        .json({ success: false, message: "Invalid credentials" });
    }

    // Check OTP
    if (!user.email_otp_code || user.email_otp_code !== otp) {
      return res.status(400).json({ success: false, message: "Invalid OTP" });
    }

    // Check OTP expiry
    if (!user.email_otp_expires_at || new Date() > user.email_otp_expires_at) {
      return res
        .status(400)
        .json({ success: false, message: "OTP has expired" });
    }

    // Clear OTP after successful verification
    await prisma.user.update({
      where: { user_id: user.user_id },
      data: {
        email_otp_code: null,
        email_otp_expires_at: null,
      },
    });

    // Generate JWT token
    const tokenPayload = {
      userId: user.user_id,
      email: user.email,
      name: user.name,
      role: user.role,
    };

    const jwt = require("jsonwebtoken");
    const token = jwt.sign(tokenPayload, process.env.JWT_SECRET, {
      expiresIn: "7d",
    });

    const userData = {
      id: user.user_id,
      user_id: user.user_id,
      name: user.name,
      email: user.email,
      role: user.role,
      profile_picture: user.profile_picture,
    };

    res.json({
      success: true,
      message: "Login successful",
      token: token,
      user: userData,
      data: userData,
    });
  } catch (error) {
    console.error("[API] Verify email OTP error:", error);
    res.status(500).json({ success: false, message: "Failed to verify OTP" });
  }
});

router.post("/auth/change-password", authenticateUser, async (req, res) => {
  try {
    console.log("[API] 🔄 Password change request received");
    console.log("[API] 📦 Raw request body:", req.body);
    console.log("[API] 📋 Request headers:", req.headers);

    // Use the standardized userId from middleware
    const userId = req.userId;
    const { currentPassword, newPassword } = req.body;

    console.log("[API] 👤 User ID:", userId);
    console.log(
      "[API] 📝 Extracted currentPassword:",
      currentPassword ? "***PROVIDED***" : "MISSING"
    );
    console.log(
      "[API] 📝 Extracted newPassword:",
      newPassword ? "***PROVIDED***" : "MISSING"
    );

    if (!userId || !currentPassword || !newPassword) {
      console.log("[API] ❌ Missing required fields");
      return res.status(400).json({
        success: false,
        error: "Current password and new password are required",
      });
    }

    // Verify current password
    console.log("[API] 🔍 Looking up user in database");
    const user = await prisma.user.findUnique({
      where: { user_id: userId },
      select: { password_hash: true },
    });

    if (!user) {
      console.log("[API] ❌ User not found");
      return res.status(404).json({ success: false, error: "User not found" });
    }

    console.log("[API] 🔐 Verifying current password");
    const bcrypt = require("bcrypt");
    const isCurrentPasswordValid = await bcrypt.compare(
      currentPassword,
      user.password_hash
    );

    if (!isCurrentPasswordValid) {
      console.log("[API] ❌ Current password is incorrect");
      return res
        .status(400)
        .json({ success: false, error: "Current password is incorrect" });
    }

    // Hash new password
    console.log("[API] 🔨 Hashing new password");
    const saltRounds = 10;
    const newPasswordHash = await bcrypt.hash(newPassword, saltRounds);

    // Update password
    console.log("[API] 💾 Updating password in database");
    await prisma.user.update({
      where: { user_id: userId },
      data: { password_hash: newPasswordHash },
    });

    console.log("[API] ✅ Password changed successfully");
    res.json({ success: true, message: "Password changed successfully" });
  } catch (error) {
    console.error("[API] ❌ Change password error:", error);
    res.status(500).json({ success: false, error: "Password change failed" });
  }
});

// Public Events routes (no authentication required)
// GET /events (public)
// Mobile app expects: { success: true, data: [ ... ] }
// Previously we returned { events: [...] }. We now return both for backward compatibility.
router.get("/events", async (req, res) => {
  try {
    const { page = 1, limit = 20, category, location } = req.query;
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    // Build where clause for filtering
    const where = {
      status: "ACTIVE",
    };

    if (category && category !== "all") {
      where.category = category;
    }

    if (location) {
      where.OR = [
        { location: { contains: location, mode: "insensitive" } },
        { venue: { contains: location, mode: "insensitive" } },
      ];
    }

    // Fetch events from database
    const events = await prisma.event.findMany({
      where,
      orderBy: { start_time: "asc" },
      skip,
      take: limitNum,
      select: {
        event_id: true,
        title: true,
        description: true,
        category: true,
        venue: true,
        location: true,
        start_time: true,
        end_time: true,
        capacity: true,
        cover_image_url: true,
        other_images_url: true,
        video_url: true,
        status: true,
        created_at: true,
        organization: {
          select: {
            name: true,
            logo_url: true,
          },
        },
      },
    });

    // If no events found, use fallback
    const finalEvents = events.length > 0 ? events : FALLBACK_EVENTS;

    res.json({
      success: true,
      fallback: events.length === 0,
      count: finalEvents.length,
      // Preferred key for mobile client
      data: finalEvents,
      // Backward compatibility with earlier microservice shape
      events: finalEvents,
      service: "core-service",
    });
  } catch (error) {
    console.error("[API] Error fetching events:", error);
    res.status(200).json({
      success: true,
      fallback: true,
      data: FALLBACK_EVENTS,
      events: FALLBACK_EVENTS,
      service: "core-service",
      warning: "Operating in fallback mode due to error",
      error: error.message,
    });
  }
});

// GET /events/:eventId (public)
router.get("/events/:eventId", async (req, res) => {
  try {
    const { eventId } = req.params;
    const eventIdNum = parseInt(eventId);

    if (isNaN(eventIdNum)) {
      return res.status(400).json({
        success: false,
        error: "Invalid event ID",
        message: "Event ID must be a number",
      });
    }

    // Fetch event from database
    const event = await prisma.event.findUnique({
      where: { event_id: eventIdNum },
      include: {
        organization: {
          select: {
            name: true,
            logo_url: true,
            contact_email: true,
            contact_number: true,
          },
        },
      },
    });

    if (!event) {
      return res.status(404).json({
        success: false,
        error: "Event not found",
        message: `Event with ID ${eventId} not found`,
      });
    }

    // Convert BigInt fields to numbers for JSON serialization
    const eventData = {
      ...event,
      event_id: Number(event.event_id),
    };

    res.json({
      success: true,
      data: eventData,
      event: eventData, // backward compatibility
      service: "core-service",
    });
  } catch (error) {
    console.error("[API] Error fetching event:", error);
    res.status(500).json({
      success: false,
      error: "Failed to fetch event",
      message: error.message,
      stack: process.env.NODE_ENV === "development" ? error.stack : undefined,
    });
  }
});

// --- Additional public event endpoints to match mobile client expectations ---

// Utility to obtain a unified events array (real or fallback)
async function getUnifiedEvents() {
  try {
    const events = await prisma.event.findMany({
      where: { status: "ACTIVE" },
      orderBy: { start_time: "asc" },
      take: 500,
      include: {
        organization: {
          select: {
            name: true,
            logo_url: true,
          },
        },
      },
    });
    return events.length > 0 ? events : FALLBACK_EVENTS;
  } catch (e) {
    console.warn("[API] getUnifiedEvents falling back:", e.message);
    return FALLBACK_EVENTS;
  }
}

// GET /events/featured - naive selection (first N or those with a future start_date)
router.get("/events/featured", async (req, res) => {
  try {
    const all = await getUnifiedEvents();
    const now = Date.now();
    let featured = all
      .filter((ev) => {
        const ts = Date.parse(ev.start_time || ev.start_date || "");
        return !isNaN(ts) && ts > now - 24 * 3600 * 1000; // within window
      })
      .slice(0, 10);

    // Optional summary view to mirror monolith UI adaptations
    if (req.query.view === "summary") {
      featured = featured.map((e) => ({
        ...e,
        displayDate: formatDisplayDate(e.start_time || e.start_date),
        displayLocation: e.location || e.venue || "TBD",
        price: deriveDisplayPrice(e),
        image:
          e.cover_image_url ||
          e.banner_url ||
          placeholderImageForCategory(e.category),
      }));
    }

    res.json({
      success: true,
      data: featured,
      events: featured,
      count: featured.length,
      service: "core-service",
    });
  } catch (e) {
    res.status(200).json({
      success: true,
      data: [],
      fallback: true,
      service: "core-service",
      error: e.message,
    });
  }
});

// GET /events/search/:query - simple case-insensitive match on title/description/category
router.get("/events/search/:query", async (req, res) => {
  try {
    const { query } = req.params;
    const q = (query || "").trim().toLowerCase();
    let all = await getUnifiedEvents();
    let results = all.filter((ev) =>
      [ev.title, ev.description, ev.category]
        .filter(Boolean)
        .some((val) => String(val).toLowerCase().includes(q))
    );

    if (req.query.view === "summary") {
      results = results.map((e) => ({
        ...e,
        displayDate: formatDisplayDate(e.start_time || e.start_date),
        displayLocation: e.location || e.venue || "TBD",
        price: deriveDisplayPrice(e),
        image:
          e.cover_image_url ||
          e.banner_url ||
          placeholderImageForCategory(e.category),
      }));
    }

    res.json({
      success: true,
      data: results,
      events: results,
      count: results.length,
      service: "core-service",
    });
  } catch (e) {
    res.status(200).json({
      success: true,
      data: [],
      fallback: true,
      service: "core-service",
      error: e.message,
    });
  }
});

// GET /events/category/:category - filter by category (exact, case-insensitive)
router.get("/events/category/:category", async (req, res) => {
  try {
    const { category } = req.params;
    const cat = (category || "").trim().toLowerCase();
    let all = await getUnifiedEvents();
    let results = all.filter((ev) => (ev.category || "").toLowerCase() === cat);

    if (req.query.view === "summary") {
      results = results.map((e) => ({
        ...e,
        displayDate: formatDisplayDate(e.start_time || e.start_date),
        displayLocation: e.location || e.venue || "TBD",
        price: deriveDisplayPrice(e),
        image:
          e.cover_image_url ||
          e.banner_url ||
          placeholderImageForCategory(e.category),
      }));
    }

    res.json({
      success: true,
      data: results,
      events: results,
      count: results.length,
      service: "core-service",
    });
  } catch (e) {
    res.status(200).json({
      success: true,
      data: [],
      fallback: true,
      service: "core-service",
      error: e.message,
    });
  }
});

// GET /events/:eventId/attendees - fetch real attendees from ticket purchases
router.get("/events/:eventId/attendees", async (req, res) => {
  try {
    const eventId = parseInt(req.params.eventId);
    if (isNaN(eventId)) {
      return res.status(400).json({
        success: false,
        error: "Invalid event ID",
      });
    }

    // Fetch attendees from ticket_purchase table with user information
    const attendees = await prisma.ticket_purchase.findMany({
      where: {
        event_id: eventId,
      },
      include: {
        User: {
          select: {
            user_id: true,
            name: true,
            email: true,
            profile_picture: true,
          },
        },
      },
      orderBy: {
        purchase_date: "desc",
      },
    });

    // Transform the data to match frontend expectations
    const transformedAttendees = attendees.map((ticket) => ({
      id: ticket.User.user_id.toString(),
      username: ticket.User.name || "Unknown User",
      name: ticket.User.name || "Unknown User",
      avatar:
        ticket.User.profile_picture ||
        `https://i.pravatar.cc/100?u=${ticket.User.user_id}`,
      profilePicture:
        ticket.User.profile_picture ||
        `https://i.pravatar.cc/100?u=${ticket.User.user_id}`,
      email: ticket.User.email,
      ticketId: ticket.ticket_id,
      seatLabel: ticket.seat_label,
      attended: ticket.attended || false,
      purchaseDate: ticket.purchase_date,
      // Mock social data (would come from a separate social service in real app)
      isFollowing: Math.random() > 0.7, // 30% chance
      isFriend: Math.random() > 0.8, // 20% chance
      mutualFriends: Math.floor(Math.random() * 20),
    }));

    // Remove duplicates by user_id (in case user bought multiple tickets)
    const uniqueAttendees = transformedAttendees.reduce((acc, current) => {
      const existing = acc.find((item) => item.id === current.id);
      if (!existing) {
        acc.push(current);
      }
      return acc;
    }, []);

    // If no real attendees found, provide sample data for testing
    if (uniqueAttendees.length === 0) {
      const sampleAttendees = [
        {
          id: "101",
          username: "Alex Johnson",
          name: "Alex Johnson",
          avatar: "https://i.pravatar.cc/100?u=101",
          profilePicture: "https://i.pravatar.cc/100?u=101",
          email: "alex@example.com",
          isFollowing: false,
          isFriend: false,
          mutualFriends: 5,
        },
        {
          id: "102",
          username: "Sarah Wilson",
          name: "Sarah Wilson",
          avatar: "https://i.pravatar.cc/100?u=102",
          profilePicture: "https://i.pravatar.cc/100?u=102",
          email: "sarah@example.com",
          isFollowing: true,
          isFriend: true,
          mutualFriends: 12,
        },
        {
          id: "103",
          username: "Mike Chen",
          name: "Mike Chen",
          avatar: "https://i.pravatar.cc/100?u=103",
          profilePicture: "https://i.pravatar.cc/100?u=103",
          email: "mike@example.com",
          isFollowing: false,
          isFriend: false,
          mutualFriends: 3,
        },
        {
          id: "104",
          username: "Emma Davis",
          name: "Emma Davis",
          avatar: "https://i.pravatar.cc/100?u=104",
          profilePicture: "https://i.pravatar.cc/100?u=104",
          email: "emma@example.com",
          isFollowing: true,
          isFriend: false,
          mutualFriends: 8,
        },
        {
          id: "105",
          username: "John Smith",
          name: "John Smith",
          avatar: "https://i.pravatar.cc/100?u=105",
          profilePicture: "https://i.pravatar.cc/100?u=105",
          email: "john@example.com",
          isFollowing: false,
          isFriend: true,
          mutualFriends: 15,
        },
      ];

      res.json({
        success: true,
        data: sampleAttendees,
        count: sampleAttendees.length,
        service: "core-service",
        note: "Sample attendees (no real ticket purchases found for this event)",
      });
    } else {
      res.json({
        success: true,
        data: uniqueAttendees,
        count: uniqueAttendees.length,
        service: "core-service",
        note: "Real attendees from ticket purchases",
      });
    }
  } catch (e) {
    console.error("[API] Error fetching attendees:", e);

    // Fallback to sample data if database query fails
    const sampleAttendees = [
      {
        id: "1",
        username: "Alex Johnson",
        name: "Alex Johnson",
        avatar: "https://i.pravatar.cc/100?img=1",
        profilePicture: "https://i.pravatar.cc/100?img=1",
        isFollowing: false,
        isFriend: false,
        mutualFriends: 5,
      },
      {
        id: "2",
        username: "Sarah Wilson",
        name: "Sarah Wilson",
        avatar: "https://i.pravatar.cc/100?img=2",
        profilePicture: "https://i.pravatar.cc/100?img=2",
        isFollowing: true,
        isFriend: true,
        mutualFriends: 12,
      },
      {
        id: "3",
        username: "Mike Chen",
        name: "Mike Chen",
        avatar: "https://i.pravatar.cc/100?img=3",
        profilePicture: "https://i.pravatar.cc/100?img=3",
        isFollowing: false,
        isFriend: false,
        mutualFriends: 3,
      },
    ];

    res.json({
      success: true,
      data: sampleAttendees,
      service: "core-service",
      note: "Fallback sample data due to database error: " + e.message,
    });
  }
});

// GET /events/:eventId/seatmap - returns seat_map if present or empty list
router.get("/events/:eventId/seatmap", async (req, res) => {
  try {
    const { eventId } = req.params;
    const eventIdNum = parseInt(eventId);

    if (isNaN(eventIdNum)) {
      return res.status(400).json({
        success: false,
        error: "Invalid event ID",
        message: "Event ID must be a number",
      });
    }

    // Fetch event directly from database
    const event = await prisma.event.findUnique({
      where: { event_id: eventIdNum },
      select: {
        event_id: true,
        title: true,
        seat_map: true,
        ticket_types: true,
      },
    });

    if (!event) {
      return res.status(404).json({
        success: false,
        error: "Event not found",
        message: `Event with ID ${eventId} not found`,
      });
    }

    // Fetch booked seats for this event (from completed/pending payments)
    const bookedSeats = await prisma.ticket_purchase.findMany({
      where: {
        event_id: eventIdNum,
        payment: {
          status: {
            in: ["pending", "completed"],
          },
        },
      },
      select: {
        seat_id: true,
        seat_label: true,
      },
    });

    // Create sets of booked seat IDs and labels for quick lookup
    // Handle both string and numeric IDs to avoid type mismatch issues
    const bookedSeatIds = new Set();
    const bookedSeatLabels = new Set();

    bookedSeats.forEach((seat) => {
      // Add seat_id in multiple formats
      if (seat.seat_id != null) {
        bookedSeatIds.add(seat.seat_id); // Original value
        bookedSeatIds.add(String(seat.seat_id)); // String version
        bookedSeatIds.add(Number(seat.seat_id)); // Numeric version (if valid)
      }

      // Add seat_label in multiple formats
      if (seat.seat_label != null) {
        bookedSeatLabels.add(seat.seat_label); // Original value
        bookedSeatLabels.add(String(seat.seat_label)); // String version
        // Also add numeric version if it's a valid number
        const numericLabel = Number(seat.seat_label);
        if (!isNaN(numericLabel)) {
          bookedSeatLabels.add(numericLabel);
        }
      }
    });

    console.log(
      `[SEATMAP] Event ${eventId} - Found ${bookedSeats.length} booked seats:`,
      "IDs:",
      Array.from(bookedSeatIds),
      "Labels:",
      Array.from(bookedSeatLabels)
    );

    const rawSeatMap = Array.isArray(event.seat_map) ? event.seat_map : null;
    const ticketTypesRaw = event.ticket_types || null;

    // Debug: Log seat map structure
    if (rawSeatMap) {
      console.log(`[SEATMAP] Raw seat map has ${rawSeatMap.length} seats`);
      console.log(
        `[SEATMAP] Sample seat map entries:`,
        rawSeatMap.slice(0, 5).map((s, i) => ({
          index: i,
          id: s.id,
          label: s.label,
          seat_id: s.seat_id,
          seat_label: s.seat_label,
          available: s.available,
        }))
      );
    }

    // Derive ticket types mapping (key -> { price, count }) for non custom seating
    function deriveTicketTypes(seatMapArray) {
      if (!Array.isArray(seatMapArray)) return {};
      const map = {};
      for (const seat of seatMapArray) {
        const type = seat.ticketType || seat.type || seat.category || "General";
        if (!map[type]) {
          map[type] = { count: 0, price: seat.price ?? seat.cost ?? 0 };
        }
        map[type].count += 1;
        // Prefer lowest price if varying
        if (seat.price != null && seat.price < map[type].price)
          map[type].price = seat.price;
      }
      return map;
    }

    let responsePayload;
    if (rawSeatMap) {
      // Custom seating mode - mark booked seats as unavailable
      responsePayload = {
        hasCustomSeating: true,
        layout: "theater",
        layoutConfig: {},
        seats: rawSeatMap.map((s, index) => {
          // Get all possible identifiers for this seat
          const seatId = s.id;
          const seatLabel = s.label;

          // Create comprehensive list of possible identifiers
          const possibleIds = [
            seatId,
            String(seatId),
            Number(seatId),
            s.seat_id,
            String(s.seat_id),
            Number(s.seat_id),
            index, // Array index (0-based)
            index + 1, // Array index (1-based)
            String(index),
            String(index + 1),
          ].filter(
            (id) => id !== undefined && id !== null && !isNaN(id) && id !== ""
          );

          const possibleLabels = [
            seatLabel,
            String(seatLabel),
            Number(seatLabel),
            s.seat_label,
            String(s.seat_label),
            Number(s.seat_label),
          ].filter(
            (label) => label !== undefined && label !== null && label !== ""
          );

          // Check if any identifier matches booked seats
          const isBookedById = possibleIds.some(
            (id) =>
              bookedSeatIds.has(id) ||
              bookedSeatIds.has(String(id)) ||
              bookedSeatIds.has(Number(id))
          );
          const isBookedByLabel = possibleLabels.some(
            (label) =>
              bookedSeatLabels.has(label) || bookedSeatLabels.has(String(label))
          );

          const isBooked = isBookedById || isBookedByLabel;

          // Enhanced debug logging for all seats to understand the mapping
          const debugInfo = {
            seatMapIndex: index,
            seatData: {
              id: seatId,
              label: seatLabel,
              seat_id: s.seat_id,
              seat_label: s.seat_label,
            },
            possibleIds: possibleIds,
            possibleLabels: possibleLabels,
            isBookedById: isBookedById,
            isBookedByLabel: isBookedByLabel,
            isBooked: isBooked,
          };

          if (isBooked) {
            console.log(`[SEATMAP] ✅ Marking seat as BOOKED:`, debugInfo);
          } else {
            // Also log available seats that might match some booked seat patterns
            const hasMatchingPattern =
              possibleIds.some((id) =>
                Array.from(bookedSeatIds).some(
                  (bookedId) => String(id) === String(bookedId)
                )
              ) ||
              possibleLabels.some((label) =>
                Array.from(bookedSeatLabels).some(
                  (bookedLabel) => String(label) === String(bookedLabel)
                )
              );

            if (hasMatchingPattern) {
              console.log(
                `[SEATMAP] 🤔 Seat looks like it should be booked but isn't marked:`,
                debugInfo
              );
            }
          }

          return {
            ...s,
            available: !isBooked && s.available !== false, // Mark as unavailable if booked
          };
        }),
        ticketTypes: Object.keys(deriveTicketTypes(rawSeatMap)).length
          ? deriveTicketTypes(rawSeatMap)
          : undefined,
      };
    } else {
      // No explicit seat_map -> treat as ticket type (general admission) flow
      let ticketTypes = {};
      if (Array.isArray(ticketTypesRaw)) {
        // Array of objects each with name/label & price
        for (const t of ticketTypesRaw) {
          const key = t.name || t.label || t.type || "General";
          ticketTypes[key] = { price: t.price || t.price_cents / 100 || 0 };
        }
      } else if (ticketTypesRaw && typeof ticketTypesRaw === "object") {
        ticketTypes = ticketTypesRaw; // already a mapping
      } else {
        // Fallback single general ticket
        ticketTypes = { General: { price: 0 } };
      }
      responsePayload = {
        hasCustomSeating: false,
        ticketTypes,
        seats: [],
      };
    }

    res.json({
      success: true,
      data: responsePayload,
      eventId,
      service: "core-service",
    });
  } catch (e) {
    console.error("[SEATMAP ERROR]", e);
    res.status(500).json({
      success: false,
      error: "Failed to fetch seatmap",
      message: e.message,
    });
  }
});

// GET /events/:eventId/booked-seats - DB-backed (ticket_purchase + payment status)
router.get("/events/:eventId/booked-seats", async (req, res) => {
  try {
    const { eventId } = req.params;
    const rows = await prisma.ticket_purchase.findMany({
      where: {
        event_id: parseInt(eventId),
        payment: { status: { in: ["pending", "completed"] } },
      },
      select: { seat_id: true, seat_label: true, purchase_date: true },
    });
    const data = rows.map((r) => ({
      seat_id: r.seat_id,
      seat_label: r.seat_label,
      booked_at: r.purchase_date,
    }));
    res.json({
      success: true,
      data,
      count: data.length,
      service: "core-service",
    });
  } catch (e) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch booked seats",
      error: e.message,
    });
  }
});

// Protected routes (require authentication)
router.use(authenticateUser);

// (Temporary removal) Ticket & Payment routes will be re-added with DB logic below
// ---------------------------------------------------------------------------
// DB-Backed Payments & Tickets
// Endpoints implemented (JWT protected except where noted):
//   POST   /payments                     -> create payment + ticket purchases
//   GET    /payments/my-payments         -> list user payments
//   GET    /payments/:payment_id         -> single payment (ownership enforced)
//   GET    /tickets/my-tickets           -> list user tickets
//   GET    /tickets/:ticketId            -> single ticket (ownership enforced)
//   GET    /tickets/qr/:qrCode           -> lookup by qr code (ownership enforced)
//   GET    /tickets/by-payment/:paymentId-> first ticket for payment (client parity)
//   PUT    /tickets/:ticketId/attend     -> mark attended (future: organizer authorization)
// Notes:
//  - Prices stored as BigInt cents; returned as integer (client divides if needed)
//  - Seat availability enforced by reading event.seat_map JSON and ensuring seats not already taken
//  - seat_map is updated (if JSON is structured) to mark seats as booked
//  - Basic optimistic locking via transaction + re-check of free seats
// ---------------------------------------------------------------------------

// Helper to extract seat list from event.seat_map JSON structure used by monolith sample maps
function extractSeatNodes(seatMapJson) {
  if (!seatMapJson) return [];
  try {
    // Expect format { sections: [ { rows: [ { seats: [ { id, label, booked } ] } ] } ] }
    const sections = seatMapJson.sections || [];
    const seats = [];
    for (const section of sections) {
      for (const row of section.rows || []) {
        for (const seat of row.seats || []) seats.push(seat);
      }
    }
    // -------------------------------------------------------------
    // Seat Locking (ported from monolith direct endpoints)
    // Endpoints (prefix inside this unified router):
    //   POST   /seat-locks/events/:eventId/seats/:seatId/lock        (auth)
    //   GET    /seat-locks/events/:eventId/seats/:seatId/lock        (public status)
    //   PUT    /seat-locks/events/:eventId/seats/:seatId/lock/extend (auth)
    //   DELETE /seat-locks/events/:eventId/seats/:seatId/lock        (auth)
    //   GET    /seat-locks/events/:eventId/locks                     (public list)
    // Uses Redis (or in-memory fallback) via seatLockService with TTL auto-expiration.
    // -------------------------------------------------------------
    const seatLockService = require("../seat-locks/seatLockService");

    // POST lock a seat
    router.post(
      "/seat-locks/events/:eventId/seats/:seatId/lock",
      authenticateUser,
      async (req, res) => {
        try {
          console.log("[SEAT LOCK] Request received:", {
            eventId: req.params.eventId,
            seatId: req.params.seatId,
            userId: req.userId,
          });

          const { eventId, seatId } = req.params;
          const userId = String(req.userId);

          if (!eventId || !seatId) {
            console.log("[SEAT LOCK] Missing parameters");
            return res
              .status(400)
              .json({ success: false, message: "eventId & seatId required" });
          }

          console.log("[SEAT LOCK] Checking seat lock status...");
          const status = await seatLockService.isSeatLocked(eventId, seatId);
          console.log("[SEAT LOCK] Current status:", status);

          if (status.locked) {
            if (String(status.userId) === userId) {
              console.log("[SEAT LOCK] Seat already locked by user");
              return res.json({
                success: true,
                message: "Seat already locked by you",
                lockInfo: { eventId, seatId, userId, ttl: status.ttl },
              });
            }
            return res.status(409).json({
              success: false,
              message: "Seat is temporarily locked",
              ttl: status.ttl,
            });
          }

          console.log("[SEAT LOCK] Attempting to lock seat...");
          const locked = await seatLockService.lockSeat(
            eventId,
            seatId,
            userId
          );
          console.log("[SEAT LOCK] Lock result:", locked);

          if (!locked) {
            console.log("[SEAT LOCK] Failed to lock seat");
            return res
              .status(409)
              .json({ success: false, message: "Failed to lock seat" });
          }

          console.log("[SEAT LOCK] Seat locked successfully");
          res.json({
            success: true,
            message: "Seat locked successfully",
            lockInfo: { eventId, seatId, userId, duration: "1 minute" },
          });
        } catch (err) {
          console.error("[SEAT LOCK ERROR]", err);
          res.status(500).json({
            success: false,
            message: "Internal server error",
            error: err.message,
            stack:
              process.env.NODE_ENV === "development" ? err.stack : undefined,
          });
        }
      }
    );

    // GET seat lock status (public)
    router.get(
      "/seat-locks/events/:eventId/seats/:seatId/lock",
      async (req, res) => {
        try {
          const { eventId, seatId } = req.params;
          const status = await seatLockService.isSeatLocked(eventId, seatId);
          return res.json({
            success: true,
            lockStatus: {
              locked: status.locked,
              ttl: status.ttl || null,
              ...(status.locked
                ? { userId: status.userId, timestamp: status.timestamp }
                : {}),
            },
          });
        } catch (err) {
          res.status(500).json({
            success: false,
            message: "Internal server error",
            error: err.message,
          });
        }
      }
    );

    // PUT extend lock (payment phase)
    router.put(
      "/seat-locks/events/:eventId/seats/:seatId/lock/extend",
      authenticateUser,
      async (req, res) => {
        try {
          const { eventId, seatId } = req.params;
          const userId = String(req.userId);
          const extended = await seatLockService.extendLock(
            eventId,
            seatId,
            userId
          );
          if (!extended)
            return res
              .status(403)
              .json({ success: false, message: "Cannot extend lock" });
          res.json({
            success: true,
            message: "Lock extended",
            duration: "10 minutes",
          });
        } catch (err) {
          res.status(500).json({
            success: false,
            message: "Internal server error",
            error: err.message,
          });
        }
      }
    );

    // DELETE release lock
    router.delete(
      "/seat-locks/events/:eventId/seats/:seatId/lock",
      authenticateUser,
      async (req, res) => {
        try {
          const { eventId, seatId } = req.params;
          const userId = String(req.userId);
          const released = await seatLockService.releaseLock(
            eventId,
            seatId,
            userId
          );
          if (!released)
            return res
              .status(403)
              .json({ success: false, message: "Cannot release lock" });
          res.json({ success: true, message: "Lock released" });
        } catch (err) {
          res.status(500).json({
            success: false,
            message: "Internal server error",
            error: err.message,
          });
        }
      }
    );

    // GET all locked seats for event (public, userId not exposed)
    router.get("/seat-locks/events/:eventId/locks", async (req, res) => {
      try {
        const { eventId } = req.params;
        const locks = await seatLockService.getEventLockedSeats(eventId);
        res.json({
          success: true,
          eventId,
          lockedSeats: locks.map((l) => ({
            seatId: l.seatId,
            ttl: l.ttl,
            timestamp: l.timestamp,
          })),
        });
      } catch (err) {
        res.status(500).json({
          success: false,
          message: "Internal server error",
          error: err.message,
        });
      }
    });

    return seats;
  } catch {
    return [];
  }
}

// -------------------------------------------------------------
// Seat Locking Routes
// Endpoints:
//   POST   /seat-locks/events/:eventId/seats/:seatId/lock        (auth)
//   GET    /seat-locks/events/:eventId/seats/:seatId/lock        (public status)
//   PUT    /seat-locks/events/:eventId/seats/:seatId/lock/extend (auth)
//   DELETE /seat-locks/events/:eventId/seats/:seatId/lock        (auth)
//   GET    /seat-locks/events/:eventId/locks                     (public list)
// Uses Redis (or in-memory fallback) via seatLockService with TTL auto-expiration.
// -------------------------------------------------------------

// POST lock a seat
router.post(
  "/seat-locks/events/:eventId/seats/:seatId/lock",
  authenticateUser,
  async (req, res) => {
    try {
      console.log("[SEAT LOCK] Request received:", {
        eventId: req.params.eventId,
        seatId: req.params.seatId,
        userId: req.userId,
      });

      const { eventId, seatId } = req.params;
      const userId = String(req.userId);

      if (!eventId || !seatId) {
        console.log("[SEAT LOCK] Missing parameters");
        return res
          .status(400)
          .json({ success: false, message: "eventId & seatId required" });
      }

      const status = await seatLockService.isSeatLocked(eventId, seatId);
      if (status.locked) {
        if (String(status.userId) === userId) {
          return res.json({
            success: true,
            message: "Seat already locked by you",
            lockInfo: { eventId, seatId, userId },
            ttl: status.ttl,
          });
        } else {
          return res.status(409).json({
            success: false,
            message: "Seat is already locked by another user",
            lockInfo: { eventId, seatId, lockedBy: status.userId },
            ttl: status.ttl,
          });
        }
      }

      console.log("[SEAT LOCK] Attempting to lock seat...");
      const locked = await seatLockService.lockSeat(eventId, seatId, userId);
      console.log("[SEAT LOCK] Lock result:", locked);

      if (!locked) {
        console.log("[SEAT LOCK] Failed to lock seat");
        return res
          .status(409)
          .json({ success: false, message: "Failed to lock seat" });
      }

      console.log("[SEAT LOCK] Seat locked successfully");
      res.json({
        success: true,
        message: "Seat locked successfully",
        lockInfo: { eventId, seatId, userId, duration: "1 minute" },
      });
    } catch (err) {
      console.error("[SEAT LOCK ERROR]", err);
      res.status(500).json({
        success: false,
        message: "Internal server error",
        error: err.message,
        stack: process.env.NODE_ENV === "development" ? err.stack : undefined,
      });
    }
  }
);

// GET seat lock status (public)
router.get(
  "/seat-locks/events/:eventId/seats/:seatId/lock",
  async (req, res) => {
    try {
      const { eventId, seatId } = req.params;
      if (!eventId || !seatId) {
        return res
          .status(400)
          .json({ success: false, message: "eventId & seatId required" });
      }
      const status = await seatLockService.isSeatLocked(eventId, seatId);
      res.json({
        success: true,
        locked: status.locked,
        lockInfo: status.locked
          ? { eventId, seatId, userId: status.userId, ttl: status.ttl }
          : null,
      });
    } catch (err) {
      res
        .status(500)
        .json({ success: false, message: "Server error", error: err.message });
    }
  }
);

// PUT extend seat lock (auth)
router.put(
  "/seat-locks/events/:eventId/seats/:seatId/lock/extend",
  authenticateUser,
  async (req, res) => {
    try {
      const { eventId, seatId } = req.params;
      const userId = String(req.userId);
      if (!eventId || !seatId) {
        return res
          .status(400)
          .json({ success: false, message: "eventId & seatId required" });
      }
      const extended = await seatLockService.extendLock(
        eventId,
        seatId,
        userId
      );
      if (!extended) {
        return res
          .status(409)
          .json({ success: false, message: "Lock not found or not owned" });
      }
      res.json({ success: true, message: "Lock extended successfully" });
    } catch (err) {
      res
        .status(500)
        .json({ success: false, message: "Server error", error: err.message });
    }
  }
);

// DELETE unlock seat (auth)
router.delete(
  "/seat-locks/events/:eventId/seats/:seatId/lock",
  authenticateUser,
  async (req, res) => {
    try {
      const { eventId, seatId } = req.params;
      const userId = String(req.userId);
      if (!eventId || !seatId) {
        return res
          .status(400)
          .json({ success: false, message: "eventId & seatId required" });
      }
      const unlocked = await seatLockService.unlockSeat(
        eventId,
        seatId,
        userId
      );
      if (!unlocked) {
        return res
          .status(409)
          .json({ success: false, message: "Lock not found or not owned" });
      }
      res.json({ success: true, message: "Seat unlocked successfully" });
    } catch (err) {
      res
        .status(500)
        .json({ success: false, message: "Server error", error: err.message });
    }
  }
);

// GET all locks for an event (public list)
router.get("/seat-locks/events/:eventId/locks", async (req, res) => {
  try {
    const { eventId } = req.params;
    if (!eventId) {
      return res
        .status(400)
        .json({ success: false, message: "eventId required" });
    }
    const locks = await seatLockService.getEventLockedSeats(eventId);
    res.json({
      success: true,
      eventId,
      locks: locks.map((lock) => ({
        seatId: lock.seatId,
        userId: lock.userId,
        ttl: lock.ttl,
      })),
    });
  } catch (err) {
    res
      .status(500)
      .json({ success: false, message: "Server error", error: err.message });
  }
});

function markSeatsBooked(seatMapJson, seatIds) {
  if (!seatMapJson) return seatMapJson;
  try {
    const set = new Set(seatIds.map((s) => parseInt(s) || s));
    console.log(
      `[MARK_SEATS_BOOKED] Marking seats as booked: ${Array.from(set)}`
    );

    // Handle flat array format (direct seats array)
    if (Array.isArray(seatMapJson)) {
      for (const seat of seatMapJson) {
        if (set.has(seat.id) || set.has(seat.seat_id) || set.has(seat.label)) {
          seat.booked = true;
          seat.available = false; // Also set available to false for consistency
          console.log(
            `[MARK_SEATS_BOOKED] Marked seat ${seat.id || seat.label} as booked`
          );
        }
      }
      return seatMapJson;
    }

    // Handle nested structure format (sections -> rows -> seats)
    for (const section of seatMapJson.sections || []) {
      for (const row of section.rows || []) {
        for (const seat of row.seats || []) {
          if (
            set.has(seat.id) ||
            set.has(seat.seat_id) ||
            set.has(seat.label)
          ) {
            seat.booked = true;
            seat.available = false; // Also set available to false for consistency
            console.log(
              `[MARK_SEATS_BOOKED] Marked seat ${
                seat.id || seat.label
              } as booked`
            );
          }
        }
      }
    }
    return seatMapJson;
  } catch (e) {
    console.error("[MARK_SEATS_BOOKED] Error:", e);
    return seatMapJson;
  }
}

// POST /payments
router.post("/payments", authenticateUser, express.json(), async (req, res) => {
  try {
    const userId = parseInt(req.userId);
    const {
      event_id,
      selected_seats,
      selectedSeatData,
      payment_method = "card",
    } = req.body || {};

    console.log(
      `[PAYMENT] User ${userId} creating payment for event ${event_id}`
    );
    console.log(`[PAYMENT] Selected seats: ${JSON.stringify(selected_seats)}`);
    console.log(
      `[PAYMENT] Selected seat data: ${JSON.stringify(selectedSeatData)}`
    );

    if (
      !event_id ||
      !Array.isArray(selected_seats) ||
      selected_seats.length === 0
    ) {
      return res.status(400).json({
        success: false,
        error: "event_id and selected_seats[] required",
        message: "event_id and selected_seats[] required",
      });
    }
    // Fetch event & current booked seats
    const event = await prisma.event.findUnique({
      where: { event_id: parseInt(event_id) },
      select: { event_id: true, seat_map: true, title: true },
    });
    if (!event)
      return res.status(404).json({
        success: false,
        error: "Event not found",
        message: "Event not found",
      });
    // ------------------------------------------------------
    // Seat lock validation (configurable)
    // Set ENFORCE_SEAT_LOCKS=false to bypass in dev OR add ?skipLockValidation=1
    // If enforcement enabled and locks missing, will try auto-lock before failing.
    // ------------------------------------------------------
    const enforceLocks =
      (process.env.ENFORCE_SEAT_LOCKS || "true") !== "false" &&
      req.query.skipLockValidation !== "1";
    const lockDebug = {
      enforceLocks,
      checked: [],
      autoLocked: [],
      missing: [],
    };
    if (event.seat_map && enforceLocks) {
      for (const seatId of selected_seats) {
        try {
          const lockStatus = await seatLockService.isSeatLocked(
            String(event.event_id),
            String(seatId)
          );
          lockDebug.checked.push({
            seatId,
            locked: lockStatus.locked,
            owner: lockStatus.userId,
          });
          if (!lockStatus.locked) {
            // Attempt auto-lock (best effort) to reduce friction
            const auto = await seatLockService.lockSeat(
              String(event.event_id),
              String(seatId),
              String(req.userId)
            );
            if (auto) {
              lockDebug.autoLocked.push(seatId);
              continue;
            }
            lockDebug.missing.push(seatId);
          } else if (String(lockStatus.userId) !== String(req.userId)) {
            lockDebug.missing.push(seatId);
          }
        } catch (e) {
          lockDebug.missing.push(seatId);
        }
      }
      if (lockDebug.missing.length) {
        return res.status(409).json({
          success: false,
          error: "Seat lock validation failed",
          message: "Some seats are not locked by you. Re-select seats.",
          details: lockDebug,
          hint: "For development you can set ENFORCE_SEAT_LOCKS=false or add ?skipLockValidation=1",
        });
      }
    }

    // Collect already booked seats (pending/completed payments)
    const existingTickets = await prisma.ticket_purchase.findMany({
      where: {
        event_id: event.event_id,
        payment: { status: { in: ["pending", "completed"] } },
      },
      select: { seat_id: true, seat_label: true },
    });

    console.log(
      `[PAYMENT_CONFLICT_CHECK] Existing tickets for event ${event.event_id}:`,
      existingTickets.map((t) => ({
        seat_id: t.seat_id,
        seat_label: t.seat_label,
      }))
    );

    const taken = new Set(
      existingTickets.map((t) => String(t.seat_id || t.seat_label))
    );

    console.log(
      `[PAYMENT_CONFLICT_CHECK] Taken seats (as strings):`,
      Array.from(taken)
    );
    console.log(
      `[PAYMENT_CONFLICT_CHECK] Checking selected seats:`,
      selected_seats
    );

    const conflicts = selected_seats.filter((s) => {
      const asString = String(s);
      const isTaken = taken.has(asString);
      console.log(
        `[PAYMENT_CONFLICT_CHECK] Seat ${s} (as string: "${asString}") - taken: ${isTaken}`
      );
      return isTaken;
    });

    console.log(`[PAYMENT_CONFLICT_CHECK] Conflicts found:`, conflicts);

    if (conflicts.length) {
      return res.status(409).json({
        success: false,
        error: "Some seats already booked",
        conflicts,
      });
    }

    // Determine price per seat from selectedSeatData or default (1000 cents placeholder)
    let totalCents = 0;
    const ticketRows = selected_seats.map((seatIdOrLabel, idx) => {
      const seatInfo =
        selectedSeatData && selectedSeatData[idx]
          ? selectedSeatData[idx]
          : null;
      const priceCents = seatInfo?.price_cents
        ? parseInt(seatInfo.price_cents)
        : seatInfo?.price
        ? Math.round(parseFloat(seatInfo.price) * 100)
        : 1000;
      totalCents += priceCents;

      // Use seat label from seatInfo if available, otherwise use the seat ID/label as is
      const displayLabel =
        seatInfo?.label || seatInfo?.seat_label || String(seatIdOrLabel);

      return {
        seatIdOrLabel, // Original ID or label from selected_seats
        displayLabel, // Human-readable label for display
        seatInfo,
        priceCents,
      };
    });

    // Persist inside transaction
    const result = await prisma.$transaction(async (tx) => {
      // Re-check seats inside transaction for race condition
      const concurrent = await tx.ticket_purchase.findMany({
        where: {
          event_id: event.event_id,
          payment: { status: { in: ["pending", "completed"] } },
        },
        select: { seat_id: true, seat_label: true },
      });
      const takenNow = new Set(
        concurrent.map((t) => String(t.seat_id || t.seat_label))
      );
      const conflictsNow = selected_seats.filter((s) =>
        takenNow.has(String(s))
      );
      if (conflictsNow.length) {
        throw new Error(
          "Seat(s) just booked by another user: " + conflictsNow.join(",")
        );
      }

      const payment = await tx.payment.create({
        data: {
          user_id: userId,
          event_id: event.event_id,
          amount: (totalCents / 100).toFixed(2), // store as decimal string
          status: "completed",
          payment_method,
          transaction_ref: "TX-" + Date.now(),
        },
      });

      const createdTickets = [];
      for (const row of ticketRows) {
        // Parse seat ID from the seat info or from the original seat identifier
        const seatIdParsed = row.seatInfo?.id
          ? parseInt(row.seatInfo.id)
          : isNaN(parseInt(row.seatIdOrLabel))
          ? null
          : parseInt(row.seatIdOrLabel);

        console.log(
          `[TICKET_CREATE] Creating ticket for seat: ${row.seatIdOrLabel}, label: ${row.displayLabel}, parsed ID: ${seatIdParsed}`
        );

        const ticket = await tx.ticket_purchase.create({
          data: {
            event_id: event.event_id,
            user_id: userId,
            payment_id: payment.payment_id,
            seat_id: seatIdParsed,
            seat_label: row.displayLabel, // Use the human-readable label
            purchase_date: new Date(),
            price: BigInt(row.priceCents),
            attended: false,
            qr_code: "QR-" + Math.random().toString(36).slice(2, 10),
          },
        });
        createdTickets.push(ticket);
      }

      // Update seat_map JSON if exists, marking seats as booked
      if (event.seat_map) {
        let seatMapObj = event.seat_map;
        seatMapObj = markSeatsBooked(seatMapObj, selected_seats);
        await tx.event.update({
          where: { event_id: event.event_id },
          data: { seat_map: seatMapObj },
        });
      }

      return { payment, tickets: createdTickets };
    });

    // Enrich tickets with event info (single query fetch)
    const eventInfo = await prisma.event.findUnique({
      where: { event_id: event.event_id },
      select: {
        title: true,
        cover_image_url: true,
        start_time: true,
        venue: true,
        location: true,
      },
    });

    // Best-effort release of locks now that booking is confirmed
    if (event.seat_map) {
      for (const seatId of selected_seats) {
        seatLockService
          .releaseLock(
            String(event.event_id),
            String(seatId),
            String(req.userId)
          )
          .catch(() => {});
      }
    }

    // Send email with tickets after successful payment and ticket creation
    console.log(
      "📧 [EMAIL] Starting email sending process for payment:",
      result.payment.payment_id
    );
    try {
      // Get user info for email
      const userInfo = await prisma.user.findUnique({
        where: { user_id: userId },
        select: { name: true, email: true },
      });

      if (userInfo && userInfo.email && result.tickets.length > 0) {
        // Prepare ticket data for email
        const ticketsForEmail = result.tickets.map((ticket) => ({
          user_name: userInfo.name,
          user_email: userInfo.email,
          event_title: eventInfo.title,
          event_venue: eventInfo.venue,
          event_location: eventInfo.location,
          event_start_time: eventInfo.start_time,
          seat_label: ticket.seat_label,
          price: Number(ticket.price), // Convert BigInt to number
          qr_code: ticket.qr_code,
          payment_id: result.payment.payment_id,
          purchase_date: ticket.purchase_date,
        }));

        console.log(`📧 [EMAIL] Preparing to send email to: ${userInfo.email}`);
        console.log(`📧 [EMAIL] Number of tickets: ${ticketsForEmail.length}`);

        // Send email based on number of tickets
        if (ticketsForEmail.length === 1) {
          // Single ticket
          console.log("📧 [EMAIL] Sending single ticket email...");
          await emailService.sendTicketEmail(
            ticketsForEmail[0],
            userInfo.email
          );
          console.log(`✅ Single ticket email sent to ${userInfo.email}`);
        } else {
          // Multiple tickets
          console.log("📧 [EMAIL] Sending multiple tickets email...");
          await emailService.sendMultipleTicketsEmail(
            ticketsForEmail,
            userInfo.email
          );
          console.log(
            `✅ Multiple tickets email sent to ${userInfo.email} (${ticketsForEmail.length} tickets)`
          );
        }
      } else {
        console.log("📧 [EMAIL] No user email found or no tickets created");
      }
    } catch (emailError) {
      console.error("❌ [EMAIL] Error sending ticket email:", emailError);
      console.error("❌ [EMAIL] Full error stack:", emailError.stack);
      // Don't fail the payment if email fails - just log it
    }

    res.status(201).json({
      success: true,
      message: "Payment record created successfully",
      payment: result.payment,
      tickets: result.tickets.map((t) => ({
        ...t,
        price: Number(t.price),
        event: eventInfo,
      })),
      lockDebug: event.seat_map ? lockDebug : undefined,
    });
  } catch (error) {
    if (error.message && error.message.startsWith("Seat(s) just booked")) {
      return res
        .status(409)
        .json({ success: false, error: error.message, message: error.message });
    }
    res.status(500).json({
      success: false,
      error: "Failed to create payment record",
      message: error.message,
    });
  }
});

// GET /payments/my-payments
router.get("/payments/my-payments", authenticateUser, async (req, res) => {
  try {
    const userId = parseInt(req.userId);
    const payments = await prisma.payment.findMany({
      where: { user_id: userId },
      orderBy: { payment_date: "desc" },
    });
    res.json({ success: true, payments });
  } catch (e) {
    res.status(500).json({
      success: false,
      error: "Failed to fetch payments",
      message: e.message,
    });
  }
});

// GET /payments/:payment_id
router.get("/payments/:payment_id", authenticateUser, async (req, res) => {
  try {
    const userId = parseInt(req.userId);
    const { payment_id } = req.params;
    const payment = await prisma.payment.findUnique({ where: { payment_id } });
    if (!payment || payment.user_id !== userId)
      return res
        .status(404)
        .json({ success: false, error: "Payment not found" });
    res.json({ success: true, payment });
  } catch (e) {
    res.status(500).json({
      success: false,
      error: "Failed to fetch payment",
      message: e.message,
    });
  }
});

// GET /tickets/my-tickets
router.get("/tickets/my-tickets", authenticateUser, async (req, res) => {
  try {
    const userId = parseInt(req.userId);
    const tickets = await prisma.ticket_purchase.findMany({
      where: { user_id: userId },
      orderBy: { purchase_date: "desc" },
      include: {
        Event: {
          select: {
            title: true,
            cover_image_url: true,
            start_time: true,
            venue: true,
            location: true,
          },
        },
        payment: {
          select: {
            payment_id: true,
            status: true,
            payment_method: true,
            transaction_ref: true,
          },
        },
        User: {
          select: {
            name: true,
            phone_number: true,
          },
        },
      },
    });
    res.json({
      success: true,
      tickets: tickets.map((t) => ({
        ...t,
        price: Number(t.price),
        user_id: Number(t.user_id),
        event_id: Number(t.event_id),
        event: t.Event,
        payment: t.payment,
        user: t.User,
      })),
    });
  } catch (e) {
    console.error("[TICKETS ERROR]", e);
    res.status(500).json({
      success: false,
      error: "Failed to fetch tickets",
      message: e.message,
      stack: process.env.NODE_ENV === "development" ? e.stack : undefined,
    });
  }
});

// GET /tickets/:ticketId
router.get("/tickets/:ticketId", authenticateUser, async (req, res) => {
  try {
    const userId = parseInt(req.userId);
    const { ticketId } = req.params;
    const ticket = await prisma.ticket_purchase.findUnique({
      where: { ticket_id: ticketId },
      include: {
        Event: {
          select: {
            title: true,
            cover_image_url: true,
            start_time: true,
            venue: true,
            location: true,
          },
        },
        payment: {
          select: {
            payment_id: true,
            status: true,
            payment_method: true,
            transaction_ref: true,
          },
        },
        User: {
          select: {
            name: true,
            phone_number: true,
          },
        },
      },
    });
    if (!ticket || ticket.user_id !== userId)
      return res
        .status(404)
        .json({ success: false, error: "Ticket not found" });
    res.json({
      success: true,
      ticket: {
        ...ticket,
        price: Number(ticket.price),
        user_id: Number(ticket.user_id),
        event_id: Number(ticket.event_id),
        event: ticket.Event,
        payment: ticket.payment,
        user: ticket.User,
      },
    });
  } catch (e) {
    res.status(500).json({
      success: false,
      error: "Failed to fetch ticket",
      message: e.message,
    });
  }
});

// GET /tickets/qr/:qrCode
router.get("/tickets/qr/:qrCode", authenticateUser, async (req, res) => {
  try {
    const userId = parseInt(req.userId);
    const { qrCode } = req.params;
    const ticket = await prisma.ticket_purchase.findFirst({
      where: { qr_code: qrCode, user_id: userId },
      include: {
        event: {
          select: {
            title: true,
            cover_image_url: true,
            start_time: true,
            venue: true,
            location: true,
          },
        },
        payment: {
          select: {
            payment_id: true,
            status: true,
            payment_method: true,
            transaction_ref: true,
          },
        },
        user: {
          select: {
            name: true,
            phone_number: true,
          },
        },
      },
    });
    if (!ticket)
      return res
        .status(404)
        .json({ success: false, error: "Ticket not found" });
    res.json({
      success: true,
      ticket: {
        ...ticket,
        price: Number(ticket.price),
        user_id: Number(ticket.user_id),
        event_id: Number(ticket.event_id),
        event: ticket.Event,
        payment: ticket.payment,
        user: ticket.User,
      },
    });
  } catch (e) {
    res.status(500).json({
      success: false,
      error: "Failed to fetch ticket by QR",
      message: e.message,
    });
  }
});

// GET /tickets/by-payment/:paymentId (parity first ticket)
router.get(
  "/tickets/by-payment/:paymentId",
  authenticateUser,
  async (req, res) => {
    try {
      const userId = parseInt(req.userId);
      const { paymentId } = req.params;
      const ticket = await prisma.ticketPurchase.findFirst({
        where: { payment_id: paymentId, user_id: userId },
        include: {
          event: {
            select: {
              title: true,
              cover_image_url: true,
              start_time: true,
              venue: true,
              location: true,
            },
          },
          payment: {
            select: {
              payment_id: true,
              status: true,
              payment_method: true,
              transaction_ref: true,
            },
          },
          user: {
            select: {
              name: true,
              phone_number: true,
            },
          },
        },
      });
      if (!ticket)
        return res
          .status(404)
          .json({ success: false, error: "Ticket not found" });
      res.json({
        success: true,
        ticket: {
          ...ticket,
          price: Number(ticket.price),
          user_id: Number(ticket.user_id),
          event_id: Number(ticket.event_id),
          event: ticket.Event,
          payment: ticket.payment,
          user: ticket.User,
        },
      });
    } catch (e) {
      res.status(500).json({
        success: false,
        error: "Failed to fetch ticket by payment",
        message: e.message,
      });
    }
  }
);

// PUT /tickets/:ticketId/attend
router.put("/tickets/:ticketId/attend", authenticateUser, async (req, res) => {
  try {
    const userId = parseInt(req.userId);
    const { ticketId } = req.params;
    console.log(
      `[CORE-SERVICE][TICKETS] /tickets/:ticketId/attend userId=${userId} ticketId=${ticketId}`
    );
    // User can only mark own ticket for now (future: organizer scan logic)
    const ticket = await prisma.ticket_purchase.findUnique({
      where: { ticket_id: ticketId },
      include: {
        event: {
          select: {
            title: true,
            cover_image_url: true,
            start_time: true,
            venue: true,
            location: true,
          },
        },
      },
    });
    if (!ticket || ticket.user_id !== userId)
      return res
        .status(404)
        .json({ success: false, error: "Ticket not found" });
    if (ticket.attended)
      return res.json({
        success: true,
        message: "Already marked attended",
        ticket: { ...ticket, price: Number(ticket.price) },
      });
    const updated = await prisma.ticket_purchase.update({
      where: { ticket_id: ticketId },
      data: { attended: true },
    });
    console.log(`[CORE-SERVICE][TICKETS] Marked attended ticket=${ticketId}`);
    res.json({
      success: true,
      message: "Ticket marked as attended",
      ticket: { ...updated, price: Number(updated.price), event: ticket.Event },
    });
  } catch (e) {
    console.error("[CORE-SERVICE][TICKETS] Error marking attendance", e);
    res.status(500).json({
      success: false,
      error: "Failed to update ticket attendance",
      message: e.message,
    });
  }
});

// Debug endpoint for ticket/payment counts (appended)
router.get("/debug/tickets-stats", authenticateUser, async (req, res) => {
  try {
    const userId = parseInt(req.userId);
    const [userTicketCount, totalTicketCount, userPaymentCount] =
      await Promise.all([
        prisma.ticket_purchase.count({ where: { user_id: userId } }),
        prisma.ticket_purchase.count(),
        prisma.payment.count({ where: { user_id: userId } }),
      ]);
    res.json({
      success: true,
      userId,
      userTicketCount,
      totalTicketCount,
      userPaymentCount,
      hint: "If userTicketCount>0 but /tickets/my-tickets empty, investigate auth userId mapping or serialization.",
    });
  } catch (e) {
    console.error("[CORE-SERVICE][TICKETS] Debug stats error", e);
    res.status(500).json({
      success: false,
      error: "Failed to get debug stats",
      message: e.message,
    });
  }
});

// User profile routes
router.get("/users/profile", async (req, res) => {
  try {
    const userId = parseInt(req.userId);
    const user = await prisma.user.findUnique({
      where: { user_id: userId },
      select: {
        user_id: true,
        name: true,
        email: true,
        phone_number: true,
        profile_picture: true,
        role: true,
        is_active: true,
        is_email_verified: true,
        created_at: true,
        updated_at: true,
      },
    });
    if (!user)
      return res.status(404).json({ success: false, error: "User not found" });
    res.json({ success: true, user, service: "core-service" });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: "Failed to fetch profile",
      message: error.message,
    });
  }
});

router.put("/users/profile", async (req, res) => {
  try {
    const userId = parseInt(req.userId);
    const { name, phone_number, profile_picture } = req.body;
    const user = await prisma.user.update({
      where: { user_id: userId },
      data: { name, phone_number, profile_picture },
      select: {
        user_id: true,
        name: true,
        email: true,
        phone_number: true,
        profile_picture: true,
        role: true,
        is_active: true,
        is_email_verified: true,
        created_at: true,
        updated_at: true,
      },
    });
    res.json({
      success: true,
      message: "Profile updated successfully",
      user,
      service: "core-service",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: "Failed to update profile",
      message: error.message,
    });
  }
});

// Analytics routes
router.get("/analytics/dashboard", async (req, res) => {
  try {
    const userId = req.headers["x-user-id"];

    // Provide basic analytics data directly from database
    const [userTickets, userPayments] = await Promise.all([
      prisma.ticket_purchase.count({
        where: { user_id: parseInt(userId) || 0 },
      }),
      prisma.payment.count({ where: { user_id: parseInt(userId) || 0 } }),
    ]);

    const analytics = {
      totalTickets: userTickets,
      totalPayments: userPayments,
      totalSpent: 0, // Would need to calculate from payments
      upcomingEvents: 0, // Would need to calculate from tickets
    };

    res.json({
      success: true,
      analytics,
      service: "core-service",
    });
  } catch (error) {
    console.error("[API] Error fetching analytics:", error);
    res.status(500).json({
      success: false,
      error: "Failed to fetch analytics",
      message: error.message,
    });
  }
});

// Import and use users routes (with authentication protection)
const usersRoutes = require("./users");
router.use("/users", authenticateUser, usersRoutes);

module.exports = router;
