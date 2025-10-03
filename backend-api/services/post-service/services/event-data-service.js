require("dotenv").config();
const amqp = require("amqplib");
const { randomUUID } = require("crypto");

class EventDataService {
  constructor() {
    this.connection = null;
    this.channel = null;
    this.replyQueue = null;
    this.pendingRequests = new Map();
    this.isConnected = false;

    this.config = {
      url: process.env.RABBITMQ_URL || "amqp://localhost:5672",
      exchange: process.env.RABBITMQ_EXCHANGE || "eventbn_exchange",
      eventDataRequestQueue: "event_data_requests",
      timeout: 10000, // 10 seconds timeout for event data requests
    };
  }

  async connect() {
    if (this.connection && !this.connection.connection.stream.destroyed) {
      return true;
    }

    try {
      console.log("[EVENT-DATA-SERVICE] Connecting to RabbitMQ...");

      this.connection = await amqp.connect(this.config.url);
      this.channel = await this.connection.createChannel();

      // Setup exchange
      await this.channel.assertExchange(this.config.exchange, "topic", {
        durable: true,
      });

      // Setup event data request queue
      await this.channel.assertQueue(this.config.eventDataRequestQueue, {
        durable: true,
      });

      // Setup reply queue for receiving responses
      const replyQueueInfo = await this.channel.assertQueue("", {
        exclusive: true,
        autoDelete: true,
      });
      this.replyQueue = replyQueueInfo.queue;

      // Listen for responses on reply queue
      await this.channel.consume(
        this.replyQueue,
        (msg) => {
          if (msg) {
            const correlationId = msg.properties.correlationId;
            const request = this.pendingRequests.get(correlationId);

            if (request) {
              this.pendingRequests.delete(correlationId);
              clearTimeout(request.timeout);

              try {
                const response = JSON.parse(msg.content.toString());
                request.resolve(response);
              } catch (error) {
                console.error(
                  "[EVENT-DATA-SERVICE] Error parsing response:",
                  error
                );
                request.reject(new Error("Invalid JSON response"));
              }
            }

            this.channel.ack(msg);
          }
        },
        { noAck: false }
      );

      this.isConnected = true;
      console.log("[EVENT-DATA-SERVICE] Connected to RabbitMQ successfully");
      return true;
    } catch (error) {
      console.error("[EVENT-DATA-SERVICE] Connection failed:", error.message);
      this.isConnected = false;
      return false;
    }
  }

  async disconnect() {
    try {
      if (this.channel) {
        await this.channel.close();
      }
      if (this.connection) {
        await this.connection.close();
      }
      this.isConnected = false;
      console.log("[EVENT-DATA-SERVICE] Disconnected from RabbitMQ");
    } catch (error) {
      console.error("[EVENT-DATA-SERVICE] Error during disconnect:", error);
    }
  }

  async getEventData(eventId) {
    if (!this.isConnected) {
      const connected = await this.connect();
      if (!connected) {
        throw new Error("Failed to connect to RabbitMQ");
      }
    }

    return new Promise((resolve, reject) => {
      const correlationId = randomUUID();
      const timeoutId = setTimeout(() => {
        this.pendingRequests.delete(correlationId);
        reject(new Error("Event data request timeout"));
      }, this.config.timeout);

      this.pendingRequests.set(correlationId, {
        resolve,
        reject,
        timeout: timeoutId,
      });

      const requestData = {
        action: "GET_EVENT",
        eventId: eventId,
        timestamp: new Date().toISOString(),
      };

      console.log(
        `[EVENT-DATA-SERVICE] Requesting event data for ID: ${eventId}`
      );

      this.channel.sendToQueue(
        this.config.eventDataRequestQueue,
        Buffer.from(JSON.stringify(requestData)),
        {
          correlationId: correlationId,
          replyTo: this.replyQueue,
          persistent: true,
          timestamp: Date.now(),
        }
      );
    });
  }
}

// Create singleton instance
const eventDataService = new EventDataService();

// Graceful shutdown
process.on("SIGTERM", () => eventDataService.disconnect());
process.on("SIGINT", () => eventDataService.disconnect());

// Export the service instance and a helper function
module.exports = {
  eventDataService,
  getEventData: (eventId) => eventDataService.getEventData(eventId),
};