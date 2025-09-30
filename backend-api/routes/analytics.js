const express = require('express');
const router = express.Router();
const analyticsController = require('../controllers/analytics');

// Dashboard endpoints (should be before parameterized routes)
router.get('/dashboard/overview', analyticsController.getDashboardOverview);
router.get('/dashboard/revenue-trend', analyticsController.getRevenueTrend);
router.get('/dashboard/categories', analyticsController.getEventCategories);
router.get('/dashboard/top-events', analyticsController.getTopEvents);
router.get('/dashboard/daily-attendees', analyticsController.getDailyAttendees);

// Organizer-specific dashboard endpoints
router.get('/organizer/:organizationId/dashboard/overview', analyticsController.getOrganizerDashboardOverview);
router.get('/organizer/:organizationId/dashboard/revenue-trend', analyticsController.getOrganizerRevenueTrend);
router.get('/organizer/:organizationId/dashboard/categories', analyticsController.getOrganizerEventCategories);
router.get('/organizer/:organizationId/dashboard/top-events', analyticsController.getOrganizerTopEvents);
router.get('/organizer/:organizationId/dashboard/daily-attendees', analyticsController.getOrganizerDailyAttendees);

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