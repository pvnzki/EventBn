const express = require("express");
const { body, validationResult } = require("express-validator");
const prisma = require("../lib/database");
const authMiddleware = require("../middleware/auth");

const router = express.Router();

// Get all events
router.get("/", async (req, res) => {
  try {
    const { page = 1, limit = 10, category, search } = req.query;
    const skip = (page - 1) * limit;

    const where = {};
    if (category) {
      where.category = category;
    }
    if (search) {
      where.OR = [
        { title: { contains: search, mode: "insensitive" } },
        { description: { contains: search, mode: "insensitive" } },
        { location: { contains: search, mode: "insensitive" } },
        { venue: { contains: search, mode: "insensitive" } },
      ];
    }

    const events = await prisma.event.findMany({
      where,
      skip: parseInt(skip),
      take: parseInt(limit),
      include: {
        // Note: Relations need to be defined in schema for this to work
        // For now, we'll just get the basic event data
      },
      orderBy: {
        start_time: "asc",
      },
    });

    const total = await prisma.event.count({ where });

    res.json({
      events,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    console.error("Get events error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Get single event
router.get("/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const event = await prisma.event.findUnique({
      where: { event_id: parseInt(id) },
      // Note: Relations need to be defined in schema for includes to work
    });

    if (!event) {
      return res.status(404).json({ error: "Event not found" });
    }

    res.json(event);
  } catch (error) {
    console.error("Get event error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Create event (requires authentication)
router.post(
  "/",
  authMiddleware,
  [
    body("title").notEmpty().trim(),
    body("description").optional().trim(),
    body("location").notEmpty().trim(),
    body("venue").optional().trim(),
    body("startDate").isISO8601(),
    body("endDate").isISO8601(),
    body("capacity").isInt({ min: 1 }),
    body("category").notEmpty().trim(),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const {
        title,
        description,
        location,
        venue,
        startDate,
        endDate,
        capacity,
        category,
        imageUrl,
      } = req.body;

      const event = await prisma.event.create({
        data: {
          title,
          description,
          location,
          venue,
          start_time: new Date(startDate),
          end_time: new Date(endDate),
          capacity: parseInt(capacity),
          category,
          cover_image_url: imageUrl,
          organizer_id: req.user.userId,
          status: "draft", // Set initial status
        },
      });

      res.status(201).json({
        message: "Event created successfully",
        event,
      });
    } catch (error) {
      console.error("Create event error:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  }
);

module.exports = router;
