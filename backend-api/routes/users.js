const express = require("express");
const multer = require("multer");
const cloudinary = require("cloudinary").v2;
const jwt = require("jsonwebtoken");
const prisma = require("../lib/database");

const router = express.Router();

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Configure multer for memory storage (we'll upload to Cloudinary)
const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  console.log("File filter - File info:", {
    fieldname: file.fieldname,
    originalname: file.originalname,
    mimetype: file.mimetype,
    encoding: file.encoding,
  });

  // Allow only image files
  if (file.mimetype && file.mimetype.startsWith("image/")) {
    console.log("File accepted:", file.originalname);
    cb(null, true);
  } else {
    console.log("File rejected - not an image:", file.mimetype);
    cb(new Error("Only image files are allowed!"), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit (Cloudinary can handle larger files)
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
  (req, res, next) => {
    console.log("Upload request received");
    console.log("Request headers:", req.headers);
    console.log("Request content-type:", req.get("content-type"));

    upload.single("profilePic")(req, res, (err) => {
      if (err) {
        console.error("Multer error:", err);
        if (err instanceof multer.MulterError) {
          if (err.code === "LIMIT_FILE_SIZE") {
            return res.status(400).json({
              success: false,
              error: "File too large. Maximum size is 10MB.",
            });
          }
          return res.status(400).json({
            success: false,
            error: `Upload error: ${err.message}`,
          });
        }
        // Custom file filter error
        return res.status(400).json({
          success: false,
          error: err.message,
        });
      }
      console.log("File upload successful, proceeding to next middleware");
      next();
    });
  },
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({ error: "No file uploaded" });
      }

      const userId = req.body.userId || req.user.userId;

      if (!userId) {
        return res.status(400).json({ error: "User ID is required" });
      }

      console.log("Uploading to Cloudinary...");

      // Upload to Cloudinary
      const result = await new Promise((resolve, reject) => {
        cloudinary.uploader
          .upload_stream(
            {
              resource_type: "image",
              folder: "profile-pictures",
              public_id: `user-${userId}-${Date.now()}`,
              transformation: [
                { width: 400, height: 400, crop: "fill", gravity: "face" },
                { quality: "auto", fetch_format: "auto" },
              ],
            },
            (error, result) => {
              if (error) {
                console.error("Cloudinary upload error:", error);
                reject(error);
              } else {
                console.log("Cloudinary upload successful:", result.secure_url);
                resolve(result);
              }
            }
          )
          .end(req.file.buffer);
      });

      // Update user's profile picture in database
      const updatedUser = await prisma.user.update({
        where: { user_id: parseInt(userId) },
        data: { profile_picture: result.secure_url },
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
        profilePictureUrl: result.secure_url,
        user: updatedUser,
      });
    } catch (error) {
      console.error("Profile picture upload error:", error);

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
