const express = require('express');
const router = express.Router();
const eventsService = require('../services/core-service/events');

// Get all events
router.get('/', async (req, res) => {
  try {
    const events = await eventsService.getAllEvents(req.query);
    res.json({
      success: true,
      data: events
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// Get event by ID
router.get('/:id', async (req, res) => {
  try {
    const event = await eventsService.getEventById(req.params.id);
    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found'
      });
    }
    res.json({
      success: true,
      data: event
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// Create new event
router.post('/', async (req, res) => {
  try {
    const event = await eventsService.createEvent(req.body);
    res.status(201).json({
      success: true,
      message: 'Event created successfully',
      data: event
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message
    });
  }
});

// Update event
router.put('/:id', async (req, res) => {
  try {
    const event = await eventsService.updateEvent(req.params.id, req.body);
    res.json({
      success: true,
      message: 'Event updated successfully',
      data: event
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message
    });
  }
});

// Delete event
router.delete('/:id', async (req, res) => {
  try {
    await eventsService.deleteEvent(req.params.id);
    res.json({
      success: true,
      message: 'Event deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

// Search events
router.get('/search/:query', async (req, res) => {
  try {
    const events = await eventsService.searchEvents(req.params.query, req.query);
    res.json({
      success: true,
      data: events
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
});

module.exports = router;
