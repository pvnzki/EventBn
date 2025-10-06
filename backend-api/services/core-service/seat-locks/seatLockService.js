const { getRedisClient } = require('../lib/redis');

class SeatLockService {
  constructor() {
    this.LOCK_DURATION = 1 * 60; // 1 minute in seconds (for testing)
    this.PAYMENT_LOCK_DURATION = 10 * 60; // 10 minutes for payment process
  }

  /**
   * Generate Redis key for seat lock
   * @param {string} eventId 
   * @param {string} seatId 
   * @returns {string}
   */
  getLockKey(eventId, seatId) {
    return `seat_lock:${eventId}:${seatId}`;
  }

  /**
   * Lock a seat for a specific user
   * @param {string} eventId 
   * @param {string} seatId 
   * @param {string} userId 
   * @returns {Promise<boolean>} true if locked successfully, false if already locked
   */
  async lockSeat(eventId, seatId, userId) {
    const normalizedUserId = String(userId); // Normalize to string early for consistent use
    
    try {
      // Enhanced input validation
      if (!eventId || !seatId || !userId) {
        const missingFields = [];
        if (!eventId) missingFields.push('eventId');
        if (!seatId) missingFields.push('seatId');
        if (!userId) missingFields.push('userId');
        
        const error = new Error(`Missing required fields: ${missingFields.join(', ')}`);
        error.code = 'INVALID_PARAMETERS';
        console.error(`🚨 Validation failed for lockSeat:`, {
          eventId,
          seatId,
          userId: normalizedUserId,
          missingFields
        });
        throw error;
      }

      const redis = getRedisClient();
      const lockKey = this.getLockKey(eventId, seatId);
      const lockValue = `${normalizedUserId}:${Date.now()}`;

      console.log(`🔄 Attempting to lock seat: ${eventId}:${seatId} for user ${normalizedUserId} (normalized)`);
      
      // Use SET with NX (only if not exists) and EX (expiration) - ATOMIC operation
      const result = await redis.set(lockKey, lockValue, {
        NX: true, // Only set if key doesn't exist
        EX: this.LOCK_DURATION // Set expiration in seconds
      });
      
      if (result === 'OK') {
        console.log(`✅ Seat locked successfully: ${eventId}:${seatId} for user ${normalizedUserId}`);
        return true;
      } else {
        console.log(`❌ Seat lock failed (already locked): ${eventId}:${seatId} for user ${normalizedUserId}`);
        return false;
      }
    } catch (error) {
      console.error(`🚨 Error locking seat ${eventId}:${seatId}:`, {
        error: error.message,
        stack: error.stack,
        eventId,
        seatId,
        userId: normalizedUserId,
        code: error.code
      });
      throw error;
    }
  }

  /**
   * Check if a seat is locked
   * @param {string} eventId 
   * @param {string} seatId 
   * @returns {Promise<{locked: boolean, userId?: string, timestamp?: number}>}
   */
  async isSeatLocked(eventId, seatId) {
    try {
      const redis = getRedisClient();
      const lockKey = this.getLockKey(eventId, seatId);
      
      console.log(`🔍 Checking lock status for: ${lockKey}`);
      
      const lockValue = await redis.get(lockKey);
      
      if (!lockValue) {
        console.log(`🟢 Seat is available: ${eventId}:${seatId}`);
        return { locked: false };
      }

      const [userId, timestamp] = lockValue.split(':');
      const ttl = await redis.ttl(lockKey);
      
      console.log(`🔒 Seat locked by user ${userId}, TTL: ${ttl}s`);
      
      return {
        locked: true,
        userId,
        timestamp: parseInt(timestamp),
        ttl
      };
    } catch (error) {
      console.error(`🚨 Error checking seat lock ${eventId}:${seatId}:`, error);
      throw error;
    }
  }

  /**
   * Extend lock duration (for payment process)
   * @param {string} eventId 
   * @param {string} seatId 
   * @param {string} userId 
   * @returns {Promise<boolean>}
   */
  async extendLock(eventId, seatId, userId) {
    const normalizedUserId = String(userId);
    
    try {
      const redis = getRedisClient();
      const lockKey = this.getLockKey(eventId, seatId);
      
      console.log(`⏰ Attempting to extend lock: ${eventId}:${seatId} for user ${normalizedUserId}`);
      
      // Get current lock value to verify ownership atomically
      const currentLockValue = await redis.get(lockKey);
      
      if (!currentLockValue) {
        console.log(`❌ Lock extension failed: No active lock for ${eventId}:${seatId}`);
        return false;
      }
      
      const [currentUserId] = currentLockValue.split(':');
      
      if (String(currentUserId) !== normalizedUserId) {
        console.log(`❌ Lock extension failed: ${eventId}:${seatId} owned by ${String(currentUserId)}, requested by ${normalizedUserId}`);
        return false;
      }

      // Atomic lock extension with conditional update
      // Use SET with XX (only if exists) to ensure atomicity
      const newLockValue = `${normalizedUserId}:${Date.now()}`;
      const result = await redis.set(lockKey, newLockValue, {
        XX: true, // Only set if key exists
        EX: this.PAYMENT_LOCK_DURATION // Set expiration in seconds
      });
      
      if (result === 'OK') {
        console.log(`✅ Lock extended successfully: ${eventId}:${seatId} for user ${normalizedUserId}`);
        return true;
      } else {
        console.log(`❌ Lock extension failed (key disappeared): ${eventId}:${seatId} for user ${normalizedUserId}`);
        return false;
      }
    } catch (error) {
      console.error('🚨 Error extending seat lock:', {
        error: error.message,
        stack: error.stack,
        eventId,
        seatId,
        userId: normalizedUserId
      });
      throw error;
    }
  }

  /**
   * Release a seat lock
   * @param {string} eventId 
   * @param {string} seatId 
   * @param {string} userId 
   * @returns {Promise<boolean>}
   */
  async releaseLock(eventId, seatId, userId = null) {
    const normalizedUserId = userId ? String(userId) : null;
    
    try {
      const redis = getRedisClient();
      const lockKey = this.getLockKey(eventId, seatId);
      
      console.log(`🔓 Attempting to release lock: ${eventId}:${seatId} for user ${normalizedUserId}`);
      
      // If userId is provided, verify ownership before releasing
      if (normalizedUserId) {
        const currentLock = await this.isSeatLocked(eventId, seatId);
        console.log(`🔍 Release ownership check: stored userId="${currentLock.userId}" (${typeof currentLock.userId}), requesting userId="${normalizedUserId}" (${typeof normalizedUserId})`);
        
        if (currentLock.locked && String(currentLock.userId) !== normalizedUserId) {
          console.log(`❌ Cannot release lock: ${eventId}:${seatId} - user ${normalizedUserId} doesn't own the lock (owned by ${String(currentLock.userId)})`);
          return false;
        }
      }

      const result = await redis.del(lockKey);
      
      if (result > 0) {
        console.log(`🔓 Seat unlocked: ${eventId}:${seatId}${normalizedUserId ? ` by user ${normalizedUserId}` : ''}`);
        return true;
      }
      
      return false;
    } catch (error) {
      console.error('🚨 Error releasing seat lock:', {
        error: error.message,
        stack: error.stack,
        eventId,
        seatId,
        userId: normalizedUserId
      });
      throw error;
    }
  }

  /**
   * Get all locked seats for an event
   * @param {string} eventId 
   * @returns {Promise<Array>}
   */
  async getEventLockedSeats(eventId) {
    try {
      const redis = getRedisClient();
      const pattern = `seat_lock:${eventId}:*`;
      
      const keys = await redis.keys(pattern);
      const lockedSeats = [];

      for (const key of keys) {
        const seatId = key.split(':')[2];
        const lockInfo = await this.isSeatLocked(eventId, seatId);
        
        if (lockInfo.locked) {
          lockedSeats.push({
            seatId,
            userId: lockInfo.userId,
            timestamp: lockInfo.timestamp,
            ttl: lockInfo.ttl
          });
        }
      }

      return lockedSeats;
    } catch (error) {
      console.error('Error getting event locked seats:', error);
      throw error;
    }
  }

  /**
   * Clean up expired locks (optional - Redis handles this automatically)
   * @param {string} eventId 
   */
  async cleanupExpiredLocks(eventId) {
    try {
      const redis = getRedisClient();
      const pattern = `seat_lock:${eventId}:*`;
      
      const keys = await redis.keys(pattern);
      let cleanedCount = 0;

      for (const key of keys) {
        const ttl = await redis.ttl(key);
        if (ttl === -2) { // Key doesn't exist
          cleanedCount++;
        }
      }

      console.log(`🧹 Cleaned up ${cleanedCount} expired locks for event ${eventId}`);
      return cleanedCount;
    } catch (error) {
      console.error('Error cleaning up expired locks:', error);
      throw error;
    }
  }
}

module.exports = new SeatLockService();
