const seatLockService = require('../services/seatLockService');
const queueService = require('../services/queueService');
const { getRedisClient } = require('../lib/redis');

class HybridSeatLockService {
  constructor() {
    this.QUEUE_THRESHOLD = 10; // Switch to queue when more than 10 requests per minute
    this.LOAD_TRACKING_KEY = 'seat_lock_load';
    this.LOAD_WINDOW = 60; // 1 minute window for load tracking
  }

  /**
   * Track request load for an event
   * @param {string} eventId 
   */
  async trackLoad(eventId) {
    try {
      const redis = getRedisClient();
      const loadKey = `${this.LOAD_TRACKING_KEY}:${eventId}`;
      
      // Increment counter with TTL
      const current = await redis.incr(loadKey);
      if (current === 1) {
        await redis.expire(loadKey, this.LOAD_WINDOW);
      }
      
      return current;
    } catch (error) {
      console.error('Error tracking load:', error);
      return 0;
    }
  }

  /**
   * Check if we should use queue based on current load
   * @param {string} eventId 
   * @returns {Promise<boolean>}
   */
  async shouldUseQueue(eventId) {
    try {
      const currentLoad = await this.trackLoad(eventId);
      const queueLength = await queueService.getQueueLength(eventId);
      
      // Use queue if:
      // 1. Current load exceeds threshold
      // 2. There are already items in the queue (to maintain order)
      return currentLoad > this.QUEUE_THRESHOLD || queueLength > 0;
    } catch (error) {
      console.error('Error checking queue usage:', error);
      return false; // Default to direct processing on error
    }
  }

  /**
   * Process seat lock request (hybrid approach)
   * @param {Object} request - { eventId, seatId, userId, action }
   * @returns {Promise<Object>}
   */
  async processRequest(request) {
    const { eventId, seatId, userId, action } = request;

    try {
      // Enhanced input validation
      if (!eventId || !seatId || !userId || !action) {
        const missingFields = [];
        if (!eventId) missingFields.push('eventId');
        if (!seatId) missingFields.push('seatId'); 
        if (!userId) missingFields.push('userId');
        if (!action) missingFields.push('action');
        
        console.error(`🚨 Invalid request parameters:`, {
          eventId,
          seatId,
          userId,
          action,
          missingFields
        });
        
        return {
          success: false,
          message: `Missing required fields: ${missingFields.join(', ')}`,
          error: 'INVALID_PARAMETERS'
        };
      }

      const useQueue = await this.shouldUseQueue(eventId);

      if (useQueue) {
        // High load - use queue
        console.log(`🚦 High load detected for event ${eventId}, using queue`);
        
        const requestId = await queueService.enqueueRequest({
          eventId,
          seatId,
          userId,
          action
        });

        return {
          success: true,
          queued: true,
          message: 'Request queued due to high traffic',
          requestId,
          queuePosition: await queueService.getQueueLength(eventId),
          estimatedWaitTime: Math.ceil(await queueService.getQueueLength(eventId) * 2) // 2 seconds per request
        };

      } else {
        // Normal load - process directly
        console.log(`⚡ Normal load for event ${eventId}, processing directly`);
        
        let result;
        switch (action) {
          case 'lock':
            const locked = await seatLockService.lockSeat(eventId, seatId, userId);
            result = {
              success: locked,
              queued: false,
              message: locked ? 'Seat locked successfully' : 'Seat already locked by another user',
              lockInfo: locked ? {
                eventId,
                seatId,
                userId,
                duration: '3 minutes'
              } : null
            };
            break;

          case 'extend':
            const extended = await seatLockService.extendLock(eventId, seatId, userId);
            result = {
              success: extended,
              queued: false,
              message: extended ? 'Lock extended successfully' : 'Cannot extend lock - you do not own this lock or it has expired',
              duration: extended ? '10 minutes' : null
            };
            break;

          case 'release':
            const released = await seatLockService.releaseLock(eventId, seatId, userId);
            result = {
              success: released,
              queued: false,
              message: released ? 'Lock released successfully' : 'Cannot release lock - you do not own this lock'
            };
            break;

          default:
            result = {
              success: false,
              queued: false,
              message: `Unknown action: ${action}`
            };
        }

        return result;
      }

    } catch (error) {
      console.error('Error in hybrid processing:', error);
      return {
        success: false,
        queued: false,
        message: 'Internal server error',
        error: error.message
      };
    }
  }

  /**
   * Get current load and queue statistics
   * @param {string} eventId 
   * @returns {Promise<Object>}
   */
  async getLoadStats(eventId) {
    try {
      const redis = getRedisClient();
      const loadKey = `${this.LOAD_TRACKING_KEY}:${eventId}`;
      
      const currentLoad = await redis.get(loadKey) || 0;
      const queueStats = await queueService.getQueueStats(eventId);
      
      return {
        eventId,
        currentLoad: parseInt(currentLoad),
        threshold: this.QUEUE_THRESHOLD,
        useQueue: parseInt(currentLoad) > this.QUEUE_THRESHOLD || queueStats.queueLength > 0,
        queue: queueStats,
        loadWindow: this.LOAD_WINDOW,
        status: parseInt(currentLoad) > this.QUEUE_THRESHOLD ? 'high-load' : 'normal-load'
      };
    } catch (error) {
      console.error('Error getting load stats:', error);
      return {
        eventId,
        currentLoad: 0,
        threshold: this.QUEUE_THRESHOLD,
        useQueue: false,
        error: error.message
      };
    }
  }
}

module.exports = new HybridSeatLockService();
