const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const { body, validationResult } = require("express-validator");
const prisma = require("../lib/database");
const authMiddleware = require("../middleware/auth");

const router = express.Router();

// Register endpoint
router.post(
  "/register",
  [
    body("email").isEmail().normalizeEmail(),
    body("password").isLength({ min: 8 }),
    body("name").notEmpty().trim(),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { email, password, name, phone } = req.body;

      // Check if user already exists
      const existingUser = await prisma.user.findUnique({
        where: { email },
      });

      if (existingUser) {
        return res.status(400).json({ error: "User already exists" });
      }

      // Hash password
      const hashedPassword = await bcrypt.hash(password, 12);

      // Create user
      const user = await prisma.user.create({
        data: {
          email,
          password_hash: hashedPassword,
          name,
          phone_number: phone,
        },
        select: {
          user_id: true,
          email: true,
          name: true,
          phone_number: true,
          role: true,
          is_active: true,
          is_email_verified: true,
        },
      });

      // Generate JWT token
      const token = jwt.sign(
        { userId: user.user_id, email: user.email },
        process.env.JWT_SECRET,
        { expiresIn: "7d" }
      );

      res.status(201).json({
        message: "User created successfully",
        user,
        token,
      });
    } catch (error) {
      console.error("Registration error:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  }
);

// Login endpoint
router.post(
  "/login",
  [body("email").isEmail().normalizeEmail(), body("password").notEmpty()],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { email, password } = req.body;

      // Find user
      const user = await prisma.user.findUnique({
        where: { email },
      });

      if (!user) {
        return res.status(401).json({ error: "Invalid credentials" });
      }

      // Check password
      const isPasswordValid = await bcrypt.compare(
        password,
        user.password_hash
      );
      if (!isPasswordValid) {
        return res.status(401).json({ error: "Invalid credentials" });
      }

      // Generate JWT token
      const token = jwt.sign(
        { userId: user.user_id, email: user.email },
        process.env.JWT_SECRET,
        { expiresIn: "7d" }
      );

      res.json({
        message: "Login successful",
        user: {
          id: user.user_id,
          email: user.email,
          name: user.name,
          phone: user.phone_number,
          role: user.role,
        },
        token,
      });
    } catch (error) {
      console.error("Login error:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  }
);

// Get current user profile
router.get("/me", authMiddleware, async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { user_id: req.user.userId },
      select: {
        user_id: true,
        name: true,
        email: true,
        phone_number: true,
        profile_picture: true,
        role: true,
        is_active: true,
        is_email_verified: true,
      },
    });

    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    res.json({
      success: true,
      user: {
        user_id: user.user_id,
        name: user.name,
        email: user.email,
        phone_number: user.phone_number,
        profile_picture: user.profile_picture,
        role: user.role,
        is_active: user.is_active,
        is_email_verified: user.is_email_verified,
      },
    });
  } catch (error) {
    console.error("Get user profile error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

module.exports = router;
