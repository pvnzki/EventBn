require("dotenv").config();
const amqp = require("amqplib");
const { PrismaClient } = require("@prisma/client");

// Use post-service's own Prisma client
const prisma = new PrismaClient();

class RabbitMQConsumer {
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
        userEvents: process.env.RABBITMQ_USER_QUEUE || "user_events",
        socialEvents: process.env.RABBITMQ_SOCIAL_QUEUE || "social_events",
      },
      prefetch: 10, // Process max 10 messages at once
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
      console.log("[RABBITMQ-CONSUMER] Connecting to RabbitMQ...");

      this.connection = await amqp.connect(this.config.url);
      this.channel = await this.connection.createChannel();

      // Set prefetch for better performance
      await this.channel.prefetch(this.config.prefetch);

      // Setup exchange
      await this.channel.assertExchange(this.config.exchange, "topic", {
        durable: true,
      });

      // Setup queues with error handling
      for (const [name, queueName] of Object.entries(this.config.queues)) {
        await this.channel.assertQueue(queueName, {
          durable: true,
          arguments: {
            "x-message-ttl": 24 * 60 * 60 * 1000, // 24 hours TTL
            "x-max-length": 10000, // Max 10k messages
            "x-dead-letter-exchange": `${this.config.exchange}.dlx`,
            "x-dead-letter-routing-key": `${queueName}.failed`,
          },
        });
      }

      // Setup dead letter exchange for failed messages
      await this.channel.assertExchange(
        `${this.config.exchange}.dlx`,
        "direct",
        {
          durable: true,
        }
      );

      // Connection error handlers
      this.connection.on("error", (error) => {
        console.error("[RABBITMQ-CONSUMER] Connection error:", error);
        this.handleConnectionError();
      });

      this.connection.on("close", () => {
        console.warn("[RABBITMQ-CONSUMER] Connection closed");
        this.handleConnectionError();
      });

      this.channel.on("error", (error) => {
        console.error("[RABBITMQ-CONSUMER] Channel error:", error);
      });

      this.reconnectAttempts = 0;
      this.isConnecting = false;

      console.log("✅ [RABBITMQ-CONSUMER] Connected successfully");
      return true;
    } catch (error) {
      console.error("❌ [RABBITMQ-CONSUMER] Connection failed:", error.message);
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
        `[RABBITMQ-CONSUMER] Attempting reconnection ${this.reconnectAttempts}/${this.maxReconnectAttempts} in ${delay}ms`
      );

      setTimeout(() => {
        this.connect().then(() => {
          // Restart all consumers after reconnection
          this.restartAllConsumers();
        });
      }, delay);
    } else {
      console.error("[RABBITMQ-CONSUMER] Max reconnection attempts reached");
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

      // Store consumer for restart after reconnection
      this.consumers.set(queueName, messageHandler);

      console.log(
        `[👂] [RABBITMQ-CONSUMER] Starting consumer for queue: ${queueName}`
      );

      await this.channel.consume(
        queueName,
        async (msg) => {
          if (msg !== null) {
            const startTime = Date.now();
            let event = null;

            try {
              // Parse message
              event = JSON.parse(msg.content.toString());

              // Add message metadata
              event.messageMetadata = {
                deliveryTag: msg.fields.deliveryTag,
                redelivered: msg.fields.redelivered,
                receivedAt: new Date().toISOString(),
                processingStarted: startTime,
              };

              console.log(
                `[📥] [RABBITMQ-CONSUMER] Processing event: ${event.type} (ID: ${event.id})`
              );

              // Process message with timeout
              const success = await Promise.race([
                messageHandler(event),
                this.createTimeoutPromise(30000), // 30 second timeout
              ]);

              const processingTime = Date.now() - startTime;

              if (success) {
                this.channel.ack(msg);
                console.log(
                  `[✅] [RABBITMQ-CONSUMER] Successfully processed event: ${event.type} in ${processingTime}ms`
                );
              } else {
                // Check retry count
                const retryCount =
                  (msg.properties.headers &&
                    msg.properties.headers["x-retry-count"]) ||
                  0;

                if (retryCount < 3) {
                  // Retry with exponential backoff
                  const delay = Math.pow(2, retryCount) * 1000; // 1s, 2s, 4s

                  console.log(
                    `[⚠️] [RABBITMQ-CONSUMER] Processing failed, retrying in ${delay}ms (attempt ${
                      retryCount + 1
                    }/3)`
                  );

                  setTimeout(() => {
                    this.channel.nack(msg, false, true);
                  }, delay);
                } else {
                  console.log(
                    `[❌] [RABBITMQ-CONSUMER] Max retries exceeded, sending to DLQ: ${event.type}`
                  );
                  this.channel.nack(msg, false, false);
                }
              }
            } catch (error) {
              const processingTime = Date.now() - startTime;
              console.error(
                `[❌] [RABBITMQ-CONSUMER] Error processing message in ${processingTime}ms:`,
                error
              );

              // Send malformed messages to dead letter queue
              this.channel.nack(msg, false, false);
            }
          }
        },
        {
          noAck: false, // Manual acknowledgment
        }
      );

      console.log(
        `[✅] [RABBITMQ-CONSUMER] Consumer started for queue: ${queueName}`
      );
      return true;
    } catch (error) {
      console.error(
        `[❌] [RABBITMQ-CONSUMER] Failed to start consumer for ${queueName}:`,
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

  // User event handlers
  async handleUserEvent(event) {
    const { type, data, metadata } = event;

    try {
      switch (type) {
        case "USER_CREATED":
          return await this.handleUserCreated(data);

        case "USER_UPDATED":
          return await this.handleUserUpdated(data);

        case "USER_DELETED":
          return await this.handleUserDeleted(data);

        case "USER_PROFILE_UPDATED":
          return await this.handleUserProfileUpdated(data);

        default:
          console.warn(`[RABBITMQ-CONSUMER] Unknown user event type: ${type}`);
          return true; // Don't retry unknown events
      }
    } catch (error) {
      console.error(
        `[RABBITMQ-CONSUMER] Error handling user event ${type}:`,
        error
      );
      return false; // Retry on database errors
    }
  }

  async handleUserCreated(userData) {
    // Create user cache in post service for faster lookups
    const userCache = {
      user_id: userData.user_id,
      name: userData.name,
      profile_picture: userData.profile_picture || null,
      is_active: userData.is_active || true,
      cached_at: new Date(),
    };

    await prisma.$executeRaw`
      INSERT INTO user_cache (user_id, name, profile_picture, is_active, cached_at, created_at, updated_at)
      VALUES (${userCache.user_id}, ${userCache.name}, ${userCache.profile_picture}, ${userCache.is_active}, ${userCache.cached_at}, NOW(), NOW())
      ON CONFLICT (user_id) DO NOTHING
    `;

    console.log(
      `[💾] [RABBITMQ-CONSUMER] Created user cache for user: ${userData.user_id}`
    );
    return true;
  }

  async handleUserUpdated(userData) {
    // Update user cache
    const result = await prisma.$executeRaw`
      INSERT INTO user_cache (user_id, name, profile_picture, is_active, cached_at, created_at, updated_at)
      VALUES (${userData.user_id}, ${userData.name}, ${userData.profile_picture}, ${userData.is_active}, NOW(), NOW(), NOW())
      ON CONFLICT (user_id) DO UPDATE SET
        name = EXCLUDED.name,
        profile_picture = EXCLUDED.profile_picture,
        is_active = EXCLUDED.is_active,
        cached_at = EXCLUDED.cached_at,
        updated_at = EXCLUDED.updated_at
    `;

    console.log(
      `[💾] [RABBITMQ-CONSUMER] Updated user cache for user: ${userData.user_id}`
    );
    return true;
  }

  async handleUserDeleted(userData) {
    const userId = userData.user_id;

    // Delete user's posts and related data
    await prisma.$transaction(async (tx) => {
      // Delete likes on user's posts
      await tx.$executeRaw`DELETE FROM post_likes WHERE post_id IN (SELECT post_id FROM posts WHERE user_id = ${userId})`;

      // Delete comments on user's posts
      await tx.$executeRaw`DELETE FROM post_comments WHERE post_id IN (SELECT post_id FROM posts WHERE user_id = ${userId})`;

      // Delete user's own likes and comments
      await tx.$executeRaw`DELETE FROM post_likes WHERE user_id = ${userId}`;
      await tx.$executeRaw`DELETE FROM post_comments WHERE user_id = ${userId}`;

      // Delete user's posts
      await tx.$executeRaw`DELETE FROM posts WHERE user_id = ${userId}`;

      // Delete user cache
      await tx.$executeRaw`DELETE FROM user_cache WHERE user_id = ${userId}`;
    });

    console.log(
      `[💾] [RABBITMQ-CONSUMER] Deleted all data for user: ${userId}`
    );
    return true;
  }

  async handleUserProfileUpdated(userData) {
    return await this.handleUserUpdated(userData);
  }

  async startAllConsumers() {
    const success = await this.connect();
    if (!success) {
      return false;
    }

    // Start user events consumer
    await this.startConsumer(
      this.config.queues.userEvents,
      this.handleUserEvent.bind(this)
    );

    console.log("[✅] [RABBITMQ-CONSUMER] All consumers started successfully");
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
      console.log("[RABBITMQ-CONSUMER] Connection closed gracefully");
    } catch (error) {
      console.error("[RABBITMQ-CONSUMER] Error closing connection:", error);
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
const rabbitmqConsumer = new RabbitMQConsumer();

module.exports = {
  rabbitmqConsumer,
  startConsumer: () => rabbitmqConsumer.startAllConsumers(),
  getRabbitMQHealth: () => rabbitmqConsumer.healthCheck(),
  closeRabbitMQ: () => rabbitmqConsumer.close(),
};
