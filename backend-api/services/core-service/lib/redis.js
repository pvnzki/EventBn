const Redis = require('ioredis');

let redisClient = null;

class RedisClient {
  constructor() {
    this.client = null;
    this.isConnected = false;
  }

  async connect() {
    try {
      const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';
      
      this.client = new Redis(redisUrl, {
        retryDelayOnFailover: 100,
        enableReadyCheck: true,
        maxRetriesPerRequest: 3,
        lazyConnect: true
      });

      this.client.on('connect', () => {
        console.log('Redis client connected');
        this.isConnected = true;
      });

      this.client.on('error', (err) => {
        console.error('Redis client error:', err);
        this.isConnected = false;
      });

      this.client.on('close', () => {
        console.log('Redis client connection closed');
        this.isConnected = false;
      });

      await this.client.connect();
      return this.client;
    } catch (error) {
      console.error('Failed to connect to Redis:', error);
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
    if (!this.client || !this.isConnected) {
      throw new Error('Redis client is not connected');
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
  RedisClient
};
