const express = require('express');
const router = express.Router();
const authService = require('../services/core-service/users');

// Register user
router.post('/register', async (req, res) => {
  try {
    const user = await authService.createUser(req.body);
    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: user
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message
    });
  }
});

// Login user
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await authService.getUserByEmail(email);
    
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }
    
    const isValidPassword = await authService.verifyPassword(user.user_id, password);
    
    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }
    
    // Remove password from response
    const { password_hash, ...userWithoutPassword } = user;
    
    res.json({
      success: true,
      message: 'Login successful',
      data: userWithoutPassword
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

module.exports = router;
