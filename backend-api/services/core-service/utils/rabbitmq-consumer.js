require("dotenv").config();
const amqp = require("amqplib");
const prisma = require("../../lib/database.js");

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
        postEvents: process.env.RABBITMQ_POST_QUEUE || "post_events",
        socialEvents: process.env.RABBITMQ_SOCIAL_QUEUE || "social_events",
        analyticsEvents: "analytics_events",
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
          arguments: {
            "x-message-ttl": 24 * 60 * 60 * 1000,
            "x-max-length": 10000,
            "x-dead-letter-exchange": `${this.config.exchange}.dlx`,
            "x-dead-letter-routing-key": `${queueName}.failed`,
          },
        });
      }

      // Setup dead letter exchange
      await this.channel.assertExchange(
        `${this.config.exchange}.dlx`,
        "direct",
        {
          durable: true,
        }
      );

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

  // Specific event implementations
  async handlePostCreated(data) {
    // Update user statistics
    await prisma.$executeRaw`
      INSERT INTO user_stats (user_id, total_posts, created_at, updated_at)
      VALUES (${data.user_id}, 1, NOW(), NOW())
      ON CONFLICT (user_id) DO UPDATE SET
        total_posts = user_stats.total_posts + 1,
        updated_at = NOW()
    `;

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

    await this.startConsumer(
      this.config.queues.analyticsEvents,
      this.handleAnalyticsEvent.bind(this)
    );

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
