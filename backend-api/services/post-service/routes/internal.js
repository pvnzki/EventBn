const express = require("express");
const router = express.Router();
const postService = require("../index");

// Middleware for service-to-service authentication
const serviceAuth = (req, res, next) => {
  const serviceKey = req.headers['x-service-key'];
  const expectedKey = process.env.INTER_SERVICE_KEY || 'dev-service-key';
  
  if (!serviceKey || serviceKey !== expectedKey) {
    return res.status(401).json({
      error: "Unauthorized service access",
      service: "post-service"
    });
  }
  
  next();
};

// Apply service auth to all internal routes
router.use(serviceAuth);

// Get posts by user ID (for core service to fetch user's posts)
router.get("/users/:userId/posts", async (req, res) => {
  try {
    const { userId } = req.params;
    const { page = 1, limit = 20, type } = req.query;
    
    const posts = await postService.posts.getPostsByUserId(userId, {
      page: parseInt(page),
      limit: parseInt(limit),
      type
    });

    res.json({
      success: true,
      posts: posts.data,
      pagination: posts.pagination,
      service: "post-service"
    });
  } catch (error) {
    console.error("[INTERNAL API] Error fetching user posts:", error);
    res.status(500).json({
      error: "Failed to fetch user posts",
      message: error.message
    });
  }
});

// Get post statistics for analytics
router.get("/posts/:postId/stats", async (req, res) => {
  try {
    const { postId } = req.params;
    
    const stats = await postService.analytics.getPostStats(postId);
    
    if (!stats) {
      return res.status(404).json({
        error: "Post not found",
        postId
      });
    }

    res.json({
      success: true,
      stats,
      service: "post-service"
    });
  } catch (error) {
    console.error("[INTERNAL API] Error fetching post stats:", error);
    res.status(500).json({
      error: "Failed to fetch post statistics",
      message: error.message
    });
  }
});

// Get user engagement metrics
router.get("/users/:userId/engagement", async (req, res) => {
  try {
    const { userId } = req.params;
    const { startDate, endDate } = req.query;
    
    const engagement = await postService.analytics.getUserEngagement(userId, {
      startDate: startDate ? new Date(startDate) : undefined,
      endDate: endDate ? new Date(endDate) : undefined
    });

    res.json({
      success: true,
      engagement,
      service: "post-service"
    });
  } catch (error) {
    console.error("[INTERNAL API] Error fetching user engagement:", error);
    res.status(500).json({
      error: "Failed to fetch user engagement",
      message: error.message
    });
  }
});

// Batch delete user posts (for account deletion in core service)
router.delete("/users/:userId/posts", async (req, res) => {
  try {
    const { userId } = req.params;
    
    const result = await postService.posts.deleteUserPosts(userId);
    
    res.json({
      success: true,
      message: "User posts deleted successfully",
      deletedCount: result.deletedCount,
      service: "post-service"
    });
  } catch (error) {
    console.error("[INTERNAL API] Error deleting user posts:", error);
    res.status(500).json({
      error: "Failed to delete user posts", 
      message: error.message
    });
  }
});

// Get trending posts for analytics
router.get("/posts/trending", async (req, res) => {
  try {
    const { limit = 10, timeframe = '24h' } = req.query;
    
    const trendingPosts = await postService.analytics.getTrendingPosts({
      limit: parseInt(limit),
      timeframe
    });

    res.json({
      success: true,
      posts: trendingPosts,
      service: "post-service"
    });
  } catch (error) {
    console.error("[INTERNAL API] Error fetching trending posts:", error);
    res.status(500).json({
      error: "Failed to fetch trending posts",
      message: error.message
    });
  }
});

// Health check endpoint for service discovery
router.get("/health", async (req, res) => {
  try {
    const health = await postService.health();
    
    res.json({
      ...health,
      timestamp: new Date().toISOString(),
      service: "post-service"
    });
  } catch (error) {
    console.error("[INTERNAL API] Health check failed:", error);
    res.status(500).json({
      service: "post-service",
      status: "unhealthy",
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Service metrics endpoint
router.get("/metrics", async (req, res) => {
  try {
    const metrics = await postService.analytics.getServiceMetrics();
    
    res.json({
      success: true,
      metrics,
      service: "post-service",
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error("[INTERNAL API] Error fetching metrics:", error);
    res.status(500).json({
      error: "Failed to fetch service metrics",
      message: error.message
    });
  }
});

module.exports = router;