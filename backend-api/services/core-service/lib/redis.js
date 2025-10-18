const Redis = require("ioredis");

let redisClient = null;

class RedisClient {
  constructor() {
    this.client = null;
    this.isConnected = false;
  }

  async connect() {
    try {
      const redisUrl = process.env.REDIS_URL || "redis://localhost:6379";
      const authToken = process.env.REDIS_AUTH_TOKEN;

      console.log(`🔗 Attempting to connect to Redis: ${redisUrl}`);
      if (authToken) {
        console.log("🔑 Using Redis AUTH token");
      }

      // Configuration optimized for AWS ElastiCache
      const redisConfig = {
        retryDelayOnFailover: 100,
        enableReadyCheck: true,
        maxRetriesPerRequest: 3,
        lazyConnect: false, // Changed to false for immediate connection
        connectTimeout: 10000, // 10 second timeout
        commandTimeout: 5000, // 5 second command timeout
        retryDelayOnClusterDown: 300,
        retryDelayOnFailover: 100,
        maxRetriesPerRequest: 3,
        enableOfflineQueue: false, // Disable offline queue for faster failure detection
        // Add keepAlive for AWS ElastiCache
        keepAlive: 30000,
        family: 4, // Force IPv4
        // Add auth token if provided
        ...(authToken && { password: authToken }),
      };

      this.client = new Redis(redisUrl, redisConfig);

      this.client.on("connect", () => {
        console.log("✅ Redis client connected successfully");
        this.isConnected = true;
      });

      this.client.on("ready", () => {
        console.log("✅ Redis client ready for commands");
        this.isConnected = true;
      });

      this.client.on("error", (err) => {
        console.error("❌ Redis client error:", err.message);
        console.error("❌ Redis error details:", err);
        this.isConnected = false;
      });

      this.client.on("close", () => {
        console.log("⚠️ Redis client connection closed");
        this.isConnected = false;
      });

      this.client.on("reconnecting", () => {
        console.log("🔄 Redis client reconnecting...");
      });

      // Test the connection with ping
      await this.client.ping();
      console.log("✅ Redis connection verified with ping");
      return this.client;
    } catch (error) {
      console.error("❌ Failed to connect to Redis:", error.message);
      console.error("❌ Full error:", error);

      // Log specific error types for AWS ElastiCache debugging
      if (error.code === "ENOTFOUND") {
        console.error("❌ DNS resolution failed - check ElastiCache endpoint");
      } else if (error.code === "ECONNREFUSED") {
        console.error(
          "❌ Connection refused - check security groups and network access"
        );
      } else if (error.code === "ETIMEDOUT") {
        console.error(
          "❌ Connection timeout - check security groups and ElastiCache availability"
        );
      }

      throw error;
    }
  }

  async disconnect() {
    if (this.client) {
      await this.client.quit();
      this.client = null;
      this.isConnected = false;
    }
  }

  getClient() {
    if (!this.client) {
      console.error("❌ Redis client not initialized");
      throw new Error("Redis client is not initialized");
    }
    if (!this.isConnected) {
      console.error(
        "❌ Redis client not connected, status:",
        this.client.status
      );
      throw new Error(
        `Redis client is not connected (status: ${this.client.status})`
      );
    }
    return this.client;
  }

  async setex(key, seconds, value) {
    const client = this.getClient();
    return await client.setex(key, seconds, value);
  }

  async get(key) {
    const client = this.getClient();
    return await client.get(key);
  }

  async del(key) {
    const client = this.getClient();
    return await client.del(key);
  }

  async exists(key) {
    const client = this.getClient();
    return await client.exists(key);
  }

  async expire(key, seconds) {
    const client = this.getClient();
    return await client.expire(key, seconds);
  }

  async ttl(key) {
    const client = this.getClient();
    return await client.ttl(key);
  }

  async ping() {
    const client = this.getClient();
    return await client.ping();
  }

  async set(key, value, options) {
    const client = this.getClient();
    return await client.set(key, value, options);
  }
}

async function connectRedis() {
  if (!redisClient) {
    redisClient = new RedisClient();
    await redisClient.connect();
  }
  return redisClient;
}

async function getRedisClient() {
  if (!redisClient) {
    await connectRedis();
  }
  return redisClient.getClient();
}

module.exports = {
  connectRedis,
  getRedisClient,
  RedisClient,
};
