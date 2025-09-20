const express = require("express");
const router = express.Router();
const coreService = require("../index");

// Middleware for service-to-service authentication
const serviceAuth = (req, res, next) => {
  const serviceKey = req.headers["x-service-key"];
  const expectedKey = process.env.INTER_SERVICE_KEY || "dev-service-key";

  if (!serviceKey || serviceKey !== expectedKey) {
    return res.status(401).json({
      error: "Unauthorized service access",
      service: "core-service",
    });
  }

  next();
};

// Apply service auth to all internal routes
router.use(serviceAuth);

// Get user details (for post service)
router.get("/users/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const user = await coreService.users.getUserById(userId);

    if (!user) {
      return res.status(404).json({
        error: "User not found",
        userId,
      });
    }

    // Return safe user data for other services
    const safeUser = {
      user_id: user.user_id,
      name: user.name,
      profile_picture: user.profile_picture,
      is_active: user.is_active,
      is_email_verified: user.is_email_verified,
      role: user.role,
      created_at: user.created_at,
    };

    res.json({
      success: true,
      user: safeUser,
    });
  } catch (error) {
    console.error("[INTERNAL API] Error fetching user:", error);
    res.status(500).json({
      error: "Failed to fetch user details",
      message: error.message,
    });
  }
});

// Batch get users (for post service to get multiple user details)
router.post("/users/batch", async (req, res) => {
  try {
    const { userIds } = req.body;

    if (!Array.isArray(userIds) || userIds.length === 0) {
      return res.status(400).json({
        error: "userIds must be a non-empty array",
      });
    }

    if (userIds.length > 100) {
      return res.status(400).json({
        error: "Maximum 100 users per batch request",
      });
    }

    const users = await Promise.all(
      userIds.map(async (userId) => {
        try {
          const user = await coreService.users.getUserById(userId);
          if (!user) return null;

          return {
            user_id: user.user_id,
            name: user.name,
            profile_picture: user.profile_picture,
            is_active: user.is_active,
            is_email_verified: user.is_email_verified,
            role: user.role,
          };
        } catch (error) {
          console.error(`Error fetching user ${userId}:`, error);
          return null;
        }
      })
    );

    const validUsers = users.filter((user) => user !== null);

    res.json({
      success: true,
      users: validUsers,
      requested: userIds.length,
      found: validUsers.length,
    });
  } catch (error) {
    console.error("[INTERNAL API] Error in batch user fetch:", error);
    res.status(500).json({
      error: "Failed to fetch users",
      message: error.message,
    });
  }
});

// Verify user exists and is active
router.get("/users/:userId/verify", async (req, res) => {
  try {
    const { userId } = req.params;
    const user = await coreService.users.getUserById(userId);

    res.json({
      exists: !!user,
      active: user?.is_active || false,
      verified: user?.is_email_verified || false,
    });
  } catch (error) {
    console.error("[INTERNAL API] Error verifying user:", error);
    res.status(500).json({
      error: "Failed to verify user",
      message: error.message,
    });
  }
});

// Get event details (for post service when posts are linked to events)
router.get("/events/:eventId", async (req, res) => {
  try {
    const { eventId } = req.params;
    const event = await coreService.events.getEventById(eventId);

    if (!event) {
      return res.status(404).json({
        error: "Event not found",
        eventId,
      });
    }

    // Return safe event data
    const safeEvent = {
      event_id: event.event_id,
      title: event.title,
      description: event.description,
      start_time: event.start_time,
      location: event.location,
      cover_image_url: event.cover_image_url,
      is_active: event.is_active,
    };

    res.json({
      success: true,
      event: safeEvent,
    });
  } catch (error) {
    console.error("[INTERNAL API] Error fetching event:", error);
    res.status(500).json({
      error: "Failed to fetch event details",
      message: error.message,
    });
  }
});

module.exports = router;
