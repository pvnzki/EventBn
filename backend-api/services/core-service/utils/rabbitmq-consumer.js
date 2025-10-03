require("dotenv").config();
const amqp = require("amqplib");
const { PrismaClient } = require("@prisma/client");

const prisma = new PrismaClient();

class CoreServiceRabbitMQConsumer {
  constructor() {
    this.connection = null;
    this.channel = null;
    this.isConnecting = false;
    this.consumers = new Map();
    this.reconnectDelay = 5000;
    this.maxReconnectAttempts = 10;
    this.reconnectAttempts = 0;

    this.config = {
      url: process.env.RABBITMQ_URL || "amqp://localhost:5672",
      exchange: process.env.RABBITMQ_EXCHANGE || "eventbn_exchange",
      queues: {
        postEvents: process.env.RABBITMQ_POST_Q || "post_events",
        socialEvents: process.env.RABBITMQ_SOCIAL_QUEUE || "social_events",
        userDataRequests: "user_data_requests", // New queue for user data requests
        eventDataRequests: "event_data_requests", // New queue for event data requests
      },
      prefetch: 10,
    };
  }

  async connect() {
    if (this.connection && !this.connection.connection.stream.destroyed) {
      return true;
    }

    if (this.isConnecting) {
      return false;
    }

    this.isConnecting = true;

    try {
      console.log("[CORE-RABBITMQ-CONSUMER] Connecting to RabbitMQ...");

      this.connection = await amqp.connect(this.config.url);
      this.channel = await this.connection.createChannel();

      await this.channel.prefetch(this.config.prefetch);

      // Setup exchange
      await this.channel.assertExchange(this.config.exchange, "topic", {
        durable: true,
      });

      // Setup queues
      for (const [name, queueName] of Object.entries(this.config.queues)) {
        await this.channel.assertQueue(queueName, {
          durable: true,
        });
      }

      // Connection error handlers
      this.connection.on("error", (error) => {
        console.error("[CORE-RABBITMQ-CONSUMER] Connection error:", error);
        this.handleConnectionError();
      });

      this.connection.on("close", () => {
        console.warn("[CORE-RABBITMQ-CONSUMER] Connection closed");
        this.handleConnectionError();
      });

      this.reconnectAttempts = 0;
      this.isConnecting = false;

      console.log("✅ [CORE-RABBITMQ-CONSUMER] Connected successfully");
      return true;
    } catch (error) {
      console.error(
        "❌ [CORE-RABBITMQ-CONSUMER] Connection failed:",
        error.message
      );
      this.isConnecting = false;
      this.handleConnectionError();
      return false;
    }
  }

  async handleConnectionError() {
    this.connection = null;
    this.channel = null;
    this.consumers.clear();
    this.isConnecting = false;

    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++;
      const delay = this.reconnectDelay * this.reconnectAttempts;

      console.log(
        `[CORE-RABBITMQ-CONSUMER] Attempting reconnection ${this.reconnectAttempts}/${this.maxReconnectAttempts} in ${delay}ms`
      );

      setTimeout(() => {
        this.connect().then(() => {
          this.restartAllConsumers();
        });
      }, delay);
    }
  }

  async restartAllConsumers() {
    for (const [queueName, handler] of this.consumers.entries()) {
      await this.startConsumer(queueName, handler);
    }
  }

  async startConsumer(queueName, messageHandler) {
    try {
      if (!this.channel) {
        const connected = await this.connect();
        if (!connected) {
          throw new Error("RabbitMQ connection not available");
        }
      }

      this.consumers.set(queueName, messageHandler);
      console.log(
        `[👂] [CORE-RABBITMQ-CONSUMER] Starting consumer for queue: ${queueName}`
      );

      await this.channel.consume(
        queueName,
        async (msg) => {
          if (msg !== null) {
            const startTime = Date.now();
            let event = null;

            try {
              event = JSON.parse(msg.content.toString());

              console.log(
                `[📥] [CORE-RABBITMQ-CONSUMER] Processing event: ${event.type} (ID: ${event.id})`
              );

              const success = await Promise.race([
                messageHandler(event),
                this.createTimeoutPromise(30000),
              ]);

              const processingTime = Date.now() - startTime;

              if (success) {
                this.channel.ack(msg);
                console.log(
                  `[✅] [CORE-RABBITMQ-CONSUMER] Successfully processed event: ${event.type} in ${processingTime}ms`
                );
              } else {
                const retryCount =
                  (msg.properties.headers &&
                    msg.properties.headers["x-retry-count"]) ||
                  0;

                if (retryCount < 3) {
                  const delay = Math.pow(2, retryCount) * 1000;
                  console.log(
                    `[⚠️] [CORE-RABBITMQ-CONSUMER] Processing failed, retrying in ${delay}ms (attempt ${
                      retryCount + 1
                    }/3)`
                  );

                  setTimeout(() => {
                    this.channel.nack(msg, false, true);
                  }, delay);
                } else {
                  console.log(
                    `[❌] [CORE-RABBITMQ-CONSUMER] Max retries exceeded, sending to DLQ: ${event.type}`
                  );
                  this.channel.nack(msg, false, false);
                }
              }
            } catch (error) {
              const processingTime = Date.now() - startTime;
              console.error(
                `[❌] [CORE-RABBITMQ-CONSUMER] Error processing message in ${processingTime}ms:`,
                error
              );
              this.channel.nack(msg, false, false);
            }
          }
        },
        { noAck: false }
      );

      console.log(
        `[✅] [CORE-RABBITMQ-CONSUMER] Consumer started for queue: ${queueName}`
      );
      return true;
    } catch (error) {
      console.error(
        `[❌] [CORE-RABBITMQ-CONSUMER] Failed to start consumer for ${queueName}:`,
        error
      );
      return false;
    }
  }

  createTimeoutPromise(timeout) {
    return new Promise((_, reject) => {
      setTimeout(() => reject(new Error("Processing timeout")), timeout);
    });
  }

  // Post event handlers
  async handlePostEvent(event) {
    const { type, data, metadata } = event;

    try {
      switch (type) {
        case "POST_CREATED":
          return await this.handlePostCreated(data);

        case "POST_UPDATED":
          return await this.handlePostUpdated(data);

        case "POST_DELETED":
          return await this.handlePostDeleted(data);

        default:
          console.warn(
            `[CORE-RABBITMQ-CONSUMER] Unknown post event type: ${type}`
          );
          return true;
      }
    } catch (error) {
      console.error(
        `[CORE-RABBITMQ-CONSUMER] Error handling post event ${type}:`,
        error
      );
      return false;
    }
  }

  // Social event handlers
  async handleSocialEvent(event) {
    const { type, data, metadata } = event;

    // Analytics/engagement tracking is disabled - ignore all social events
    console.log(
      `[✅] [CORE-RABBITMQ-CONSUMER] Analytics disabled - ignoring social event: ${type}`
    );
    return true; // Successfully "processed" by ignoring

    try {
      switch (type) {
        case "POST_LIKED":
          return await this.handlePostLiked(data);

        case "POST_UNLIKED":
          return await this.handlePostUnliked(data);

        case "COMMENT_CREATED":
          return await this.handleCommentCreated(data);

        case "USER_FOLLOWED":
          return await this.handleUserFollowed(data);

        default:
          console.warn(
            `[CORE-RABBITMQ-CONSUMER] Unknown social event type: ${type}`
          );
          return true;
      }
    } catch (error) {
      console.error(
        `[CORE-RABBITMQ-CONSUMER] Error handling social event ${type}:`,
        error
      );
      return false;
    }
  }

  // Analytics event handlers
  async handleAnalyticsEvent(event) {
    const { type, data, metadata } = event;

    return true;

    try {
      switch (type) {
        case "ENGAGEMENT_METRICS":
          return await this.handleEngagementMetrics(data);

        case "FEED_INTERACTION":
          return await this.handleFeedInteraction(data);

        default:
          console.warn(
            `[CORE-RABBITMQ-CONSUMER] Unknown analytics event type: ${type}`
          );
          return true;
      }
    } catch (error) {
      console.error(
        `[CORE-RABBITMQ-CONSUMER] Error handling analytics event ${type}:`,
        error
      );
      return false;
    }
  }

  // User data request handler
  async handleUserDataRequest(event) {
    const { type, data, replyTo, correlationId } = event;

    try {
      switch (type) {
        case "GET_USER_DATA":
          return await this.handleGetUserData(data, replyTo, correlationId);

        case "GET_USERS_BATCH":
          return await this.handleGetUsersBatch(data, replyTo, correlationId);

        default:
          console.warn(
            `[CORE-RABBITMQ-CONSUMER] Unknown user data request type: ${type}`
          );
          return true;
      }
    } catch (error) {
      console.error(
        `[CORE-RABBITMQ-CONSUMER] Error handling user data request ${type}:`,
        error
      );
      return false;
    }
  }

  // User data request implementations
  async handleGetUserData(data, replyTo, correlationId) {
    const { userId } = data;

    try {
      const user = await prisma.user.findUnique({
        where: { user_id: parseInt(userId) },
        select: {
          user_id: true,
          name: true,
          email: true,
          profile_picture: true,
          is_active: true,
          created_at: true,
        },
      });

      const response = {
        success: true,
        user: user
          ? {
              id: user.user_id,
              name: user.name,
              email: user.email,
              profilePicture: user.profile_picture,
              isActive: user.is_active,
              createdAt: user.created_at,
            }
          : null,
      };

      // Send response back via RabbitMQ
      if (replyTo && correlationId) {
        await this.channel.sendToQueue(
          replyTo,
          Buffer.from(JSON.stringify(response)),
          {
            correlationId,
          }
        );
      }

      console.log(
        `[📤] [CORE-RABBITMQ-CONSUMER] Sent user data for user: ${userId}`
      );
      return true;
    } catch (error) {
      const allowFallback = process.env.ALLOW_JWT_FALLBACK === "true";
      const isInitError = /Can't reach database server/i.test(error.message);
      if (allowFallback && isInitError) {
        console.warn(
          `[⚠️] [CORE-RABBITMQ-CONSUMER] DB unreachable, sending fallback user (ALLOW_JWT_FALLBACK) for userId=${userId}`
        );
        const response = {
          success: true,
          user: {
            id: parseInt(userId),
            name: `User ${userId}`,
            email: null,
            profilePicture: null,
            isActive: true,
            createdAt: new Date().toISOString(),
            fallback: true,
          },
          fallback: true,
        };
        if (replyTo && correlationId) {
          await this.channel.sendToQueue(
            replyTo,
            Buffer.from(JSON.stringify(response)),
            { correlationId }
          );
        }
        return true; // treat as handled to avoid retries
      }

      console.error(
        `[❌] [CORE-RABBITMQ-CONSUMER] Error getting user data (no fallback):`,
        error.message
      );

      if (replyTo && correlationId) {
        const errorResponse = {
          success: false,
          error: allowFallback
            ? "User data unavailable"
            : "Failed to retrieve user data",
        };
        await this.channel.sendToQueue(
          replyTo,
          Buffer.from(JSON.stringify(errorResponse)),
          { correlationId }
        );
      }
      return isInitError ? true : false; // avoid endless retries on init error
    }
  }

  async handleGetUsersBatch(data, replyTo, correlationId) {
    const { userIds } = data;

    try {
      const users = await prisma.user.findMany({
        where: {
          user_id: {
            in: userIds.map((id) => parseInt(id)),
          },
        },
        select: {
          user_id: true,
          name: true,
          email: true,
          profile_picture: true,
          is_active: true,
          created_at: true,
        },
      });

      const response = {
        success: true,
        users: users.map((user) => ({
          id: user.user_id,
          name: user.name,
          email: user.email,
          profilePicture: user.profile_picture,
          isActive: user.is_active,
          createdAt: user.created_at,
        })),
      };

      // Send response back via RabbitMQ
      if (replyTo && correlationId) {
        await this.channel.sendToQueue(
          replyTo,
          Buffer.from(JSON.stringify(response)),
          {
            correlationId,
          }
        );
      }

      console.log(
        `[📤] [CORE-RABBITMQ-CONSUMER] Sent batch user data for ${userIds.length} users`
      );
      return true;
    } catch (error) {
      const allowFallback = process.env.ALLOW_JWT_FALLBACK === "true";
      const isInitError = /Can't reach database server/i.test(error.message);
      if (allowFallback && isInitError) {
        console.warn(
          `[⚠️] [CORE-RABBITMQ-CONSUMER] DB unreachable, sending fallback batch users (ALLOW_JWT_FALLBACK) count=${userIds.length}`
        );
        const response = {
          success: true,
          users: userIds.map((id) => ({
            id: parseInt(id),
            name: `User ${id}`,
            email: null,
            profilePicture: null,
            isActive: true,
            createdAt: new Date().toISOString(),
            fallback: true,
          })),
          fallback: true,
        };
        if (replyTo && correlationId) {
          await this.channel.sendToQueue(
            replyTo,
            Buffer.from(JSON.stringify(response)),
            { correlationId }
          );
        }
        return true;
      }

      console.error(
        `[❌] [CORE-RABBITMQ-CONSUMER] Error getting batch user data (no fallback):`,
        error.message
      );

      if (replyTo && correlationId) {
        const errorResponse = {
          success: false,
          error: allowFallback
            ? "Batch user data unavailable"
            : "Failed to retrieve batch user data",
        };
        await this.channel.sendToQueue(
          replyTo,
          Buffer.from(JSON.stringify(errorResponse)),
          { correlationId }
        );
      }
      return isInitError ? true : false;
    }
  }

  // Event data request handler
  async handleEventDataRequest(msg) {
    try {
      // Parse the message content
      const messageData = JSON.parse(msg.content.toString());
      const { action, eventId } = messageData;
      const { correlationId, replyTo } = msg.properties;

      console.log(
        `[CORE-RABBITMQ-CONSUMER] Processing event data request: ${action} for event ID: ${eventId}`
      );

      switch (action) {
        case "GET_EVENT":
          return await this.handleGetEventData(
            { eventId },
            replyTo,
            correlationId
          );

        default:
          console.warn(
            `[CORE-RABBITMQ-CONSUMER] Unknown event data request action: ${action}`
          );
          return true;
      }
    } catch (error) {
      console.error(
        `[CORE-RABBITMQ-CONSUMER] Error handling event data request:`,
        error
      );
      return false;
    }
  }

  // Event data request implementations
  async handleGetEventData(data, replyTo, correlationId) {
    const { eventId } = data;

    try {
      const event = await prisma.event.findUnique({
        where: { event_id: parseInt(eventId) },
        select: {
          event_id: true,
          title: true,
          description: true,
          category: true,
          venue: true,
          location: true,
          start_time: true,
          end_time: true,
          capacity: true,
          cover_image_url: true,
          other_images_url: true,
          status: true,
          created_at: true,
        },
      });

      const response = {
        success: true,
        event: event
          ? {
              id: event.event_id,
              title: event.title,
              description: event.description,
              imageUrl: event.cover_image_url, // Use actual cover_image_url field
              venue: event.venue, // Use actual venue field
              location: event.location, // Use actual location field
              startDateTime: event.start_time, // Use actual start_time field
              endDateTime: event.end_time, // Use actual end_time field
              category: event.category,
              isActive: event.status === 'ACTIVE', // Map status to isActive boolean
              status: event.status,
              capacity: event.capacity,
              otherImages: event.other_images_url, // Additional images
              createdAt: event.created_at,
            }
          : null,
        message: event ? "Event found" : "Event not found",
      };

      // Send response back via RabbitMQ
      if (replyTo && correlationId) {
        await this.channel.sendToQueue(
          replyTo,
          Buffer.from(JSON.stringify(response)),
          {
            correlationId,
          }
        );
      }

      console.log(
        `[📤] [CORE-RABBITMQ-CONSUMER] Sent event data for event: ${eventId}`
      );
      return true;
    } catch (error) {
      console.error(
        `[❌] [CORE-RABBITMQ-CONSUMER] Error getting event data:`,
        error.message
      );

      if (replyTo && correlationId) {
        const errorResponse = {
          success: false,
          event: null,
          error: "Failed to fetch event data",
          message: error.message,
        };
        await this.channel.sendToQueue(
          replyTo,
          Buffer.from(JSON.stringify(errorResponse)),
          { correlationId }
        );
      }
      return false;
    }
  }

  // Specific event implementations
  async handlePostCreated(data) {
    // user_stats tracking removed as unnecessary; keeping event engagement update only

    // If post is related to an event, update event engagement
    if (data.event_id) {
      await prisma.$executeRaw`
        UPDATE events 
        SET social_engagement_count = COALESCE(social_engagement_count, 0) + 1,
            updated_at = NOW()
        WHERE event_id = ${data.event_id}
      `;
    }

    console.log(
      `[💾] [CORE-RABBITMQ-CONSUMER] Updated stats for post creation: ${data.post_id}`
    );
    return true;
  }

  async handlePostLiked(data) {
    // Update user engagement metrics
    await prisma.$executeRaw`
      INSERT INTO user_engagement_metrics (
        user_id, likes_received, engagement_score, created_at, updated_at
      )
      VALUES (${data.post_user_id}, 1, 1, NOW(), NOW())
      ON CONFLICT (user_id) DO UPDATE SET
        likes_received = user_engagement_metrics.likes_received + 1,
        engagement_score = user_engagement_metrics.engagement_score + 1,
        updated_at = NOW()
    `;

    // Track social interaction
    await prisma.$executeRaw`
      INSERT INTO social_interactions (
        actor_user_id, target_user_id, interaction_type, 
        reference_id, created_at
      )
      VALUES (
        ${data.liked_by_user_id}, ${data.post_user_id}, 'LIKE',
        ${data.post_id}, NOW()
      )
    `;

    console.log(
      `[💾] [CORE-RABBITMQ-CONSUMER] Recorded like interaction: ${data.like_id}`
    );
    return true;
  }

  async handlePostUnliked(data) {
    // Update user engagement metrics (decrement)
    await prisma.$executeRaw`
      UPDATE user_engagement_metrics 
      SET 
        likes_received = GREATEST(0, likes_received - 1),
        engagement_score = GREATEST(0, engagement_score - 1),
        updated_at = NOW()
      WHERE user_id = ${data.post_user_id}
    `;

    console.log(
      `[💾] [CORE-RABBITMQ-CONSUMER] Updated stats for unlike: ${data.post_id}`
    );
    return true;
  }

  async handleCommentCreated(data) {
    // Update user engagement metrics
    await prisma.$executeRaw`
      INSERT INTO user_engagement_metrics (
        user_id, comments_received, engagement_score, created_at, updated_at
      )
      VALUES (${data.post_user_id || data.user_id}, 1, 2, NOW(), NOW())
      ON CONFLICT (user_id) DO UPDATE SET
        comments_received = user_engagement_metrics.comments_received + 1,
        engagement_score = user_engagement_metrics.engagement_score + 2,
        updated_at = NOW()
    `;

    console.log(
      `[💾] [CORE-RABBITMQ-CONSUMER] Updated stats for comment: ${data.comment_id}`
    );
    return true;
  }

  async handleUserFollowed(data) {
    // Track follow relationship in analytics
    await prisma.$executeRaw`
      INSERT INTO social_interactions (
        actor_user_id, target_user_id, interaction_type, created_at
      )
      VALUES (${data.follower_id}, ${data.following_id}, 'FOLLOW', NOW())
    `;

    // Update user metrics
    await prisma.$executeRaw`
      INSERT INTO user_stats (user_id, followers_count, created_at, updated_at)
      VALUES (${data.following_id}, 1, NOW(), NOW())
      ON CONFLICT (user_id) DO UPDATE SET
        followers_count = user_stats.followers_count + 1,
        updated_at = NOW()
    `;

    console.log(
      `[💾] [CORE-RABBITMQ-CONSUMER] Recorded follow relationship: ${data.follower_id} -> ${data.following_id}`
    );
    return true;
  }

  async handleEngagementMetrics(data) {
    // Store detailed engagement metrics
    await prisma.$executeRaw`
      INSERT INTO engagement_analytics (
        user_id, post_id, engagement_type, timestamp, metadata, created_at
      )
      VALUES (
        ${data.user_id}, ${data.post_id}, ${data.engagement_type},
        ${data.timestamp}, ${JSON.stringify(data.metadata || {})}, NOW()
      )
    `;

    console.log(
      `[💾] [CORE-RABBITMQ-CONSUMER] Recorded engagement metric: ${data.engagement_type}`
    );
    return true;
  }

  async handleFeedInteraction(data) {
    // Store feed interaction analytics
    await prisma.$executeRaw`
      INSERT INTO feed_analytics (
        user_id, post_id, interaction_type, duration, position, 
        timestamp, created_at
      )
      VALUES (
        ${data.user_id}, ${data.post_id}, ${data.interaction_type},
        ${data.duration}, ${data.position}, ${data.timestamp}, NOW()
      )
    `;

    console.log(
      `[💾] [CORE-RABBITMQ-CONSUMER] Recorded feed interaction: ${data.interaction_type}`
    );
    return true;
  }

  async startEventDataRequestConsumer() {
    try {
      if (!this.channel) {
        const connected = await this.connect();
        if (!connected) {
          throw new Error("RabbitMQ connection not available");
        }
      }

      const queueName = this.config.queues.eventDataRequests;
      console.log(
        `[👂] [CORE-RABBITMQ-CONSUMER] Starting event data request consumer for queue: ${queueName}`
      );

      await this.channel.consume(
        queueName,
        async (msg) => {
          if (msg !== null) {
            const startTime = Date.now();

            try {
              console.log(
                `[📥] [CORE-RABBITMQ-CONSUMER] Processing event data request`
              );

              const success = await Promise.race([
                this.handleEventDataRequest(msg),
                this.createTimeoutPromise(30000),
              ]);

              const processingTime = Date.now() - startTime;

              if (success) {
                this.channel.ack(msg);
                console.log(
                  `[✅] [CORE-RABBITMQ-CONSUMER] Successfully processed event data request in ${processingTime}ms`
                );
              } else {
                console.log(
                  `[❌] [CORE-RABBITMQ-CONSUMER] Failed to process event data request`
                );
                this.channel.nack(msg, false, false);
              }
            } catch (error) {
              console.error(
                `[💥] [CORE-RABBITMQ-CONSUMER] Error processing event data request:`,
                error
              );
              this.channel.nack(msg, false, false);
            }
          }
        },
        { noAck: false }
      );

      console.log(
        `[✅] [CORE-RABBITMQ-CONSUMER] Event data request consumer started successfully`
      );
    } catch (error) {
      console.error(
        `[❌] [CORE-RABBITMQ-CONSUMER] Failed to start event data request consumer:`,
        error
      );
      throw error;
    }
  }

  async startAllConsumers() {
    const success = await this.connect();
    if (!success) {
      return false;
    }

    // Start consumers for different queues
    await this.startConsumer(
      this.config.queues.postEvents,
      this.handlePostEvent.bind(this)
    );

    await this.startConsumer(
      this.config.queues.socialEvents,
      this.handleSocialEvent.bind(this)
    );

    // Analytics events queue not needed for current functionality
    // await this.startConsumer(
    //   this.config.queues.analyticsEvents,
    //   this.handleAnalyticsEvent.bind(this)
    // );

    await this.startConsumer(
      this.config.queues.userDataRequests,
      this.handleUserDataRequest.bind(this)
    );

    await this.startEventDataRequestConsumer();

    console.log(
      "[✅] [CORE-RABBITMQ-CONSUMER] All consumers started successfully"
    );
    return true;
  }

  async close() {
    try {
      this.consumers.clear();

      if (this.channel) {
        await this.channel.close();
      }
      if (this.connection) {
        await this.connection.close();
      }
      console.log("[CORE-RABBITMQ-CONSUMER] Connection closed gracefully");
    } catch (error) {
      console.error(
        "[CORE-RABBITMQ-CONSUMER] Error closing connection:",
        error
      );
    }
  }

  async healthCheck() {
    try {
      if (!this.connection || this.connection.connection.stream.destroyed) {
        return { status: "disconnected", error: "No active connection" };
      }

      if (!this.channel) {
        return { status: "error", error: "No active channel" };
      }

      return {
        status: "connected",
        consumers: this.consumers.size,
        exchange: this.config.exchange,
        queues: Object.keys(this.config.queues),
      };
    } catch (error) {
      return {
        status: "error",
        error: error.message,
      };
    }
  }
}

// Create singleton instance
const coreRabbitMQConsumer = new CoreServiceRabbitMQConsumer();

module.exports = {
  coreRabbitMQConsumer,
  startConsumer: () => coreRabbitMQConsumer.startAllConsumers(),
  getRabbitMQHealth: () => coreRabbitMQConsumer.healthCheck(),
  closeRabbitMQ: () => coreRabbitMQConsumer.close(),
};
