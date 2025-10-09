const express = require('express');
const router = express.Router();
const usersService = require('../users');
const multer = require('multer');
const { cloudinary } = require('../lib/cloudinary');

// Configure multer for memory storage
const upload = multer({ storage: multer.memoryStorage() });

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

// Update user (basic update without file upload)
router.put("/:id", async (req, res) => {
  try {
    const updateData = { ...req.body };
    const user = await usersService.updateUser(req.params.id, updateData);

    res.json({
      success: true,
      message: "User updated successfully",
      data: user,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
});

// Update user profile (for mobile app - accepts Cloudinary URLs)
router.put('/:id/profile', async (req, res) => {
  try {
    const user = await usersService.updateUserProfile(req.params.id, req.body);
    
    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: user
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message
    });
  }
});

// Upload profile image to Cloudinary
router.post('/:id/upload-profile-image', upload.single('image'), async (req, res) => {
  try {
    console.log('📸 [PROFILE_UPLOAD] Received profile image upload request for user:', req.params.id);
    
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No image file provided'
      });
    }

    console.log('📸 [PROFILE_UPLOAD] File details:', {
      originalname: req.file.originalname,
      mimetype: req.file.mimetype,
      size: req.file.size
    });

    // Upload to Cloudinary
    const uploadOptions = {
      folder: 'eventbn/profile_pictures',
      transformation: [
        { width: 400, height: 400, crop: 'fill', gravity: 'face' },
        { quality: 'auto', fetch_format: 'auto' }
      ]
    };

    console.log('☁️ [PROFILE_UPLOAD] Uploading to Cloudinary...');
    
    const uploadResult = await new Promise((resolve, reject) => {
      cloudinary.uploader.upload_stream(uploadOptions, (error, result) => {
        if (error) {
          console.error('❌ [PROFILE_UPLOAD] Cloudinary upload error:', error);
          reject(error);
        } else {
          console.log('✅ [PROFILE_UPLOAD] Cloudinary upload success:', result.secure_url);
          resolve(result);
        }
      }).end(req.file.buffer);
    });

    // Update user profile with the new image URL
    const updatedUser = await usersService.updateUserProfile(req.params.id, {
      avatarUrl: uploadResult.secure_url
    });

    console.log('✅ [PROFILE_UPLOAD] User profile updated with new image URL');

    res.json({
      success: true,
      message: 'Profile image uploaded successfully',
      data: updatedUser,
      imageUrl: uploadResult.secure_url
    });
  } catch (error) {
    console.error('❌ [PROFILE_UPLOAD] Upload failed:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to upload profile image: ' + (error.message || error.toString() || 'Unknown error')
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
