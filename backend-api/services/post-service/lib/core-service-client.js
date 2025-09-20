const axios = require("axios");

class CoreServiceClient {
  constructor() {
    this.baseURL = process.env.CORE_SERVICE_URL || "http://localhost:3001";
    this.serviceKey = process.env.INTER_SERVICE_KEY || "dev-service-key";
    this.timeout = 5000; // 5 seconds

    this.client = axios.create({
      baseURL: this.baseURL + "/internal/v1",
      timeout: this.timeout,
      headers: {
        "X-Service-Key": this.serviceKey,
        "Content-Type": "application/json",
      },
    });

    // Request interceptor for logging
    this.client.interceptors.request.use(
      (config) => {
        console.log(
          `[CORE-SERVICE-CLIENT] ${config.method?.toUpperCase()} ${config.url}`
        );
        return config;
      },
      (error) => {
        console.error("[CORE-SERVICE-CLIENT] Request error:", error);
        return Promise.reject(error);
      }
    );

    // Response interceptor for error handling
    this.client.interceptors.response.use(
      (response) => response,
      (error) => {
        const message =
          error.response?.data?.error || error.message || "Unknown error";
        console.error(`[CORE-SERVICE-CLIENT] Error: ${message}`);

        if (error.code === "ECONNREFUSED") {
          console.error("[CORE-SERVICE-CLIENT] Core service is not reachable");
        }

        return Promise.reject(error);
      }
    );
  }

  // Get user details by ID
  async getUserById(userId) {
    try {
      const response = await this.client.get(`/users/${userId}`);
      return response.data;
    } catch (error) {
      console.error(
        `[CORE-SERVICE-CLIENT] Failed to fetch user ${userId}:`,
        error.message
      );
      throw new Error(`Failed to fetch user details: ${error.message}`);
    }
  }

  // Get multiple users in a single request
  async getUsersBatch(userIds) {
    try {
      if (!Array.isArray(userIds) || userIds.length === 0) {
        throw new Error("userIds must be a non-empty array");
      }

      const response = await this.client.post("/users/batch", {
        userIds: userIds,
      });

      return response.data;
    } catch (error) {
      console.error(
        "[CORE-SERVICE-CLIENT] Failed to fetch users batch:",
        error.message
      );
      throw new Error(`Failed to fetch users: ${error.message}`);
    }
  }

  // Verify if user exists and is active
  async verifyUser(userId) {
    try {
      const response = await this.client.get(`/users/${userId}/verify`);
      return response.data;
    } catch (error) {
      console.error(
        `[CORE-SERVICE-CLIENT] Failed to verify user ${userId}:`,
        error.message
      );
      return { exists: false, active: false, verified: false };
    }
  }

  // Get event details by ID
  async getEventById(eventId) {
    try {
      const response = await this.client.get(`/events/${eventId}`);
      return response.data;
    } catch (error) {
      console.error(
        `[CORE-SERVICE-CLIENT] Failed to fetch event ${eventId}:`,
        error.message
      );
      throw new Error(`Failed to fetch event details: ${error.message}`);
    }
  }

  // Health check for core service
  async healthCheck() {
    try {
      const response = await axios.get(`${this.baseURL}/health`, {
        timeout: 3000,
      });
      return {
        status: "healthy",
        data: response.data,
      };
    } catch (error) {
      console.error(
        "[CORE-SERVICE-CLIENT] Health check failed:",
        error.message
      );
      return {
        status: "unhealthy",
        error: error.message,
      };
    }
  }

  // Utility method to check if core service is reachable
  async isReachable() {
    try {
      const health = await this.healthCheck();
      return health.status === "healthy";
    } catch (error) {
      return false;
    }
  }
}

// Create singleton instance
const coreServiceClient = new CoreServiceClient();

module.exports = coreServiceClient;
