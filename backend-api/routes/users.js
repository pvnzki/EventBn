const express = require('express');
const multer =require('multer');
const router = express.Router();
const usersService = require('../services/core-service/users');

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

// Configure Multer storage
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/"); // Folder to save images (make sure it exists)
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(null, uniqueSuffix + "-" + file.originalname);
  },
});

const upload = multer({ storage });

// Update user
router.put("/:id", upload.single("profile_picture"), async (req, res) => {
  try {
    const updateData = { ...req.body };

    // If a new profile picture is uploaded, set its path
    if (req.file) {
      updateData.profile_picture = `/uploads/${req.file.filename}`;
    }

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
