const { getRedisClient } = require('../lib/redis');
const { v4: uuidv4 } = require('uuid');
const EventEmitter = require('events');

class QueueService extends EventEmitter {
  constructor() {
    super();
    this.QUEUE_KEY_PREFIX = 'seat_lock_queue';
    this.RESULT_KEY_PREFIX = 'queue_result';
    this.RESULT_TTL = 60; // Results expire after 60 seconds
    this.PROCESSING_TIMEOUT = 30000; // 30 seconds timeout for processing
    
    // Track active workers
    this.isWorkerRunning = false;
    this.workerPromise = null;
  }

  /**
   * Generate queue key for an event
   * @param {string} eventId 
   * @returns {string}
   */
  getQueueKey(eventId) {
    return `${this.QUEUE_KEY_PREFIX}:${eventId}`;
  }

  /**
   * Generate result key for a request
   * @param {string} requestId 
   * @returns {string}
   */
  getResultKey(requestId) {
    return `${this.RESULT_KEY_PREFIX}:${requestId}`;
  }

  /**
   * Add a seat lock request to the queue
   * @param {Object} request - { eventId, seatId, userId, action, timestamp }
   * @returns {Promise<string>} requestId for tracking
   */
  async enqueueRequest(request) {
    try {
      const redis = getRedisClient();
      const requestId = uuidv4();
      const queueKey = this.getQueueKey(request.eventId);
      
      const queueItem = {
        requestId,
        ...request,
        timestamp: Date.now(),
        status: 'queued'
      };

      // Add to queue (LPUSH for FIFO when using BRPOP)
      await redis.lPush(queueKey, JSON.stringify(queueItem));
      
      console.log(`📝 Queued request: ${request.action} seat ${request.seatId} for user ${request.userId} (ID: ${requestId})`);
      
      // Start worker if not running
      this.startWorker(request.eventId);
      
      return requestId;
    } catch (error) {
      console.error('Error enqueuing request:', error);
      throw error;
    }
  }

  /**
   * Get the result of a processed request
   * @param {string} requestId 
   * @returns {Promise<Object|null>}
   */
  async getRequestResult(requestId) {
    try {
      const redis = getRedisClient();
      const resultKey = this.getResultKey(requestId);
      
      const result = await redis.get(resultKey);
      return result ? JSON.parse(result) : null;
    } catch (error) {
      console.error('Error getting request result:', error);
      throw error;
    }
  }

  /**
   * Store the result of a processed request
   * @param {string} requestId 
   * @param {Object} result 
   * @returns {Promise<void>}
   */
  async storeRequestResult(requestId, result) {
    try {
      const redis = getRedisClient();
      const resultKey = this.getResultKey(requestId);
      
      const resultData = {
        ...result,
        processedAt: Date.now(),
        requestId
      };

      // Store with TTL
      await redis.setEx(resultKey, this.RESULT_TTL, JSON.stringify(resultData));
    } catch (error) {
      console.error('Error storing request result:', error);
      throw error;
    }
  }

  /**
   * Get queue length for an event
   * @param {string} eventId 
   * @returns {Promise<number>}
   */
  async getQueueLength(eventId) {
    try {
      const redis = getRedisClient();
      const queueKey = this.getQueueKey(eventId);
      return await redis.lLen(queueKey);
    } catch (error) {
      console.error('Error getting queue length:', error);
      return 0;
    }
  }

  /**
   * Start the queue worker for processing requests
   * @param {string} eventId 
   */
  startWorker(eventId) {
    if (this.isWorkerRunning) {
      return this.workerPromise;
    }

    this.isWorkerRunning = true;
    this.workerPromise = this.processQueue(eventId);
    
    return this.workerPromise;
  }

  /**
   * Stop the queue worker
   */
  async stopWorker() {
    this.isWorkerRunning = false;
    if (this.workerPromise) {
      await this.workerPromise;
      this.workerPromise = null;
    }
  }

  /**
   * Process queued requests
   * @param {string} eventId 
   */
  async processQueue(eventId) {
    const redis = getRedisClient();
    const queueKey = this.getQueueKey(eventId);

    console.log(`🚀 Starting queue worker for event: ${eventId}`);

    while (this.isWorkerRunning) {
      try {
        // Block until a request is available (5 second timeout)
        const result = await redis.brPop(queueKey, 5);
        
        if (!result) {
          // Check if queue is empty, if so, stop worker
          const queueLength = await this.getQueueLength(eventId);
          if (queueLength === 0) {
            console.log(`⏹️  Queue empty, stopping worker for event: ${eventId}`);
            break;
          }
          continue;
        }

        // Redis v4+ returns {key: queueName, element: value}
        const queueItemJson = result.element;
        const queueItem = JSON.parse(queueItemJson);

        console.log(`⚡ Processing request: ${queueItem.requestId} - ${queueItem.action} seat ${queueItem.seatId}`);

        // Process the request
        await this.processRequest(queueItem);

      } catch (error) {
        console.error('Error in queue processing:', error);
        // Continue processing even if one request fails
      }
    }

    this.isWorkerRunning = false;
    console.log(`✅ Queue worker stopped for event: ${eventId}`);
  }

  /**
   * Process a single request
   * @param {Object} queueItem 
   */
  async processRequest(queueItem) {
    const { requestId, eventId, seatId, userId, action } = queueItem;
    const seatLockService = require('./seatLockService');
    
    try {
      let result;
      
      switch (action) {
        case 'lock':
          const locked = await seatLockService.lockSeat(eventId, seatId, userId);
          result = {
            success: locked,
            message: locked ? 'Seat locked successfully' : 'Seat already locked by another user',
            action: 'lock',
            eventId,
            seatId,
            userId
          };
          break;

        case 'extend':
          const extended = await seatLockService.extendLock(eventId, seatId, userId);
          result = {
            success: extended,
            message: extended ? 'Lock extended successfully' : 'Cannot extend lock',
            action: 'extend',
            eventId,
            seatId,
            userId
          };
          break;

        case 'release':
          const released = await seatLockService.releaseLock(eventId, seatId, userId);
          result = {
            success: released,
            message: released ? 'Lock released successfully' : 'Cannot release lock',
            action: 'release',
            eventId,
            seatId,
            userId
          };
          break;

        default:
          result = {
            success: false,
            message: `Unknown action: ${action}`,
            action,
            eventId,
            seatId,
            userId
          };
      }

      // Store result for client to retrieve
      await this.storeRequestResult(requestId, result);
      
      console.log(`✅ Processed: ${requestId} - ${action} ${result.success ? 'SUCCESS' : 'FAILED'}`);
      
      // Emit event for real-time updates (if WebSockets implemented)
      this.emit('requestProcessed', { requestId, result });

    } catch (error) {
      console.error(`❌ Error processing request ${requestId}:`, error);
      
      const errorResult = {
        success: false,
        message: 'Internal server error during processing',
        error: error.message,
        action,
        eventId,
        seatId,
        userId
      };

      await this.storeRequestResult(requestId, errorResult);
    }
  }

  /**
   * Get queue statistics
   * @param {string} eventId 
   * @returns {Promise<Object>}
   */
  async getQueueStats(eventId) {
    try {
      const queueLength = await this.getQueueLength(eventId);
      
      return {
        eventId,
        queueLength,
        isWorkerRunning: this.isWorkerRunning,
        estimatedWaitTime: queueLength * 2, // Rough estimate: 2 seconds per request
        status: queueLength > 0 ? 'active' : 'idle'
      };
    } catch (error) {
      console.error('Error getting queue stats:', error);
      return {
        eventId,
        queueLength: 0,
        isWorkerRunning: false,
        estimatedWaitTime: 0,
        status: 'error',
        error: error.message
      };
    }
  }

  /**
   * Clear all requests from a queue (use with caution)
   * @param {string} eventId 
   * @returns {Promise<number>} number of requests cleared
   */
  async clearQueue(eventId) {
    try {
      const redis = getRedisClient();
      const queueKey = this.getQueueKey(eventId);
      
      const cleared = await redis.del(queueKey);
      console.log(`🗑️  Cleared ${cleared} requests from queue: ${eventId}`);
      
      return cleared;
    } catch (error) {
      console.error('Error clearing queue:', error);
      throw error;
    }
  }
}

module.exports = new QueueService();
