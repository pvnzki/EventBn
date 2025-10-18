const Redis = require("ioredis");

let redisClient = null;

class RedisClient {
  constructor() {
    this.client = null;
    this.isConnected = false;
    this.connectionAttempts = 0;
    this.maxRetries = 5;
    this.retryBackoffBase = 1000; // Base delay in ms
    this.circuitBreakerTimeout = 60000; // 60 seconds before trying again
    this.lastConnectionAttempt = 0;
    this.isCircuitBreakerOpen = false;
  }

  async connect() {
    // Check circuit breaker - don't attempt if we're in cooldown
    if (this.isCircuitBreakerOpen) {
      const timeSinceLastAttempt = Date.now() - this.lastConnectionAttempt;
      if (timeSinceLastAttempt < this.circuitBreakerTimeout) {
        throw new Error(`Redis circuit breaker is open. Next attempt in ${Math.ceil((this.circuitBreakerTimeout - timeSinceLastAttempt) / 1000)} seconds`);
      } else {
        // Reset circuit breaker after timeout
        this.isCircuitBreakerOpen = false;
        this.connectionAttempts = 0;
        console.log("🔄 Redis circuit breaker reset, attempting reconnection");
      }
    }

    // Check if we've exceeded max retries
    if (this.connectionAttempts >= this.maxRetries) {
      this.isCircuitBreakerOpen = true;
      this.lastConnectionAttempt = Date.now();
      throw new Error(`Redis connection failed after ${this.maxRetries} attempts. Circuit breaker activated.`);
    }

    try {
      this.connectionAttempts++;
      this.lastConnectionAttempt = Date.now();

      const redisUrl = process.env.REDIS_URL || "redis://localhost:6379";
      const authToken = process.env.REDIS_AUTH_TOKEN;

      console.log(`🔗 Redis connection attempt ${this.connectionAttempts}/${this.maxRetries}: ${redisUrl}`);
      if (authToken) {
        console.log("🔑 Using Redis AUTH token");
      }

      // Configuration optimized for AWS ElastiCache with controlled reconnection
      const redisConfig = {
        retryDelayOnFailover: 100,
        enableReadyCheck: true,
        maxRetriesPerRequest: 2, // Reduced from 3
        lazyConnect: false,
        connectTimeout: 10000,
        commandTimeout: 5000,
        retryDelayOnClusterDown: 300,
        enableOfflineQueue: false,
        keepAlive: 30000,
        family: 4,
        // Limit automatic reconnection attempts
        maxRetriesPerRequest: 2,
        retryDelayOnFailover: this.retryBackoffBase * Math.pow(2, this.connectionAttempts - 1), // Exponential backoff
        ...(authToken && { password: authToken }),
      };

      this.client = new Redis(redisUrl, redisConfig);

      this.client.on("connect", () => {
        console.log("✅ Redis client connected successfully");
        this.isConnected = true;
        // Reset connection attempts on successful connection
        this.connectionAttempts = 0;
        this.isCircuitBreakerOpen = false;
      });

      this.client.on("ready", () => {
        console.log("✅ Redis client ready for commands");
        this.isConnected = true;
        // Reset connection attempts on ready state
        this.connectionAttempts = 0;
        this.isCircuitBreakerOpen = false;
      });

      this.client.on("error", (err) => {
        console.error(`❌ Redis client error (attempt ${this.connectionAttempts}/${this.maxRetries}):`, err.message);
        this.isConnected = false;
        
        // Don't log full error details repeatedly to reduce noise
        if (this.connectionAttempts === 1) {
          console.error("❌ Redis error details:", err);
        }
      });

      this.client.on("close", () => {
        console.log("⚠️ Redis client connection closed");
        this.isConnected = false;
      });

      this.client.on("reconnecting", (time) => {
        console.log(`🔄 Redis client reconnecting in ${time}ms (attempt ${this.connectionAttempts}/${this.maxRetries})`);
        
        // Stop automatic reconnection if we've hit the limit
        if (this.connectionAttempts >= this.maxRetries) {
          console.log("🛑 Max Redis reconnection attempts reached, stopping automatic reconnection");
          this.client.disconnect(false); // Disconnect without triggering reconnect
          this.isCircuitBreakerOpen = true;
        }
      });

      // Test the connection with ping
      await this.client.ping();
      console.log("✅ Redis connection verified with ping");
      
      // Reset attempts on successful connection
      this.connectionAttempts = 0;
      this.isCircuitBreakerOpen = false;
      
      return this.client;
    } catch (error) {
      console.error(`❌ Redis connection attempt ${this.connectionAttempts}/${this.maxRetries} failed:`, error.message);
      
      // Only log full error details on first attempt to reduce noise
      if (this.connectionAttempts === 1) {
        console.error("❌ Full error:", error);
        
        // Log specific error types for AWS ElastiCache debugging
        if (error.code === "ENOTFOUND") {
          console.error("❌ DNS resolution failed - check ElastiCache endpoint");
        } else if (error.code === "ECONNREFUSED") {
          console.error("❌ Connection refused - check security groups and network access");
        } else if (error.code === "ETIMEDOUT") {
          console.error("❌ Connection timeout - check security groups and ElastiCache availability");
        }
      }

      // Clean up client on failure
      if (this.client) {
        this.client.disconnect(false);
        this.client = null;
      }
      this.isConnected = false;

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

  /**
   * Reset circuit breaker and allow new connection attempts
   */
  resetCircuitBreaker() {
    this.isCircuitBreakerOpen = false;
    this.connectionAttempts = 0;
    console.log("🔧 Redis circuit breaker manually reset");
  }

  /**
   * Get connection status and circuit breaker state
   */
  getConnectionStatus() {
    return {
      isConnected: this.isConnected,
      connectionAttempts: this.connectionAttempts,
      maxRetries: this.maxRetries,
      isCircuitBreakerOpen: this.isCircuitBreakerOpen,
      lastConnectionAttempt: this.lastConnectionAttempt,
      clientStatus: this.client ? this.client.status : 'no-client'
    };
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
  }
  
  // Only attempt connection if not connected and circuit breaker allows it
  if (!redisClient.isConnected) {
    try {
      await redisClient.connect();
    } catch (error) {
      // Don't throw error immediately, let the application continue with fallback
      console.warn("⚠️ Redis connection failed, application will use fallback methods:", error.message);
    }
  }
  
  return redisClient;
}

async function getRedisClient() {
  if (!redisClient) {
    await connectRedis();
  }
  
  // Check if circuit breaker is open
  if (redisClient.isCircuitBreakerOpen) {
    throw new Error("Redis is temporarily unavailable due to repeated connection failures");
  }
  
  return redisClient.getClient();
}

module.exports = {
  connectRedis,
  getRedisClient,
  RedisClient,
  // Export utility functions for monitoring and management
  getRedisStatus: () => redisClient ? redisClient.getConnectionStatus() : { status: 'not-initialized' },
  resetRedisCircuitBreaker: () => redisClient ? redisClient.resetCircuitBreaker() : null,
};
