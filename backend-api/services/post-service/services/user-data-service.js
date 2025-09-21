require("dotenv").config();
const amqp = require("amqplib");
const { v4: uuidv4 } = require("uuid");

class UserDataService {
  constructor() {
    this.connection = null;
    this.channel = null;
    this.replyQueue = null;
    this.pendingRequests = new Map();
    this.isConnected = false;

    this.config = {
      url: process.env.RABBITMQ_URL || "amqp://localhost:5672",
      exchange: process.env.RABBITMQ_EXCHANGE || "eventbn_exchange",
      userDataRequestQueue: "user_data_requests",
      timeout: 10000, // 10 seconds timeout for user data requests
    };
  }

  async connect() {
    if (this.connection && !this.connection.connection.stream.destroyed) {
      return true;
    }

    try {
      console.log("[USER-DATA-SERVICE] Connecting to RabbitMQ...");

      this.connection = await amqp.connect(this.config.url);
      this.channel = await this.connection.createChannel();

      // Setup exchange
      await this.channel.assertExchange(this.config.exchange, "topic", {
        durable: true,
      });

      // Setup user data request queue
      await this.channel.assertQueue(this.config.userDataRequestQueue, {
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
            this.handleResponse(msg);
          }
        },
        { noAck: true }
      );

      // Connection error handlers
      this.connection.on("error", (error) => {
        console.error("[USER-DATA-SERVICE] Connection error:", error);
        this.isConnected = false;
      });

      this.connection.on("close", () => {
        console.warn("[USER-DATA-SERVICE] Connection closed");
        this.isConnected = false;
      });

      this.isConnected = true;
      console.log("✅ [USER-DATA-SERVICE] Connected successfully");
      return true;
    } catch (error) {
      console.error("❌ [USER-DATA-SERVICE] Connection failed:", error.message);
      this.isConnected = false;
      return false;
    }
  }

  handleResponse(msg) {
    try {
      const correlationId = msg.properties.correlationId;
      const response = JSON.parse(msg.content.toString());

      const pendingRequest = this.pendingRequests.get(correlationId);
      if (pendingRequest) {
        clearTimeout(pendingRequest.timeout);
        pendingRequest.resolve(response);
        this.pendingRequests.delete(correlationId);
      }
    } catch (error) {
      console.error("[USER-DATA-SERVICE] Error handling response:", error);
    }
  }

  async getUserData(userId) {
    if (!this.isConnected) {
      await this.connect();
    }

    return new Promise((resolve, reject) => {
      const correlationId = uuidv4();

      const timeout = setTimeout(() => {
        this.pendingRequests.delete(correlationId);
        reject(new Error("User data request timeout"));
      }, this.config.timeout);

      this.pendingRequests.set(correlationId, {
        resolve,
        reject,
        timeout,
      });

      const message = {
        type: "GET_USER_DATA",
        data: { userId },
        replyTo: this.replyQueue,
        correlationId,
        timestamp: new Date().toISOString(),
      };

      this.channel.sendToQueue(
        this.config.userDataRequestQueue,
        Buffer.from(JSON.stringify(message)),
        {
          correlationId,
          replyTo: this.replyQueue,
        }
      );
    });
  }

  async getUsersBatch(userIds) {
    if (!this.isConnected) {
      await this.connect();
    }

    return new Promise((resolve, reject) => {
      const correlationId = uuidv4();

      const timeout = setTimeout(() => {
        this.pendingRequests.delete(correlationId);
        reject(new Error("Batch user data request timeout"));
      }, this.config.timeout);

      this.pendingRequests.set(correlationId, {
        resolve,
        reject,
        timeout,
      });

      const message = {
        type: "GET_USERS_BATCH",
        data: { userIds },
        replyTo: this.replyQueue,
        correlationId,
        timestamp: new Date().toISOString(),
      };

      this.channel.sendToQueue(
        this.config.userDataRequestQueue,
        Buffer.from(JSON.stringify(message)),
        {
          correlationId,
          replyTo: this.replyQueue,
        }
      );
    });
  }

  async initialize() {
    try {
      console.log("[USER-DATA-SERVICE] Initializing service...");
      const connected = await this.connect();
      if (connected) {
        console.log("✅ [USER-DATA-SERVICE] Service initialized successfully");
        return true;
      } else {
        console.log("⚠️ [USER-DATA-SERVICE] Service initialization failed");
        return false;
      }
    } catch (error) {
      console.error("❌ [USER-DATA-SERVICE] Initialization error:", error);
      return false;
    }
  }

  async cleanup() {
    return await this.close();
  }

  async close() {
    try {
      // Clear all pending requests
      for (const [correlationId, request] of this.pendingRequests) {
        clearTimeout(request.timeout);
        request.reject(new Error("Connection closing"));
      }
      this.pendingRequests.clear();

      if (this.channel) {
        await this.channel.close();
      }
      if (this.connection) {
        await this.connection.close();
      }

      this.isConnected = false;
      console.log("[USER-DATA-SERVICE] Connection closed gracefully");
    } catch (error) {
      console.error("[USER-DATA-SERVICE] Error closing connection:", error);
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
        pendingRequests: this.pendingRequests.size,
        replyQueue: this.replyQueue,
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
const userDataService = new UserDataService();

module.exports = {
  userDataService,
  initialize: () => userDataService.initialize(),
  cleanup: () => userDataService.cleanup(),
  getUserData: (userId) => userDataService.getUserData(userId),
  getUsersBatch: (userIds) => userDataService.getUsersBatch(userIds),
  getUserDataHealth: () => userDataService.healthCheck(),
  closeUserDataService: () => userDataService.close(),
};
