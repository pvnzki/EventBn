/**
 * Notification Service — RabbitMQ Consumer (Observer)
 *
 * Implements the Observer Pattern: subscribes to the `notification_events` queue
 * on the RabbitMQ topic exchange. When any service publishes a notification event,
 * this consumer picks it up and delegates to notificationService.handleDomainEvent().
 */

require("dotenv").config();
const amqp = require("amqplib");
const notificationService = require("../services/notificationService");

class NotificationRabbitMQConsumer {
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
      queue: process.env.RABBITMQ_NOTIFICATION_QUEUE || "notification_events",
      routingKey: "notification.*",
      prefetch: 10,
    };
  }

  async connect() {
    if (this.connection && !this.connection.connection.stream.destroyed) {
      return true;
    }

    if (this.isConnecting) return false;
    this.isConnecting = true;

    try {
      console.log("[NOTIFICATION-RABBITMQ] Connecting to RabbitMQ...");

      this.connection = await amqp.connect(this.config.url);
      this.channel = await this.connection.createChannel();
      await this.channel.prefetch(this.config.prefetch);

      // Assert exchange (same shared exchange)
      await this.channel.assertExchange(this.config.exchange, "topic", {
        durable: true,
      });

      // Assert notification queue
      await this.channel.assertQueue(this.config.queue, { durable: true });

      // Bind queue to exchange with routing key
      await this.channel.bindQueue(
        this.config.queue,
        this.config.exchange,
        this.config.routingKey
      );

      // Connection error handlers
      this.connection.on("error", (error) => {
        console.error("[NOTIFICATION-RABBITMQ] Connection error:", error);
        this.handleConnectionError();
      });

      this.connection.on("close", () => {
        console.warn("[NOTIFICATION-RABBITMQ] Connection closed");
        this.handleConnectionError();
      });

      this.reconnectAttempts = 0;
      this.isConnecting = false;

      console.log("✅ [NOTIFICATION-RABBITMQ] Connected successfully");
      return true;
    } catch (error) {
      console.error(
        "❌ [NOTIFICATION-RABBITMQ] Connection failed:",
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
        `[NOTIFICATION-RABBITMQ] Reconnecting ${this.reconnectAttempts}/${this.maxReconnectAttempts} in ${delay}ms`
      );

      setTimeout(() => {
        this.connect().then(() => this.startConsumer());
      }, delay);
    } else {
      console.error(
        "[NOTIFICATION-RABBITMQ] Max reconnection attempts reached"
      );
    }
  }

  /**
   * Start consuming from the notification_events queue.
   * Each message is routed to notificationService.handleDomainEvent().
   */
  async startConsumer() {
    try {
      if (!this.channel) {
        const connected = await this.connect();
        if (!connected) {
          throw new Error("RabbitMQ connection not available");
        }
      }

      console.log(
        `[👂] [NOTIFICATION-RABBITMQ] Starting consumer for queue: ${this.config.queue}`
      );

      await this.channel.consume(
        this.config.queue,
        async (msg) => {
          if (msg === null) return;

          const startTime = Date.now();
          let event = null;

          try {
            event = JSON.parse(msg.content.toString());

            console.log(
              `[📥] [NOTIFICATION-RABBITMQ] Received event: ${event.type} (ID: ${event.id})`
            );

            const success = await Promise.race([
              notificationService.handleDomainEvent(event),
              this.createTimeoutPromise(30000),
            ]);

            const processingTime = Date.now() - startTime;

            if (success) {
              this.channel.ack(msg);
              console.log(
                `[✅] [NOTIFICATION-RABBITMQ] Processed: ${event.type} in ${processingTime}ms`
              );
            } else {
              this.handleRetry(msg, event);
            }
          } catch (error) {
            const processingTime = Date.now() - startTime;
            console.error(
              `[❌] [NOTIFICATION-RABBITMQ] Error processing message in ${processingTime}ms:`,
              error.message
            );
            this.channel.nack(msg, false, false);
          }
        },
        { noAck: false }
      );

      console.log(
        `[✅] [NOTIFICATION-RABBITMQ] Consumer started for queue: ${this.config.queue}`
      );
      return true;
    } catch (error) {
      console.error(
        `[❌] [NOTIFICATION-RABBITMQ] Failed to start consumer:`,
        error
      );
      return false;
    }
  }

  handleRetry(msg, event) {
    const retryCount =
      (msg.properties.headers && msg.properties.headers["x-retry-count"]) || 0;

    if (retryCount < 3) {
      const delay = Math.pow(2, retryCount) * 1000;
      console.log(
        `[⚠️] [NOTIFICATION-RABBITMQ] Retrying in ${delay}ms (attempt ${retryCount + 1}/3)`
      );
      setTimeout(() => {
        this.channel.nack(msg, false, true);
      }, delay);
    } else {
      console.log(
        `[❌] [NOTIFICATION-RABBITMQ] Max retries exceeded, sending to DLQ: ${event.type}`
      );
      this.channel.nack(msg, false, false);
    }
  }

  createTimeoutPromise(timeout) {
    return new Promise((_, reject) => {
      setTimeout(() => reject(new Error("Processing timeout")), timeout);
    });
  }

  async close() {
    try {
      if (this.channel) await this.channel.close();
      if (this.connection) await this.connection.close();
      console.log("[NOTIFICATION-RABBITMQ] Connection closed gracefully");
    } catch (error) {
      console.error("[NOTIFICATION-RABBITMQ] Error closing:", error);
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
      await this.channel.checkExchange(this.config.exchange);
      return {
        status: "connected",
        exchange: this.config.exchange,
        queue: this.config.queue,
      };
    } catch (error) {
      return { status: "error", error: error.message };
    }
  }
}

// Singleton
const consumer = new NotificationRabbitMQConsumer();

module.exports = {
  notificationConsumer: consumer,
  connectNotificationRabbitMQ: () => consumer.connect(),
  startNotificationConsumer: () => consumer.startConsumer(),
  getNotificationRabbitMQHealth: () => consumer.healthCheck(),
  closeNotificationRabbitMQ: () => consumer.close(),
};
