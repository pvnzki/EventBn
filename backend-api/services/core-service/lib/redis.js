// Simple Redis client for core-service
// For now, we'll use a basic implementation that connects to the Redis container

class RedisClient {
  constructor() {
    this.isConnected = false;
    this.store = new Map(); // In-memory storage
    this.expirations = new Map(); // Track expiration times
  }

  async connect() {
    try {
      // For now, we'll simulate connection
      this.isConnected = true;
      console.log("✅ Redis client connected (simulated)");

      // Start cleanup timer for expired keys
      this.startCleanupTimer();
    } catch (error) {
      console.log(
        "❌ Redis connection failed (using fallback):",
        error.message
      );
      this.isConnected = false;
    }
  }

  startCleanupTimer() {
    // Clean up expired keys every 5 seconds
    setInterval(() => {
      const now = Date.now();
      for (const [key, expireTime] of this.expirations.entries()) {
        if (now >= expireTime) {
          this.store.delete(key);
          this.expirations.delete(key);
          console.log(`🧹 Cleaned up expired key: ${key}`);
        }
      }
    }, 5000);
  }

  async get(key) {
    if (!this.isConnected) {
      return null;
    }

    // Check if key has expired
    const expireTime = this.expirations.get(key);
    if (expireTime && Date.now() >= expireTime) {
      this.store.delete(key);
      this.expirations.delete(key);
      return null;
    }

    return this.store.get(key) || null;
  }

  async set(key, value, options = {}) {
    if (!this.isConnected) {
      return false;
    }

    // Handle NX option (only set if key doesn't exist)
    if (options.NX) {
      const existing = await this.get(key);
      if (existing !== null) {
        return null; // Key exists, operation failed
      }
    }

    // Set the value
    this.store.set(key, value);

    // Handle EX option (expiration in seconds)
    if (options.EX) {
      const expireTime = Date.now() + options.EX * 1000;
      this.expirations.set(key, expireTime);
    }

    return "OK";
  }

  async del(key) {
    if (!this.isConnected) {
      return 0;
    }

    const existed = this.store.has(key);
    this.store.delete(key);
    this.expirations.delete(key);
    return existed ? 1 : 0;
  }

  async exists(key) {
    if (!this.isConnected) {
      return 0;
    }

    // Check if key exists and hasn't expired
    const value = await this.get(key);
    return value !== null ? 1 : 0;
  }

  async ttl(key) {
    if (!this.isConnected) {
      return -2;
    }

    const expireTime = this.expirations.get(key);
    if (!expireTime) {
      // Key doesn't exist or has no expiration
      const exists = this.store.has(key);
      return exists ? -1 : -2; // -1 = no expiration, -2 = doesn't exist
    }

    const now = Date.now();
    if (now >= expireTime) {
      // Key has expired
      this.store.delete(key);
      this.expirations.delete(key);
      return -2;
    }

    return Math.ceil((expireTime - now) / 1000); // Return TTL in seconds
  }
}

const redisClient = new RedisClient();

// Auto-connect
redisClient.connect().catch(console.error);

function getRedisClient() {
  return redisClient;
}

module.exports = { getRedisClient };
