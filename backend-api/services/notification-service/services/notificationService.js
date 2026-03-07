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

class NotificationService {
  /**
   * Create a notification in the database.
   */
  async createNotification({ user_id, title, body, type, data = {} }) {
    return prisma.notification.create({
      data: {
        user_id: parseInt(user_id),
        title,
        body,
        type,
        data,
      },
    });
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

    return prisma.notification.createMany({ data: records });
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
}

module.exports = new NotificationService();
