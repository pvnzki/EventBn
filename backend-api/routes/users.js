const express = require("express");
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const jwt = require("jsonwebtoken");
const prisma = require("../lib/database");

const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadPath = "uploads/profile-pictures/";
    // Create directory if it doesn't exist
    if (!fs.existsSync(uploadPath)) {
      fs.mkdirSync(uploadPath, { recursive: true });
    }
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    // Generate unique filename
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(null, "profile-" + uniqueSuffix + path.extname(file.originalname));
  },
});

const fileFilter = (req, file, cb) => {
  // Allow only image files
  if (file.mimetype.startsWith("image/")) {
    cb(null, true);
  } else {
    cb(new Error("Only image files are allowed!"), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
});

// Middleware to verify JWT token
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];

  if (!token) {
    return res.status(401).json({ error: "Access token required" });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: "Invalid token" });
    }
    req.user = user;
    next();
  });
};

// Upload profile picture endpoint
router.post(
  "/upload-profile-pic",
  authenticateToken,
  upload.single("profilePic"),
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({ error: "No file uploaded" });
      }

      const userId = req.body.userId || req.user.userId;

      if (!userId) {
        return res.status(400).json({ error: "User ID is required" });
      }

      // Construct the file URL (you might want to use a CDN or cloud storage in production)
      const fileUrl = `${req.protocol}://${req.get(
        "host"
      )}/uploads/profile-pictures/${req.file.filename}`;

      // Update user's profile picture in database
      const updatedUser = await prisma.user.update({
        where: { user_id: parseInt(userId) },
        data: { profile_picture: fileUrl },
        select: {
          user_id: true,
          name: true,
          email: true,
          profile_picture: true,
          role: true,
          phone_number: true,
          is_active: true,
          is_email_verified: true,
        },
      });

      res.json({
        success: true,
        message: "Profile picture uploaded successfully",
        profilePictureUrl: fileUrl,
        user: updatedUser,
      });
    } catch (error) {
      console.error("Profile picture upload error:", error);

      // Delete uploaded file if database update fails
      if (req.file && req.file.path) {
        try {
          fs.unlinkSync(req.file.path);
        } catch (deleteError) {
          console.error("Error deleting file:", deleteError);
        }
      }

      res.status(500).json({
        error: "Failed to upload profile picture",
        details: error.message,
      });
    }
  }
);

// Get user profile endpoint
router.get("/profile/:userId", authenticateToken, async (req, res) => {
  try {
    const userId = parseInt(req.params.userId);

    const user = await prisma.user.findUnique({
      where: { user_id: userId },
      select: {
        user_id: true,
        name: true,
        email: true,
        profile_picture: true,
        role: true,
        phone_number: true,
        is_active: true,
        is_email_verified: true,
      },
    });

    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    res.json({
      success: true,
      user: user,
    });
  } catch (error) {
    console.error("Get user profile error:", error);
    res.status(500).json({
      error: "Failed to get user profile",
      details: error.message,
    });
  }
});

module.exports = router;
