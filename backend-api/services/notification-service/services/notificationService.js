/**
 * Notification Service — Core Business Logic
 *
 * Observer Pattern: This service acts as the concrete Observer.
 * When a domain event arrives via RabbitMQ (the Subject/Event Bus),
 * this observer persists the notification to the database.
 *
 * Adding a new notification type only requires adding a handler here —
 * no changes to the publisher (Subject) are needed.
 */

const prisma = require("../lib/database");
const { sendPushToUser, sendPushToUsers } = require("./fcmSender");

class NotificationService {
  /**
   * Create a notification in the database.
   */
  async createNotification({ user_id, title, body, type, data = {} }) {
    const notification = await prisma.notification.create({
      data: {
        user_id: parseInt(user_id),
        title,
        body,
        type,
        data,
      },
    });

    // Send FCM push (fire-and-forget — don't block the DB write)
    sendPushToUser(user_id, { title, body }, { type, ...data }).catch(() => {});

    return notification;
  }

  /**
   * Create notifications for multiple users (e.g., event_created broadcast).
   */
  async createBulkNotifications(userIds, { title, body, type, data = {} }) {
    const records = userIds.map((uid) => ({
      user_id: parseInt(uid),
      title,
      body,
      type,
      data,
    }));

    const result = await prisma.notification.createMany({ data: records });

    // Send FCM push to all target users (fire-and-forget)
    sendPushToUsers(userIds, { title, body }, { type, ...data }).catch(() => {});

    return result;
  }

  /**
   * Get paginated notifications for a user.
   */
  async getUserNotifications(userId, { page = 1, limit = 20, type } = {}) {
    const where = { user_id: parseInt(userId) };
    if (type) where.type = type;

    const skip = (page - 1) * limit;

    const [notifications, total] = await Promise.all([
      prisma.notification.findMany({
        where,
        orderBy: { created_at: "desc" },
        skip,
        take: limit,
      }),
      prisma.notification.count({ where }),
    ]);

    return {
      notifications,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Get unread count for a user.
   */
  async getUnreadCount(userId) {
    return prisma.notification.count({
      where: { user_id: parseInt(userId), is_read: false },
    });
  }

  /**
   * Mark a single notification as read.
   */
  async markAsRead(notificationId, userId) {
    return prisma.notification.updateMany({
      where: {
        notification_id: parseInt(notificationId),
        user_id: parseInt(userId),
      },
      data: { is_read: true },
    });
  }

  /**
   * Mark all notifications as read for a user.
   */
  async markAllAsRead(userId) {
    return prisma.notification.updateMany({
      where: { user_id: parseInt(userId), is_read: false },
      data: { is_read: true },
    });
  }

  /**
   * Delete a single notification.
   */
  async deleteNotification(notificationId, userId) {
    return prisma.notification.deleteMany({
      where: {
        notification_id: parseInt(notificationId),
        user_id: parseInt(userId),
      },
    });
  }

  /**
   * Handle domain events from RabbitMQ — the Observer's update() method.
   * Maps domain event types to notification creation.
   */
  async handleDomainEvent(event) {
    const { type, data } = event;

    try {
      switch (type) {
        case "TICKET_PURCHASED":
          return await this.handleTicketPurchased(data);

        case "PAYMENT_CONFIRMED":
          return await this.handlePaymentConfirmed(data);

        case "EVENT_CREATED":
          return await this.handleEventCreated(data);

        case "EVENT_UPDATED":
          return await this.handleEventUpdated(data);

        case "EVENT_CANCELLED":
          return await this.handleEventCancelled(data);

        case "EVENT_REMINDER":
          return await this.handleEventReminder(data);

        case "PASSWORD_CHANGED":
          return await this.handlePasswordChanged(data);

        case "TWO_FACTOR_ENABLED":
          return await this.handleTwoFactorEnabled(data);

        case "TWO_FACTOR_DISABLED":
          return await this.handleTwoFactorDisabled(data);

        case "LOGIN_SUCCESS":
          return await this.handleLoginSuccess(data);

        case "WELCOME":
          return await this.handleWelcome(data);

        case "PLATFORM_NEWS":
          return await this.handlePlatformNews(data);

        default:
          console.warn(
            `[NOTIFICATION-SERVICE] Unknown event type: ${type}`
          );
          return true;
      }
    } catch (error) {
      console.error(
        `[NOTIFICATION-SERVICE] Error handling event ${type}:`,
        error.message
      );
      return false;
    }
  }

  // ── Concrete event handlers ─────────────────────────────────────────

  async handleTicketPurchased(data) {
    const { userId, eventTitle, eventId, ticketCount, totalAmount } = data;

    await this.createNotification({
      user_id: userId,
      title: "Ticket Purchased! 🎉",
      body: `You purchased ${ticketCount || 1} ticket(s) for "${eventTitle}". Total: $${totalAmount || 0}`,
      type: "ticket_purchased",
      data: { eventId, ticketCount, totalAmount },
    });

    console.log(
      `[NOTIFICATION-SERVICE] Created ticket_purchased notification for user ${userId}`
    );
    return true;
  }

  async handlePaymentConfirmed(data) {
    const { userId, eventTitle, eventId, paymentId, amount } = data;

    await this.createNotification({
      user_id: userId,
      title: "Payment Confirmed ✅",
      body: `Your payment of $${amount} for "${eventTitle}" has been confirmed.`,
      type: "payment_confirmed",
      data: { eventId, paymentId, amount },
    });

    console.log(
      `[NOTIFICATION-SERVICE] Created payment_confirmed notification for user ${userId}`
    );
    return true;
  }

  async handleEventCreated(data) {
    const { eventTitle, eventId, organizerName, targetUserIds } = data;

    if (targetUserIds && targetUserIds.length > 0) {
      await this.createBulkNotifications(targetUserIds, {
        title: "New Event! 🎪",
        body: `"${eventTitle}" by ${organizerName || "an organizer"} is now live. Check it out!`,
        type: "event_created",
        data: { eventId },
      });

      console.log(
        `[NOTIFICATION-SERVICE] Created event_created notifications for ${targetUserIds.length} users`
      );
    }
    return true;
  }

  async handleEventUpdated(data) {
    const { eventTitle, eventId, targetUserIds, changes } = data;

    if (targetUserIds && targetUserIds.length > 0) {
      await this.createBulkNotifications(targetUserIds, {
        title: "Event Updated 📝",
        body: `"${eventTitle}" has been updated. ${changes || "Check the latest details."}`,
        type: "event_updated",
        data: { eventId, changes },
      });

      console.log(
        `[NOTIFICATION-SERVICE] Created event_updated notifications for ${targetUserIds.length} users`
      );
    }
    return true;
  }

  async handleEventCancelled(data) {
    const { eventTitle, eventId, targetUserIds } = data;

    if (targetUserIds && targetUserIds.length > 0) {
      await this.createBulkNotifications(targetUserIds, {
        title: "Event Cancelled ❌",
        body: `Unfortunately, "${eventTitle}" has been cancelled. Please check for refund details.`,
        type: "event_cancelled",
        data: { eventId },
      });

      console.log(
        `[NOTIFICATION-SERVICE] Created event_cancelled notifications for ${targetUserIds.length} users`
      );
    }
    return true;
  }

  async handleEventReminder(data) {
    const { eventTitle, eventId, targetUserIds, startsIn } = data;

    if (targetUserIds && targetUserIds.length > 0) {
      await this.createBulkNotifications(targetUserIds, {
        title: "Event Reminder ⏰",
        body: `"${eventTitle}" starts ${startsIn || "soon"}! Don't forget to attend.`,
        type: "event_reminder",
        data: { eventId },
      });

      console.log(
        `[NOTIFICATION-SERVICE] Created event_reminder notifications for ${targetUserIds.length} users`
      );
    }
    return true;
  }

  // ── Security & Account handlers ──────────────────────────────────────

  async handlePasswordChanged(data) {
    const { userId } = data;

    await this.createNotification({
      user_id: userId,
      title: "Password Changed \uD83D\uDD12",
      body: "Your password was changed successfully. If you didn't do this, please contact support immediately.",
      type: "security",
      data: { action: "password_changed" },
    });

    console.log(`[NOTIFICATION-SERVICE] Created password_changed notification for user ${userId}`);
    return true;
  }

  async handleTwoFactorEnabled(data) {
    const { userId } = data;

    await this.createNotification({
      user_id: userId,
      title: "2FA Enabled \uD83D\uDEE1\uFE0F",
      body: "Two-factor authentication has been enabled on your account. Your account is now more secure.",
      type: "security",
      data: { action: "2fa_enabled" },
    });

    console.log(`[NOTIFICATION-SERVICE] Created 2fa_enabled notification for user ${userId}`);
    return true;
  }

  async handleTwoFactorDisabled(data) {
    const { userId } = data;

    await this.createNotification({
      user_id: userId,
      title: "2FA Disabled \u26A0\uFE0F",
      body: "Two-factor authentication has been disabled. Your account is now less secure. If you didn't do this, change your password immediately.",
      type: "security",
      data: { action: "2fa_disabled" },
    });

    console.log(`[NOTIFICATION-SERVICE] Created 2fa_disabled notification for user ${userId}`);
    return true;
  }

  async handleLoginSuccess(data) {
    const { userId, email } = data;

    await this.createNotification({
      user_id: userId,
      title: "New Login Detected \uD83D\uDD11",
      body: `A new login was detected on your account (${email}). If this wasn't you, change your password immediately.`,
      type: "security",
      data: { action: "login_success" },
    });

    console.log(`[NOTIFICATION-SERVICE] Created login_success notification for user ${userId}`);
    return true;
  }

  async handleWelcome(data) {
    const { userId, name } = data;

    await this.createNotification({
      user_id: userId,
      title: "Welcome to EventBn! \uD83C\uDF89",
      body: `Hi ${name || "there"}! Welcome to EventBn. Start exploring events near you and book your next experience.`,
      type: "general",
      data: { action: "welcome" },
    });

    console.log(`[NOTIFICATION-SERVICE] Created welcome notification for user ${userId}`);
    return true;
  }

  async handlePlatformNews(data) {
    const { title, body, targetUserIds } = data;

    if (targetUserIds && targetUserIds.length > 0) {
      await this.createBulkNotifications(targetUserIds, {
        title: title || "EventBn Update \uD83D\uDCE2",
        body: body || "Check out what's new on EventBn!",
        type: "general",
        data: { action: "platform_news" },
      });

      console.log(`[NOTIFICATION-SERVICE] Created platform_news notifications for ${targetUserIds.length} users`);
    }
    return true;
  }
}

module.exports = new NotificationService();
