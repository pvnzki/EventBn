const express = require("express");
const router = express.Router();
const postService = require("../index");
const coreServiceClient = require("../lib/core-service-client");

// Authentication middleware for external API
const authenticateUser = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({
      error: "Missing or invalid authorization header",
      service: "post-service",
    });
  }

  const token = authHeader.substring(7);

  if (!token) {
    return res.status(401).json({
      error: "Invalid token",
      service: "post-service",
    });
  }

  // In a real implementation, verify JWT token here
  req.token = token;
  next();
};

// Apply authentication to all routes
router.use(authenticateUser);

// Posts endpoints
router.get("/posts", async (req, res) => {
  try {
    const userId = req.headers["x-user-id"];
    const { page = 1, limit = 20, type } = req.query;

    const posts = await postService.posts.getPosts({
      userId,
      page: parseInt(page),
      limit: parseInt(limit),
      type,
    });

    // Enrich posts with user data from core service
    const enrichedPosts = await Promise.all(
      posts.data.map(async (post) => {
        try {
          const userResult = await coreServiceClient.getUserById(post.user_id);
          return {
            ...post,
            user: userResult.success ? userResult.user : null,
          };
        } catch (error) {
          console.error(
            `Failed to enrich post ${post.post_id} with user data:`,
            error
          );
          return {
            ...post,
            user: null,
          };
        }
      })
    );

    res.json({
      success: true,
      posts: enrichedPosts,
      pagination: posts.pagination,
      service: "post-service",
    });
  } catch (error) {
    console.error("[API] Error fetching posts:", error);
    res.status(500).json({
      error: "Failed to fetch posts",
      message: error.message,
      service: "post-service",
    });
  }
});

router.get("/posts/:postId", async (req, res) => {
  try {
    const { postId } = req.params;
    const post = await postService.posts.getPostById(postId);

    if (!post) {
      return res.status(404).json({
        error: "Post not found",
        service: "post-service",
      });
    }

    // Enrich with user data
    try {
      const userResult = await coreServiceClient.getUserById(post.user_id);
      if (userResult.success) {
        post.user = userResult.user;
      }
    } catch (error) {
      console.error(`Failed to enrich post ${postId} with user data:`, error);
      post.user = null;
    }

    res.json({
      success: true,
      post,
      service: "post-service",
    });
  } catch (error) {
    console.error("[API] Error fetching post:", error);
    res.status(500).json({
      error: "Failed to fetch post",
      message: error.message,
      service: "post-service",
    });
  }
});

router.post("/posts", async (req, res) => {
  try {
    const userId = req.headers["x-user-id"];
    const postData = { ...req.body, user_id: userId };

    if (!userId) {
      return res.status(400).json({
        error: "User ID required",
        service: "post-service",
      });
    }

    // Verify user exists in core service
    const userVerification = await coreServiceClient.verifyUser(userId);
    if (!userVerification.exists || !userVerification.active) {
      return res.status(400).json({
        error: "Invalid or inactive user",
        service: "post-service",
      });
    }

    const result = await postService.posts.createPost(postData);

    if (!result.success) {
      return res.status(400).json({
        error: result.message || "Post creation failed",
        service: "post-service",
      });
    }

    res.status(201).json({
      success: true,
      message: "Post created successfully",
      post: result.post,
      service: "post-service",
    });
  } catch (error) {
    console.error("[API] Error creating post:", error);
    res.status(500).json({
      error: "Failed to create post",
      message: error.message,
      service: "post-service",
    });
  }
});

router.put("/posts/:postId", async (req, res) => {
  try {
    const { postId } = req.params;
    const userId = req.headers["x-user-id"];
    const updates = req.body;

    const result = await postService.posts.updatePost(postId, updates, userId);

    if (!result.success) {
      return res.status(400).json({
        error: result.message || "Post update failed",
        service: "post-service",
      });
    }

    res.json({
      success: true,
      message: "Post updated successfully",
      post: result.post,
      service: "post-service",
    });
  } catch (error) {
    console.error("[API] Error updating post:", error);
    res.status(500).json({
      error: "Failed to update post",
      message: error.message,
      service: "post-service",
    });
  }
});

router.delete("/posts/:postId", async (req, res) => {
  try {
    const { postId } = req.params;
    const userId = req.headers["x-user-id"];

    const result = await postService.posts.deletePost(postId, userId);

    if (!result.success) {
      return res.status(400).json({
        error: result.message || "Post deletion failed",
        service: "post-service",
      });
    }

    res.json({
      success: true,
      message: "Post deleted successfully",
      service: "post-service",
    });
  } catch (error) {
    console.error("[API] Error deleting post:", error);
    res.status(500).json({
      error: "Failed to delete post",
      message: error.message,
      service: "post-service",
    });
  }
});

// Feeds endpoints
router.get("/feeds/home", async (req, res) => {
  try {
    const userId = req.headers["x-user-id"];
    const { page = 1, limit = 20 } = req.query;

    const feed = await postService.feeds.getHomeFeed(userId, {
      page: parseInt(page),
      limit: parseInt(limit),
    });

    // Batch enrich posts with user data
    const userIds = [...new Set(feed.data.map((post) => post.user_id))];
    let usersMap = {};

    try {
      const usersResult = await coreServiceClient.getUsersBatch(userIds);
      if (usersResult.success) {
        usersMap = usersResult.users.reduce((acc, user) => {
          acc[user.user_id] = user;
          return acc;
        }, {});
      }
    } catch (error) {
      console.error("Failed to batch fetch users for feed:", error);
    }

    const enrichedFeed = feed.data.map((post) => ({
      ...post,
      user: usersMap[post.user_id] || null,
    }));

    res.json({
      success: true,
      feed: enrichedFeed,
      pagination: feed.pagination,
      service: "post-service",
    });
  } catch (error) {
    console.error("[API] Error fetching home feed:", error);
    res.status(500).json({
      error: "Failed to fetch home feed",
      message: error.message,
      service: "post-service",
    });
  }
});

router.get("/feeds/explore", async (req, res) => {
  try {
    const { page = 1, limit = 30 } = req.query;

    const feed = await postService.feeds.getExploreFeed({
      page: parseInt(page),
      limit: parseInt(limit),
    });

    // Batch enrich with user data
    const userIds = [...new Set(feed.data.map((post) => post.user_id))];
    let usersMap = {};

    try {
      const usersResult = await coreServiceClient.getUsersBatch(userIds);
      if (usersResult.success) {
        usersMap = usersResult.users.reduce((acc, user) => {
          acc[user.user_id] = user;
          return acc;
        }, {});
      }
    } catch (error) {
      console.error("Failed to batch fetch users for explore feed:", error);
    }

    const enrichedFeed = feed.data.map((post) => ({
      ...post,
      user: usersMap[post.user_id] || null,
    }));

    res.json({
      success: true,
      feed: enrichedFeed,
      pagination: feed.pagination,
      service: "post-service",
    });
  } catch (error) {
    console.error("[API] Error fetching explore feed:", error);
    res.status(500).json({
      error: "Failed to fetch explore feed",
      message: error.message,
      service: "post-service",
    });
  }
});

// Comments endpoints
router.get("/posts/:postId/comments", async (req, res) => {
  try {
    const { postId } = req.params;
    const { page = 1, limit = 50 } = req.query;

    const comments = await postService.comments.getComments(postId, {
      page: parseInt(page),
      limit: parseInt(limit),
    });

    // Enrich with user data
    const userIds = [
      ...new Set(comments.data.map((comment) => comment.user_id)),
    ];
    let usersMap = {};

    try {
      const usersResult = await coreServiceClient.getUsersBatch(userIds);
      if (usersResult.success) {
        usersMap = usersResult.users.reduce((acc, user) => {
          acc[user.user_id] = user;
          return acc;
        }, {});
      }
    } catch (error) {
      console.error("Failed to batch fetch users for comments:", error);
    }

    const enrichedComments = comments.data.map((comment) => ({
      ...comment,
      user: usersMap[comment.user_id] || null,
    }));

    res.json({
      success: true,
      comments: enrichedComments,
      pagination: comments.pagination,
      service: "post-service",
    });
  } catch (error) {
    console.error("[API] Error fetching comments:", error);
    res.status(500).json({
      error: "Failed to fetch comments",
      message: error.message,
      service: "post-service",
    });
  }
});

router.post("/posts/:postId/comments", async (req, res) => {
  try {
    const { postId } = req.params;
    const userId = req.headers["x-user-id"];
    const { content } = req.body;

    if (!content || !content.trim()) {
      return res.status(400).json({
        error: "Comment content is required",
        service: "post-service",
      });
    }

    const result = await postService.comments.createComment({
      post_id: postId,
      user_id: userId,
      content: content.trim(),
    });

    if (!result.success) {
      return res.status(400).json({
        error: result.message || "Comment creation failed",
        service: "post-service",
      });
    }

    res.status(201).json({
      success: true,
      message: "Comment created successfully",
      comment: result.comment,
      service: "post-service",
    });
  } catch (error) {
    console.error("[API] Error creating comment:", error);
    res.status(500).json({
      error: "Failed to create comment",
      message: error.message,
      service: "post-service",
    });
  }
});

// Likes endpoints
router.post("/posts/:postId/like", async (req, res) => {
  try {
    const { postId } = req.params;
    const userId = req.headers["x-user-id"];

    const result = await postService.likes.toggleLike(postId, userId);

    res.json({
      success: true,
      message: result.liked ? "Post liked" : "Post unliked",
      liked: result.liked,
      totalLikes: result.totalLikes,
      service: "post-service",
    });
  } catch (error) {
    console.error("[API] Error toggling like:", error);
    res.status(500).json({
      error: "Failed to toggle like",
      message: error.message,
      service: "post-service",
    });
  }
});

router.get("/posts/:postId/likes", async (req, res) => {
  try {
    const { postId } = req.params;
    const { page = 1, limit = 50 } = req.query;

    const likes = await postService.likes.getLikes(postId, {
      page: parseInt(page),
      limit: parseInt(limit),
    });

    // Enrich with user data
    const userIds = likes.data.map((like) => like.user_id);
    let usersMap = {};

    try {
      const usersResult = await coreServiceClient.getUsersBatch(userIds);
      if (usersResult.success) {
        usersMap = usersResult.users.reduce((acc, user) => {
          acc[user.user_id] = user;
          return acc;
        }, {});
      }
    } catch (error) {
      console.error("Failed to batch fetch users for likes:", error);
    }

    const enrichedLikes = likes.data.map((like) => ({
      ...like,
      user: usersMap[like.user_id] || null,
    }));

    res.json({
      success: true,
      likes: enrichedLikes,
      pagination: likes.pagination,
      service: "post-service",
    });
  } catch (error) {
    console.error("[API] Error fetching likes:", error);
    res.status(500).json({
      error: "Failed to fetch likes",
      message: error.message,
      service: "post-service",
    });
  }
});

module.exports = router;
