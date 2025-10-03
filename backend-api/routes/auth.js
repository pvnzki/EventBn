const express = require('express');
const router = express.Router();
const authService = require('../services/core-service/auth');
const { ValidationError } = require('../lib/validation');

const { authenticateToken } = require('../middleware/auth');

// Register user
router.post('/register', async (req, res) => {
  try {
    const result = await authService.register(req.body);
    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: result.user,
      token: result.token
    });
  } catch (error) {
    if (error instanceof ValidationError) {
      return res.status(400).json({
        success: false,
        message: error.message,
        code: 'VALIDATION_ERROR',
        errors: error.errors
      });
    }
    res.status(400).json({
      success: false,
      message: error.message
    });
  }
});

// Login user
router.post('/login', async (req, res) => {
  try {
    const result = await authService.login(req.body);
    res.json({
      success: true,
      message: 'Login successful',
      data: result.user,
      token: result.token
    });
  } catch (error) {
    if (error instanceof ValidationError) {
      return res.status(400).json({
        success: false,
        message: error.message,
        code: 'VALIDATION_ERROR',
        errors: error.errors
      });
    }
    res.status(401).json({
      success: false,
      message: error.message
    });
  }
});


// Get current user
router.get('/me', authenticateToken, async (req, res) => {
  try {
    res.json({
      success: true,
      data: req.user
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

module.exports = router;
