const seatLockService = require('../../../services/core-service/seat-locks/seatLockService');
const { getRedisClient } = require('../../../lib/redis');

// Mock Redis client
jest.mock('../../../lib/redis', () => ({
  getRedisClient: jest.fn()
}));

describe('SeatLockService', () => {
  let mockRedis;

  beforeEach(() => {
    jest.clearAllMocks();
    
    // Mock Redis client methods
    mockRedis = {
      set: jest.fn(),
      get: jest.fn(),
      del: jest.fn(),
      exists: jest.fn(),
      expire: jest.fn(),
      setex: jest.fn(),
      ttl: jest.fn()
    };
    
    getRedisClient.mockReturnValue(mockRedis);
  });

  describe('constructor', () => {
    it('should initialize with correct lock durations', () => {
      expect(seatLockService.LOCK_DURATION).toBe(60); // 1 minute
      expect(seatLockService.PAYMENT_LOCK_DURATION).toBe(600); // 10 minutes
    });
  });

  describe('getLockKey', () => {
    it('should generate correct Redis key format', () => {
      const key = seatLockService.getLockKey('event123', 'A1');
      expect(key).toBe('seat_lock:event123:A1');
    });

    it('should handle different seat ID formats', () => {
      expect(seatLockService.getLockKey('1', 'A-1')).toBe('seat_lock:1:A-1');
      expect(seatLockService.getLockKey('2', '12')).toBe('seat_lock:2:12');
    });
  });

  describe('lockSeat', () => {
    const eventId = 'event123';
    const seatId = 'A1';
    const userId = '456';

    it('should successfully lock an available seat', async () => {
      mockRedis.set.mockResolvedValueOnce('OK');

      const result = await seatLockService.lockSeat(eventId, seatId, userId);

      expect(mockRedis.set).toHaveBeenCalledWith(
        'seat_lock:event123:A1',
        expect.stringMatching(/^456:\d+$/),
        {
          NX: true,
          EX: 60
        }
      );
      expect(result).toBe(true);
    });

    it('should fail to lock already locked seat', async () => {
      mockRedis.set.mockResolvedValueOnce(null); // Redis returns null when key exists

      const result = await seatLockService.lockSeat(eventId, seatId, userId);

      expect(result).toBe(false);
    });

    it('should validate required parameters', async () => {
      await expect(seatLockService.lockSeat('', seatId, userId))
        .rejects
        .toThrow('Missing required fields: eventId');

      await expect(seatLockService.lockSeat(eventId, '', userId))
        .rejects
        .toThrow('Missing required fields: seatId');

      await expect(seatLockService.lockSeat(eventId, seatId, ''))
        .rejects
        .toThrow('Missing required fields: userId');

      await expect(seatLockService.lockSeat('', '', ''))
        .rejects
        .toThrow('Missing required fields: eventId, seatId, userId');
    });

    it('should normalize userId to string', async () => {
      mockRedis.set.mockResolvedValueOnce('OK');

      await seatLockService.lockSeat(eventId, seatId, 123); // Number

      expect(mockRedis.set).toHaveBeenCalledWith(
        'seat_lock:event123:A1',
        expect.stringMatching(/^123:\d+$/),
        {
          NX: true,
          EX: 60
        }
      );
    });

    it('should handle Redis errors gracefully', async () => {
      mockRedis.set.mockRejectedValueOnce(new Error('Redis connection failed'));

      await expect(seatLockService.lockSeat(eventId, seatId, userId))
        .rejects
        .toThrow('Redis connection failed');
    });

    it('should include timestamp in lock value', async () => {
      const mockTimestamp = 1234567890;
      jest.spyOn(Date, 'now').mockReturnValue(mockTimestamp);
      mockRedis.set.mockResolvedValueOnce('OK');

      await seatLockService.lockSeat(eventId, seatId, userId);

      expect(mockRedis.set).toHaveBeenCalledWith(
        'seat_lock:event123:A1',
        '456:1234567890',
        {
          NX: true,
          EX: 60
        }
      );

      Date.now.mockRestore();
    });
  });

  describe('unlockSeat', () => {
    const eventId = 'event123';
    const seatId = 'A1';
    const userId = '456';

    it('should successfully unlock seat owned by user', async () => {
      mockRedis.get.mockResolvedValueOnce(`${userId}:${Date.now()}`);
      mockRedis.del.mockResolvedValueOnce(1);

      const result = await seatLockService.unlockSeat(eventId, seatId, userId);

      expect(mockRedis.get).toHaveBeenCalledWith('seat_lock:event123:A1');
      expect(mockRedis.del).toHaveBeenCalledWith('seat_lock:event123:A1');
      expect(result).toBe(true);
    });

    it('should fail to unlock seat owned by different user', async () => {
      mockRedis.get.mockResolvedValueOnce('999:1234567890'); // Different user

      const result = await seatLockService.unlockSeat(eventId, seatId, userId);

      expect(mockRedis.del).not.toHaveBeenCalled();
      expect(result).toBe(false);
    });

    it('should fail to unlock non-existent lock', async () => {
      mockRedis.get.mockResolvedValueOnce(null);

      const result = await seatLockService.unlockSeat(eventId, seatId, userId);

      expect(mockRedis.del).not.toHaveBeenCalled();
      expect(result).toBe(false);
    });

    it('should validate required parameters', async () => {
      await expect(seatLockService.unlockSeat('', seatId, userId))
        .rejects
        .toThrow('Missing required fields: eventId');
    });
  });

  describe('extendLock', () => {
    const eventId = 'event123';
    const seatId = 'A1';
    const userId = '456';

    it('should extend lock for payment process', async () => {
      mockRedis.get.mockResolvedValueOnce(`${userId}:${Date.now()}`);
      mockRedis.expire.mockResolvedValueOnce(1);

      const result = await seatLockService.extendLock(eventId, seatId, userId, 'payment');

      expect(mockRedis.expire).toHaveBeenCalledWith('seat_lock:event123:A1', 600);
      expect(result).toBe(true);
    });

    it('should extend lock for default duration', async () => {
      mockRedis.get.mockResolvedValueOnce(`${userId}:${Date.now()}`);
      mockRedis.expire.mockResolvedValueOnce(1);

      const result = await seatLockService.extendLock(eventId, seatId, userId);

      expect(mockRedis.expire).toHaveBeenCalledWith('seat_lock:event123:A1', 60);
      expect(result).toBe(true);
    });

    it('should fail to extend lock for wrong user', async () => {
      mockRedis.get.mockResolvedValueOnce('999:1234567890');

      const result = await seatLockService.extendLock(eventId, seatId, userId);

      expect(mockRedis.expire).not.toHaveBeenCalled();
      expect(result).toBe(false);
    });
  });

  describe('isLocked', () => {
    const eventId = 'event123';
    const seatId = 'A1';

    it('should return true for locked seat', async () => {
      mockRedis.exists.mockResolvedValueOnce(1);

      const result = await seatLockService.isLocked(eventId, seatId);

      expect(mockRedis.exists).toHaveBeenCalledWith('seat_lock:event123:A1');
      expect(result).toBe(true);
    });

    it('should return false for unlocked seat', async () => {
      mockRedis.exists.mockResolvedValueOnce(0);

      const result = await seatLockService.isLocked(eventId, seatId);

      expect(result).toBe(false);
    });
  });

  describe('getLockInfo', () => {
    const eventId = 'event123';
    const seatId = 'A1';
    const userId = '456';
    const timestamp = 1234567890;

    it('should return lock information', async () => {
      mockRedis.get.mockResolvedValueOnce(`${userId}:${timestamp}`);
      mockRedis.ttl.mockResolvedValueOnce(30);

      const result = await seatLockService.getLockInfo(eventId, seatId);

      expect(result).toEqual({
        isLocked: true,
        lockedBy: userId,
        lockedAt: timestamp,
        ttl: 30
      });
    });

    it('should return null for unlocked seat', async () => {
      mockRedis.get.mockResolvedValueOnce(null);

      const result = await seatLockService.getLockInfo(eventId, seatId);

      expect(result).toBeNull();
    });

    it('should handle malformed lock value', async () => {
      mockRedis.get.mockResolvedValueOnce('invalid-format');

      const result = await seatLockService.getLockInfo(eventId, seatId);

      expect(result).toEqual({
        isLocked: true,
        lockedBy: 'unknown',
        lockedAt: null,
        ttl: null
      });
    });
  });

  describe('cleanup operations', () => {
    it('should cleanup expired locks', async () => {
      // This would test any cleanup functionality
      // Implementation depends on actual service methods
    });

    it('should handle bulk operations', async () => {
      // Test bulk lock/unlock operations if they exist
    });
  });

  describe('error handling', () => {
    it('should handle Redis connection failures', async () => {
      getRedisClient.mockImplementation(() => {
        throw new Error('Redis unavailable');
      });

      await expect(seatLockService.lockSeat('event1', 'A1', '123'))
        .rejects
        .toThrow('Redis unavailable');
    });

    it('should handle invalid lock values gracefully', async () => {
      mockRedis.get.mockResolvedValueOnce('corrupted:data:extra');

      const result = await seatLockService.getLockInfo('event1', 'A1');

      expect(result.lockedBy).toBe('corrupted');
      expect(result.lockedAt).toBeNaN();
    });
  });
});