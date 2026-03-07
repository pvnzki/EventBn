const express = require("express");
const router = express.Router();
const jwt = require("jsonwebtoken");
const notificationService = require("../services/notificationService");
const prisma = require("../lib/database");

// ── Auth Middleware (lightweight — no DB lookup, just JWT verify) ──────

const authenticateToken = (req, res, next) => {
  try {
    const authHeader = req.headers["authorization"];
    const token = authHeader && authHeader.split(" ")[1];

    if (!token) {
      return res.status(401).json({
        success: false,
        message: "Access token required",
        code: "NO_TOKEN",
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = { user_id: decoded.userId };
    next();
  } catch (error) {
    if (error.name === "TokenExpiredError") {
      return res
        .status(401)
        .json({ success: false, message: "Token expired", code: "TOKEN_EXPIRED" });
    }
    return res
      .status(401)
      .json({ success: false, message: "Invalid token", code: "INVALID_TOKEN" });
  }
};

// ── GET /api/notifications — paginated list ───────────────────────────

router.get("/", authenticateToken, async (req, res) => {
  try {
    const userId = req.user.user_id;
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit) || 20));
    const type = req.query.type || undefined;

    const result = await notificationService.getUserNotifications(userId, {
      page,
      limit,
      type,
    });

    res.json({ success: true, ...result });
  } catch (error) {
    console.error("[NOTIFICATION-ROUTES] Error fetching notifications:", error);
    res.status(500).json({ success: false, message: "Failed to fetch notifications" });
  }
});

// ── GET /api/notifications/unread-count ───────────────────────────────

router.get("/unread-count", authenticateToken, async (req, res) => {
  try {
    const count = await notificationService.getUnreadCount(req.user.user_id);
    res.json({ success: true, unreadCount: count });
  } catch (error) {
    console.error("[NOTIFICATION-ROUTES] Error fetching unread count:", error);
    res.status(500).json({ success: false, message: "Failed to fetch unread count" });
  }
});

// ── PUT /api/notifications/read-all ───────────────────────────────────

router.put("/read-all", authenticateToken, async (req, res) => {
  try {
    await notificationService.markAllAsRead(req.user.user_id);
    res.json({ success: true, message: "All notifications marked as read" });
  } catch (error) {
    console.error("[NOTIFICATION-ROUTES] Error marking all as read:", error);
    res.status(500).json({ success: false, message: "Failed to mark all as read" });
  }
});

// ── PUT /api/notifications/:id/read ───────────────────────────────────

router.put("/:id/read", authenticateToken, async (req, res) => {
  try {
    const notificationId = parseInt(req.params.id);
    if (isNaN(notificationId)) {
      return res.status(400).json({ success: false, message: "Invalid notification ID" });
    }

    await notificationService.markAsRead(notificationId, req.user.user_id);
    res.json({ success: true, message: "Notification marked as read" });
  } catch (error) {
    console.error("[NOTIFICATION-ROUTES] Error marking as read:", error);
    res.status(500).json({ success: false, message: "Failed to mark as read" });
  }
});

// ── DELETE /api/notifications/:id ─────────────────────────────────────

router.delete("/:id", authenticateToken, async (req, res) => {
  try {
    const notificationId = parseInt(req.params.id);
    if (isNaN(notificationId)) {
      return res.status(400).json({ success: false, message: "Invalid notification ID" });
    }

    await notificationService.deleteNotification(notificationId, req.user.user_id);
    res.json({ success: true, message: "Notification deleted" });
  } catch (error) {
    console.error("[NOTIFICATION-ROUTES] Error deleting notification:", error);
    res.status(500).json({ success: false, message: "Failed to delete notification" });
  }
});

// ── POST /api/notifications/fcm-token — register device token ─────────

router.post("/fcm-token", authenticateToken, async (req, res) => {
  try {
    const { token, platform } = req.body;
    if (!token || !platform) {
      return res.status(400).json({ success: false, message: "token and platform required" });
    }
    if (!["android", "ios"].includes(platform)) {
      return res.status(400).json({ success: false, message: "platform must be android or ios" });
    }

    await prisma.deviceToken.upsert({
      where: {
        user_id_token: { user_id: req.user.user_id, token },
      },
      update: { platform, updated_at: new Date() },
      create: { user_id: req.user.user_id, token, platform },
    });

    res.json({ success: true, message: "Device token registered" });
  } catch (error) {
    console.error("[NOTIFICATION-ROUTES] Error registering FCM token:", error);
    res.status(500).json({ success: false, message: "Failed to register device token" });
  }
});

// ── POST /api/notifications/test-push — send a test push (dev only) ───

router.post("/test-push", authenticateToken, async (req, res) => {
  try {
    // Create an in-app notification AND trigger FCM push
    const notification = await notificationService.createNotification({
      user_id: req.user.user_id,
      title: "🔔 Test Push Notification",
      body: "If you see this as a push, FCM is working!",
      type: "GENERAL",
      data: { test: "true" },
    });

    res.json({ success: true, message: "Test push sent", notification });
  } catch (error) {
    console.error("[NOTIFICATION-ROUTES] Test push error:", error);
    res.status(500).json({ success: false, message: "Failed to send test push" });
  }
});

// ── DELETE /api/notifications/fcm-token — unregister on logout ────────

router.delete("/fcm-token", authenticateToken, async (req, res) => {
  try {
    const { token } = req.body;
    if (!token) {
      return res.status(400).json({ success: false, message: "token required" });
    }

    await prisma.deviceToken.deleteMany({
      where: { user_id: req.user.user_id, token },
    });

    res.json({ success: true, message: "Device token unregistered" });
  } catch (error) {
    console.error("[NOTIFICATION-ROUTES] Error unregistering FCM token:", error);
    res.status(500).json({ success: false, message: "Failed to unregister device token" });
  }
});

// ── POST /api/notifications/broadcast — admin sends news to all users ─

router.post("/broadcast", authenticateToken, async (req, res) => {
  try {
    const { title, body } = req.body;
    if (!title || !body) {
      return res.status(400).json({ success: false, message: "title and body required" });
    }

    // Get all distinct user IDs that have registered device tokens
    const users = await prisma.deviceToken.findMany({
      select: { user_id: true },
      distinct: ["user_id"],
    });
    const userIds = users.map((u) => u.user_id);

    if (userIds.length === 0) {
      return res.json({ success: true, message: "No registered users to notify", count: 0 });
    }

    await notificationService.handleDomainEvent({
      type: "PLATFORM_NEWS",
      data: { title, body, targetUserIds: userIds },
    });

    res.json({ success: true, message: `Broadcast sent to ${userIds.length} users`, count: userIds.length });
  } catch (error) {
    console.error("[NOTIFICATION-ROUTES] Broadcast error:", error);
    res.status(500).json({ success: false, message: "Failed to send broadcast" });
  }
});

module.exports = router;
