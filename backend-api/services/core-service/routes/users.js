const express = require('express');
const multer =require('multer');
const bcrypt = require('bcrypt');
const router = express.Router();
const usersService = require('../users');
const { uploadStream } = require('../lib/cloudinary');

// Get all users
router.get('/', async (req, res) => {
  try {
    const users = await usersService.getAllUsers(req.query);
    res.json({
      success: true,
      data: users
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// Get user by ID
router.get('/:id', async (req, res) => {
  try {
    const user = await usersService.getUserById(req.params.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// Create new user
router.post('/', async (req, res) => {
  try {
    const newUser = await usersService.createUser(req.body);
    res.status(201).json({
      success: true,
      message: 'User created successfully',
      data: newUser
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message
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

// Update user
router.put("/:id", upload.single("profile_picture"), async (req, res) => {
  try {
    const updateData = { ...req.body };

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

    const user = await usersService.updateUser(req.params.id, updateData);

    res.json({
      success: true,
      message: "User updated successfully",
      data: user,
    });
  } catch (error) {
    console.error('Error updating user:', error);
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
});

// Delete user
router.delete('/:id', async (req, res) => {
  try {
    await usersService.permanentDeleteUser(req.params.id);

    res.json({
      success: true,
      message: 'User deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

module.exports = router;
