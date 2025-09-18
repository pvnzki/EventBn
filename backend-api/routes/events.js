const express = require("express");
const router = express.Router();

const eventsService = require("../services/core-service/events");
const prisma = require("../lib/database");
const multer = require("multer");
const cloudinary = require("../lib/cloudinary");
const upload = multer({ storage: multer.memoryStorage() });

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


// Create new event with media upload
router.post("/", upload.fields([
  { name: "cover_image", maxCount: 1 },
  { name: "other_images", maxCount: 10 },
  { name: "video", maxCount: 1 },
]), async (req, res) => {
  try {
    const body = req.body;
    // Parse ticket_types and seat_map if sent as JSON strings
    if (body.ticket_types && typeof body.ticket_types === "string") {
      try {
        body.ticket_types = JSON.parse(body.ticket_types);
      } catch (e) {
        return res.status(400).json({ success: false, message: "Invalid JSON for ticket_types" });
      }
    }
    if (body.seat_map && typeof body.seat_map === "string") {
      try {
        body.seat_map = JSON.parse(body.seat_map);
      } catch (e) {
        return res.status(400).json({ success: false, message: "Invalid JSON for seat_map" });
      }
    }

    // Handle file uploads to Cloudinary
    if (req.files) {
      // Cover image
      if (req.files.cover_image && req.files.cover_image[0]) {
        const result = await cloudinary.uploader.upload_stream_promise(req.files.cover_image[0], "cover_images");
        body.cover_image_url = result.secure_url;
      }
      // Other images
      if (req.files.other_images) {
        const otherUrls = [];
        for (const file of req.files.other_images) {
          const result = await cloudinary.uploader.upload_stream_promise(file, "event_images");
          otherUrls.push(result.secure_url);
        }
        body.other_images_url = JSON.stringify(otherUrls);
      }
      // Video
      if (req.files.video && req.files.video[0]) {
        const result = await cloudinary.uploader.upload_stream_promise(req.files.video[0], "event_videos", { resource_type: "video" });
        body.video_url = result.secure_url;
      }
    }

    const event = await eventsService.createEvent(body);
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
