const express = require('express');
const multer =require('multer');
const bcrypt = require('bcrypt');
const router = express.Router();
const usersService = require('../users');
const { uploadStream } = require('../lib/cloudinary');
const { cloudinary } = require("../lib/cloudinary");

// Get all users
router.get("/", async (req, res) => {
  try {
    const users = await usersService.getAllUsers(req.query);
    res.json({
      success: true,
      data: users,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Get user by ID
router.get("/:id", async (req, res) => {
  try {
    console.log(`👤 [Users Route] GET /api/users/${req.params.id}`);
    console.log(`👤 [Users Route] Request headers:`, req.headers);

    const user = await usersService.getUserById(req.params.id);
    if (!user) {
      console.log(`❌ [Users Route] User not found for ID: ${req.params.id}`);
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    console.log(`✅ [Users Route] User found, returning data`);
    res.json({
      success: true,
      data: user,
    });
  } catch (error) {
    console.error(
      `❌ [Users Route] Error in GET /api/users/${req.params.id}:`,
      error
    );
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Create new user
router.post("/", async (req, res) => {
  try {
    const newUser = await usersService.createUser(req.body);
    res.status(201).json({
      success: true,
      message: "User created successfully",
      data: newUser,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
});

// Configure Multer for memory storage (Cloudinary integration)
const storage = multer.memoryStorage();
const upload = multer({ 
  storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    // Only allow image files
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  }
});

// Update user password
router.put('/:id/password', async (req, res) => {
  try {
    const userId = parseInt(req.params.id);
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        error: 'Current password and new password are required'
      });
    }

    // Get user to verify current password
    const user = await usersService.getUserByIdWithPassword(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    // Verify current password
    const isCurrentPasswordValid = await bcrypt.compare(currentPassword, user.password_hash);
    if (!isCurrentPasswordValid) {
      return res.status(400).json({
        success: false,
        error: 'Current password is incorrect'
      });
    }

    // Hash new password
    const saltRounds = 10;
    const newPasswordHash = await bcrypt.hash(newPassword, saltRounds);

    // Update password in database
    await usersService.updateUser(userId, { password_hash: newPasswordHash });

    res.json({
      success: true,
      message: 'Password updated successfully'
    });
  } catch (error) {
    console.error('Error updating password:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Update user (with optional profile picture upload)
router.put("/:id", upload.single("profile_picture"), async (req, res) => {
  try {
    console.log(`🔄 [USER UPDATE] Updating user ${req.params.id}`);
    console.log(
      `🔍 [USER UPDATE] Request body:`,
      JSON.stringify(req.body, null, 2)
    );
    console.log(`🔍 [USER UPDATE] User ID from token:`, req.userId);
    console.log(
      `🔍 [USER UPDATE] Raw request headers:`,
      req.headers.authorization?.slice(0, 20) + "..."
    );

    // If a new profile picture is uploaded, upload to Cloudinary
    if (req.file) {
      console.log('Uploading profile picture to Cloudinary...');
      const result = await uploadStream(req.file.buffer, {
        folder: 'eventbn/profile_pictures',
        resource_type: 'image',
        transformation: [
          { width: 400, height: 400, crop: 'fill' },
          { quality: 'auto' }
        ]
      });
      
      updateData.profile_picture = result.secure_url;
      console.log('Profile picture uploaded to Cloudinary:', result.secure_url);
    }

    // Ensure user can only update their own profile
    if (req.userId && req.params.id !== req.userId.toString()) {
      console.log(
        `❌ [USER UPDATE] Authorization failed: ${req.userId} trying to update ${req.params.id}`
      );
      return res.status(403).json({
        success: false,
        message: "You can only update your own profile",
      });
    }

    const updateData = { ...req.body };

    console.log(`🔍 [USER UPDATE] Processing update data:`, {
      phone_number: updateData.phone_number,
      date_of_birth: updateData.date_of_birth,
      billing_address: updateData.billing_address,
      fieldsCount: Object.keys(updateData).length,
    });

    const user = await usersService.updateUser(req.params.id, updateData);

    console.log(`✅ [USER UPDATE] User updated successfully:`, {
      user_id: user.user_id,
      phone_number: user.phone_number,
      date_of_birth: user.date_of_birth,
      billing_address: user.billing_address,
    });

    res.json({
      success: true,
      message: "User updated successfully",
      data: user,
    });
  } catch (error) {
    console.error(
      `❌ [USER UPDATE] Error updating user ${req.params.id}:`,
      error.message
    );
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
});

// Update user profile (for mobile app - accepts Cloudinary URLs)
router.put("/:id/profile", async (req, res) => {
  try {
    const user = await usersService.updateUserProfile(req.params.id, req.body);

    res.json({
      success: true,
      message: "Profile updated successfully",
      data: user,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
});

// Upload profile image to Cloudinary
router.post(
  "/:id/upload-profile-image",
  upload.single("image"),
  async (req, res) => {
    try {
      console.log(
        "📸 [PROFILE_UPLOAD] Received profile image upload request for user:",
        req.params.id
      );

      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: "No image file provided",
        });
      }

      console.log("📸 [PROFILE_UPLOAD] File details:", {
        originalname: req.file.originalname,
        mimetype: req.file.mimetype,
        size: req.file.size,
      });

      // Upload to Cloudinary
      const uploadOptions = {
        folder: "eventbn/profile_pictures",
        transformation: [
          { width: 400, height: 400, crop: "fill", gravity: "face" },
          { quality: "auto", fetch_format: "auto" },
        ],
      };

      console.log("☁️ [PROFILE_UPLOAD] Uploading to Cloudinary...");

      const uploadResult = await new Promise((resolve, reject) => {
        cloudinary.uploader
          .upload_stream(uploadOptions, (error, result) => {
            if (error) {
              console.error(
                "❌ [PROFILE_UPLOAD] Cloudinary upload error:",
                error
              );
              reject(error);
            } else {
              console.log(
                "✅ [PROFILE_UPLOAD] Cloudinary upload success:",
                result.secure_url
              );
              resolve(result);
            }
          })
          .end(req.file.buffer);
      });

      // Update user profile with the new image URL
      const updatedUser = await usersService.updateUserProfile(req.params.id, {
        avatarUrl: uploadResult.secure_url,
      });

      console.log(
        "✅ [PROFILE_UPLOAD] User profile updated with new image URL"
      );

      res.json({
        success: true,
        message: "Profile image uploaded successfully",
        data: updatedUser,
        imageUrl: uploadResult.secure_url,
      });
    } catch (error) {
      console.error("❌ [PROFILE_UPLOAD] Upload failed:", error);
      res.status(500).json({
        success: false,
        message:
          "Failed to upload profile image: " +
          (error.message || error.toString() || "Unknown error"),
      });
    }
  }
);

// Delete user
router.delete("/:id", async (req, res) => {
  try {
    await usersService.permanentDeleteUser(req.params.id);

    res.json({
      success: true,
      message: "User deleted successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

module.exports = router;
