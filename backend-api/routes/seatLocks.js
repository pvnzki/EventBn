const express = require('express');
const router = express.Router();
const seatLockService = require('../services/seatLockService');
const hybridSeatLockService = require('../services/hybridSeatLockService');
const queueService = require('../services/queueService');
const { authenticateToken } = require('../middleware/auth');

// HYBRID ENDPOINTS (recommended for high-concurrency events)

// Hybrid seat lock (automatically uses queue when needed)
router.post('/events/:eventId/seats/:seatId/hybrid/lock', authenticateToken, async (req, res) => {
  try {
    const { eventId, seatId } = req.params;
    const userId = req.user.user_id; // Fixed: use user_id from middleware

    console.log(`🔄 Hybrid lock request: Event ${eventId}, Seat ${seatId}, User ${userId}`);

    const result = await hybridSeatLockService.processRequest({
      eventId,
      seatId,
      userId,
      action: 'lock'
    });

    const statusCode = result.success ? 200 : (result.queued ? 202 : 409);
    
    res.status(statusCode).json(result);

  } catch (error) {
    console.error('🚨 Error in hybrid lock endpoint:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// Hybrid seat lock extension
router.put('/events/:eventId/seats/:seatId/hybrid/extend', authenticateToken, async (req, res) => {
  try {
    const { eventId, seatId } = req.params;
    const userId = req.user.user_id; // Fixed: use user_id from middleware

    const result = await hybridSeatLockService.processRequest({
      eventId,
      seatId,
      userId,
      action: 'extend'
    });

    const statusCode = result.success ? 200 : (result.queued ? 202 : 403);
    
    res.status(statusCode).json(result);

  } catch (error) {
    console.error('Error in hybrid extend endpoint:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// Hybrid seat lock release
router.delete('/events/:eventId/seats/:seatId/hybrid/release', authenticateToken, async (req, res) => {
  try {
    const { eventId, seatId } = req.params;
    const userId = req.user.user_id; // Fixed: use user_id from middleware

    const result = await hybridSeatLockService.processRequest({
      eventId,
      seatId,
      userId,
      action: 'release'
    });

    const statusCode = result.success ? 200 : (result.queued ? 202 : 403);
    
    res.status(statusCode).json(result);

  } catch (error) {
    console.error('Error in hybrid release endpoint:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// Get load statistics and queue status
router.get('/events/:eventId/hybrid/stats', async (req, res) => {
  try {
    const { eventId } = req.params;
    
    const stats = await hybridSeatLockService.getLoadStats(eventId);
    
    res.json({
      success: true,
      eventId,
      stats
    });

  } catch (error) {
    console.error('Error getting hybrid stats:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get load statistics',
      error: error.message
    });
  }
});

// Poll for queued request result
router.get('/hybrid/requests/:requestId/result', authenticateToken, async (req, res) => {
  try {
    const { requestId } = req.params;
    const timeout = parseInt(req.query.timeout) || 30000; // Default 30 seconds
    
    const startTime = Date.now();
    const pollInterval = 1000; // Poll every 1 second

    while (Date.now() - startTime < timeout) {
      const result = await queueService.getRequestResult(requestId);
      
      if (result) {
        return res.json({
          success: true,
          requestId,
          result,
          processedAt: result.processedAt,
          waitTime: Date.now() - startTime
        });
      }

      // Wait before next poll
      await new Promise(resolve => setTimeout(resolve, pollInterval));
    }

    // Timeout reached
    res.status(408).json({
      success: false,
      message: 'Request processing timeout',
      requestId,
      timeout
    });

  } catch (error) {
    console.error('Error polling hybrid request:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to poll request result',
      error: error.message
    });
  }
});

// DIRECT ENDPOINTS (original implementation for backwards compatibility)

// Lock a seat
router.post('/events/:eventId/seats/:seatId/lock', authenticateToken, async (req, res) => {
  try {
    const { eventId, seatId } = req.params;
    const userId = req.user.user_id; // Fixed: use user_id from middleware

    // Enhanced input validation and logging
    console.log(`🔄 Direct lock request received:`, {
      eventId,
      seatId,
      userId,
      userObject: req.user,
      timestamp: new Date().toISOString()
    });

    // Validate inputs
    if (!eventId || !seatId || !userId) {
      const missingFields = [];
      if (!eventId) missingFields.push('eventId');
      if (!seatId) missingFields.push('seatId');
      if (!userId) missingFields.push('userId');
      
      console.error(`🚨 Missing required fields in direct lock:`, {
        eventId,
        seatId,
        userId,
        missingFields,
        headers: req.headers.authorization ? 'Present' : 'Missing'
      });
      
      return res.status(400).json({
        success: false,
        message: `Missing required fields: ${missingFields.join(', ')}`,
        error: 'INVALID_PARAMETERS'
      });
    }

    // Check if seat is already locked
    const lockStatus = await seatLockService.isSeatLocked(eventId, seatId);
    
    if (lockStatus.locked) {
      // If it's locked by the same user, return success (idempotent)
      if (lockStatus.userId === userId) {
        console.log(`✅ Seat already locked by requesting user: ${eventId}:${seatId}`);
        return res.json({
          success: true,
          message: 'Seat already locked by you',
          lockInfo: {
            eventId,
            seatId,
            userId,
            ttl: lockStatus.ttl
          }
        });
      }
      
      // Locked by another user
      console.log(`❌ Seat locked by different user: ${eventId}:${seatId}, owner: ${lockStatus.userId}, requester: ${userId}`);
      return res.status(409).json({
        success: false,
        message: 'Seat is temporarily locked by another user',
        ttl: lockStatus.ttl
      });
    }

    // Try to lock the seat
    const locked = await seatLockService.lockSeat(eventId, seatId, userId);
    
    if (locked) {
      console.log(`✅ Seat lock successful via direct endpoint: ${eventId}:${seatId} for user ${userId}`);
      res.json({
        success: true,
        message: 'Seat locked successfully',
        lockInfo: {
          eventId,
          seatId,
          userId,
          duration: '1 minute'
        }
      });
    } else {
      console.log(`❌ Seat lock failed via direct endpoint: ${eventId}:${seatId} for user ${userId}`);
      res.status(409).json({
        success: false,
        message: 'Failed to lock seat - may have been locked by another user'
      });
    }
  } catch (error) {
    console.error('🚨 Error in direct seat lock endpoint:', {
      error: error.message,
      stack: error.stack,
      eventId: req.params.eventId,
      seatId: req.params.seatId,
      userId: req.user?.user_id,
      code: error.code
    });
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message,
      code: error.code
    });
  }
});

// Check seat lock status
router.get('/events/:eventId/seats/:seatId/lock', async (req, res) => {
  try {
    const { eventId, seatId } = req.params;
    
    const lockStatus = await seatLockService.isSeatLocked(eventId, seatId);
    
    res.json({
      success: true,
      lockStatus: {
        locked: lockStatus.locked,
        ttl: lockStatus.ttl || null,
        ...(lockStatus.locked && {
          userId: lockStatus.userId,
          timestamp: lockStatus.timestamp
        })
      }
    });
  } catch (error) {
    console.error('Error checking seat lock status:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// Extend seat lock (for payment process)
router.put('/events/:eventId/seats/:seatId/lock/extend', authenticateToken, async (req, res) => {
  try {
    const { eventId, seatId } = req.params;
    const userId = req.user.user_id; // Fixed: use user_id from middleware

    const extended = await seatLockService.extendLock(eventId, seatId, userId);
    
    if (extended) {
      res.json({
        success: true,
        message: 'Lock extended successfully',
        duration: '10 minutes'
      });
    } else {
      res.status(403).json({
        success: false,
        message: 'Cannot extend lock - you do not own this lock or it has expired'
      });
    }
  } catch (error) {
    console.error('Error extending seat lock:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// Release seat lock
router.delete('/events/:eventId/seats/:seatId/lock', authenticateToken, async (req, res) => {
  try {
    const { eventId, seatId } = req.params;
    const userId = req.user.user_id; // Fixed: use user_id from middleware

    const released = await seatLockService.releaseLock(eventId, seatId, userId);
    
    if (released) {
      res.json({
        success: true,
        message: 'Lock released successfully'
      });
    } else {
      res.status(403).json({
        success: false,
        message: 'Cannot release lock - you do not own this lock or it does not exist'
      });
    }
  } catch (error) {
    console.error('Error releasing seat lock:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// Get all locked seats for an event
router.get('/events/:eventId/locks', async (req, res) => {
  try {
    const { eventId } = req.params;
    
    const lockedSeats = await seatLockService.getEventLockedSeats(eventId);
    
    res.json({
      success: true,
      eventId,
      lockedSeats: lockedSeats.map(seat => ({
        seatId: seat.seatId,
        ttl: seat.ttl,
        timestamp: seat.timestamp
        // Note: We don't expose userId for privacy
      }))
    });
  } catch (error) {
    console.error('Error getting event locked seats:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

module.exports = router;
