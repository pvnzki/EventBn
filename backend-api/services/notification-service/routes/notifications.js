const express = require("express");
const router = express.Router();
const jwt = require("jsonwebtoken");
const notificationService = require("../services/notificationService");

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

module.exports = router;
