const express = require("express");
const router = express.Router();
const eventsService = require("../services/core-service/events");
const prisma = require("../lib/database");

// Get all events
router.get("/", async (req, res) => {
  try {
    const events = await eventsService.getAllEvents(req.query);
    res.json({
      success: true,
      data: events,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Get event by ID
router.get("/:id", async (req, res) => {
  try {
    const event = await eventsService.getEventById(req.params.id);
    if (!event) {
      return res.status(404).json({
        success: false,
        message: "Event not found",
      });
    }
    res.json({
      success: true,
      data: event,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Create new event
router.post("/", async (req, res) => {
  try {
    const event = await eventsService.createEvent(req.body);
    res.status(201).json({
      success: true,
      message: "Event created successfully",
      data: event,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
});

// Update event
router.put("/:id", async (req, res) => {
  try {
    const event = await eventsService.updateEvent(req.params.id, req.body);
    res.json({
      success: true,
      message: "Event updated successfully",
      data: event,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
});

// Delete event
router.delete("/:id", async (req, res) => {
  try {
    await eventsService.deleteEvent(req.params.id);
    res.json({
      success: true,
      message: "Event deleted successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Get booked seats for an event
router.get("/:id/booked-seats", async (req, res) => {
  try {
    const eventId = parseInt(req.params.id);

    const bookedSeats = await prisma.bookedSeats.findMany({
      where: {
        event_id: eventId,
        payment: {
          status: {
            in: ["pending", "completed"],
          },
        },
      },
      select: {
        seat_id: true,
        seat_label: true,
        booked_at: true,
      },
    });

    res.json({
      success: true,
      data: bookedSeats,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Search events
router.get("/search/:query", async (req, res) => {
  try {
    const events = await eventsService.searchEvents(
      req.params.query,
      req.query
    );
    res.json({
      success: true,
      data: events,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Get seat map for an event
router.get("/:id/seatmap", async (req, res) => {
  try {
    const seatMap = await eventsService.getSeatMap(req.params.id);
    if (!seatMap) {
      return res.status(404).json({
        success: false,
        message: "Event or seat map not found",
      });
    }
    res.json({
      success: true,
      data: seatMap,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Update seat map for an event (for booking seats)
router.put("/:id/seatmap", async (req, res) => {
  try {
    const updatedSeatMap = await eventsService.updateSeatMap(
      req.params.id,
      req.body.seatMap
    );
    res.json({
      success: true,
      message: "Seat map updated successfully",
      data: updatedSeatMap,
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
});

module.exports = router;
