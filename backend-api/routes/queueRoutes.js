const express = require('express');
const router = express.Router();
const queueService = require('../services/queueService');
const { authenticateToken } = require('../middleware/auth');

// Add seat lock request to queue
router.post('/events/:eventId/seats/:seatId/queue/lock', authenticateToken, async (req, res) => {
  try {
    const { eventId, seatId } = req.params;
    const userId = req.user.id;

    const requestId = await queueService.enqueueRequest({
      eventId,
      seatId,
      userId,
      action: 'lock'
    });

    res.json({
      success: true,
      message: 'Lock request queued successfully',
      requestId,
      queueInfo: {
        eventId,
        seatId,
        position: await queueService.getQueueLength(eventId)
      }
    });

  } catch (error) {
    console.error('Error queuing lock request:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to queue lock request',
      error: error.message
    });
  }
});

// Add seat lock extension request to queue
router.put('/events/:eventId/seats/:seatId/queue/extend', authenticateToken, async (req, res) => {
  try {
    const { eventId, seatId } = req.params;
    const userId = req.user.id;

    const requestId = await queueService.enqueueRequest({
      eventId,
      seatId,
      userId,
      action: 'extend'
    });

    res.json({
      success: true,
      message: 'Extend request queued successfully',
      requestId,
      queueInfo: {
        eventId,
        seatId,
        position: await queueService.getQueueLength(eventId)
      }
    });

  } catch (error) {
    console.error('Error queuing extend request:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to queue extend request',
      error: error.message
    });
  }
});

// Add seat lock release request to queue
router.delete('/events/:eventId/seats/:seatId/queue/release', authenticateToken, async (req, res) => {
  try {
    const { eventId, seatId } = req.params;
    const userId = req.user.id;

    const requestId = await queueService.enqueueRequest({
      eventId,
      seatId,
      userId,
      action: 'release'
    });

    res.json({
      success: true,
      message: 'Release request queued successfully',
      requestId,
      queueInfo: {
        eventId,
        seatId,
        position: await queueService.getQueueLength(eventId)
      }
    });

  } catch (error) {
    console.error('Error queuing release request:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to queue release request',
      error: error.message
    });
  }
});

// Get request result
router.get('/requests/:requestId/result', authenticateToken, async (req, res) => {
  try {
    const { requestId } = req.params;

    const result = await queueService.getRequestResult(requestId);

    if (!result) {
      return res.status(404).json({
        success: false,
        message: 'Request result not found or expired',
        requestId
      });
    }

    res.json({
      success: true,
      requestId,
      result,
      processedAt: result.processedAt
    });

  } catch (error) {
    console.error('Error getting request result:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get request result',
      error: error.message
    });
  }
});

// Poll for request result (with timeout)
router.get('/requests/:requestId/poll', authenticateToken, async (req, res) => {
  try {
    const { requestId } = req.params;
    const timeout = parseInt(req.query.timeout) || 30000; // Default 30 seconds
    const pollInterval = 1000; // Poll every 1 second
    
    const startTime = Date.now();

    const pollForResult = async () => {
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
      return res.status(408).json({
        success: false,
        message: 'Request processing timeout',
        requestId,
        timeout
      });
    };

    await pollForResult();

  } catch (error) {
    console.error('Error polling request result:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to poll request result',
      error: error.message
    });
  }
});

// Get queue statistics
router.get('/events/:eventId/queue/stats', async (req, res) => {
  try {
    const { eventId } = req.params;

    const stats = await queueService.getQueueStats(eventId);

    res.json({
      success: true,
      eventId,
      stats
    });

  } catch (error) {
    console.error('Error getting queue stats:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get queue stats',
      error: error.message
    });
  }
});

// Clear queue (admin only - use with caution)
router.delete('/events/:eventId/queue/clear', authenticateToken, async (req, res) => {
  try {
    const { eventId } = req.params;
    
    // TODO: Add admin role check
    // if (!req.user.isAdmin) {
    //   return res.status(403).json({ success: false, message: 'Admin access required' });
    // }

    const clearedCount = await queueService.clearQueue(eventId);

    res.json({
      success: true,
      message: `Cleared ${clearedCount} requests from queue`,
      eventId,
      clearedCount
    });

  } catch (error) {
    console.error('Error clearing queue:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to clear queue',
      error: error.message
    });
  }
});

module.exports = router;
