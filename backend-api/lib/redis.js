const redis = require('redis');
const InMemoryRedis = require('./in-memory-redis');

let client = null;

const connectRedis = async () => {
  try {
    if (!client) {
      const redisHost = process.env.REDIS_HOST || 'localhost';
      const redisPort = process.env.REDIS_PORT || 6379;
      const redisPassword = process.env.REDIS_PASSWORD;
      
      // Try to connect to real Redis first with a short timeout
      try {
        client = redis.createClient({
          socket: {
            host: redisHost,
            port: redisPort,
            connectTimeout: 3000, // 3 second timeout
            lazyConnect: true,
          },
          password: redisPassword,
        });

        // Try to connect with timeout
        await Promise.race([
          client.connect(),
          new Promise((_, reject) => 
            setTimeout(() => reject(new Error('Redis connection timeout')), 5000)
          )
        ]);

        client.on('error', (err) => {
          console.error('Redis Client Error:', err.message);
        });

        client.on('connect', () => {
          console.log('✅ Connected to Redis');
        });

        client.on('ready', () => {
          console.log('✅ Redis client ready');
        });

        console.log('✅ Successfully connected to Redis server');

      } catch (error) {
        console.log('⚠️  Redis not available, using in-memory store for development');
        console.log('   This is perfect for local development without Redis installed');
        
        // Fallback to in-memory store
        client = new InMemoryRedis();
        await client.connect();
      }
    }
    
    return client;
  } catch (error) {
    console.error('❌ Failed to initialize Redis client:', error.message);
    // Final fallback
    client = new InMemoryRedis();
    await client.connect();
    return client;
  }
};

const getRedisClient = () => {
  if (!client) {
    throw new Error('Redis client not initialized. Call connectRedis() first.');
  }
  return client;
};

const closeRedis = async () => {
  if (client) {
    await client.quit();
    client = null;
    console.log('✅ Redis connection closed');
  }
};

module.exports = {
  connectRedis,
  getRedisClient,
  closeRedis
};
