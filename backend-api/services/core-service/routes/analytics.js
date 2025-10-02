const express = require('express');
const router = express.Router();
const analyticsController = require('../controllers/analytics');

// Fetch all analytics
router.get('/', analyticsController.getAll);

// Fetch by year
router.get('/:year', analyticsController.getByYear);

// Fetch by year + month
router.get('/:year/:month', analyticsController.getByMonth);

// Create new record
router.post('/', analyticsController.create);

// Update record
router.put('/:id', analyticsController.update);

// Delete record
router.delete('/:id', analyticsController.remove);

module.exports = router;