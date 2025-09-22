const express = require("express");
const jwt = require("jsonwebtoken");
// Use shared Prisma client (avoid multiple PrismaClient instances causing prepared statement collisions)
const { prisma } = require("../lib/database");
const { publishPostCreated } = require("../utils/rabbitmq-publisher");
const { getUserData, getUsersBatch } = require("../services/user-data-service");
const {
  getUploadMiddleware,
  uploadMultipleImages,
  uploadImage,
  getSingleUploadMiddleware,
} = require("../services/image-upload-service");

const router = express.Router();
console.log(
  `[POST-SERVICE] Using shared Prisma client (pid=${process.pid}) for routes/api.js`
);

// JWT Authentication middleware (enhanced logging for debugging device POST failures)
const verifyJWT = (req, res, next) => {
  const authHeader = req.headers.authorization;
  const reqId = `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
  req._reqId = reqId;
  try {
    if (!authHeader) {
      console.warn(
        `🔐 [AUTH][${reqId}] Missing Authorization header path=${req.method} ${req.path}`
      );
      return res
        .status(401)
        .json({
          success: false,
          error: "Authorization header required",
          code: "NO_AUTH_HEADER",
        });
    }
    if (!authHeader.startsWith("Bearer ")) {
      console.warn(
        `🔐 [AUTH][${reqId}] Malformed header value='${authHeader.slice(
          0,
          20
        )}...'`
      );
      return res
        .status(401)
        .json({
          success: false,
          error: "Malformed Authorization header",
          code: "BAD_AUTH_HEADER",
        });
    }
    const token = authHeader.slice(7);
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    console.log(
      `🔐 [AUTH][${reqId}] Authenticated userId=${
        decoded.userId || decoded.user_id || decoded.id
      }`
    );
    next();
  } catch (error) {
    console.warn(
      `🔐 [AUTH][${reqId}] Token verification failed: ${error.message}`
    );
    return res
      .status(401)
      .json({
        success: false,
        error: "Invalid or expired token",
        code: "TOKEN_INVALID",
        message: process.env.DEBUG ? error.message : undefined,
      });
  }
};

// Helper function to fetch user info from core-service
const fetchUserInfo = async (userId) => {
  try {
    const response = await axios.get(
      `${process.env.CORE_SERVICE_URL}/api/users/${userId}`,
      {
        headers: {
          Authorization: `Bearer ${process.env.INTERNAL_API_KEY}`,
        },
      }
    );
    return response.data.user;
  } catch (error) {
    console.warn("Failed to fetch user info:", error.message);
    return null;
  }
};

// Helper function to transform post data to match Flutter ExplorePost model
const transformPostForFlutter = async (post, currentUserId = null) => {
  console.log(
    "🔄 [TRANSFORM] Starting post transformation for post:",
    post.post_id
  );
  let userData = null;

  // Fetch user data via RabbitMQ
  try {
    console.log("🔍 [TRANSFORM] Fetching user data for user_id:", post.user_id);
    const userResponse = await getUserData(post.user_id);
    if (userResponse.success && userResponse.user) {
      userData = userResponse.user;
      console.log("✅ [TRANSFORM] User data fetched successfully");
    } else {
      console.log("⚠️ [TRANSFORM] User data not found");
    }
  } catch (error) {
    console.warn(
      "⚠️ [TRANSFORM] Failed to fetch user info via RabbitMQ:",
      error.message
    );
  }

  // Handle image URLs from image_url field
  let imageUrls = [];
  if (post.image_url) {
    try {
      // Try to parse as JSON array (multiple images)
      if (post.image_url.startsWith("[")) {
        imageUrls = JSON.parse(post.image_url);
      } else {
        // Single image URL string
        imageUrls = [post.image_url];
      }
    } catch (e) {
      // If parsing fails, treat as single URL string
      imageUrls = [post.image_url];
    }
  }

  const transformedPost = {
    id: post.post_id,
    userId: post.user_id,
    userDisplayName:
      userData?.name ||
      userData?.firstName + " " + userData?.lastName ||
      "Unknown User",
    userEmail: userData?.email || "",
    userAvatarUrl: userData?.profilePicture || "",
    content: post.caption || "",
    imageUrls: imageUrls,
    eventId: post.event_id || null,
    relatedEventName: null, // Would need event service integration
    relatedEventDate: null,
    relatedEventLocation: null,
    likesCount: post.likesCount || 0,
    commentsCount: post.commentsCount || 0,
    sharesCount: post.sharesCount || 0,
    isLiked:
      currentUserId && post.likes
        ? post.likes.some((like) => like.userId === currentUserId)
        : false,
    isBookmarked: false, // TODO: Implement bookmarks
    isUserVerified: userData?.isActive || false,
    postType: "eventMoment", // Default post type
    category: "all", // Default category
    tags: [],
    location: null,
    createdAt: post.created_at?.toISOString() || new Date().toISOString(),
    updatedAt: post.created_at?.toISOString() || new Date().toISOString(),
  };

  console.log(
    "✅ [TRANSFORM] Post transformation completed for post:",
    post.post_id
  );
  return transformedPost;
};

// Helper for 42P05 mitigation: retry once after DEALLOCATE ALL
async function fetchExplorePosts({ where, limit, skip }) {
  const start = process.hrtime.bigint();
  try {
    const posts = await prisma.post.findMany({
      where,
      orderBy: [{ created_at: "desc" }],
      take: limit,
      skip,
    });
    const elapsedMs = Number(process.hrtime.bigint() - start) / 1e6;
    return { posts, retry: false, elapsedMs };
  } catch (err) {
    // Detect prepared statement collision (Postgres 42P05)
    if (err?.message?.includes("42P05")) {
      console.warn(
        "⚠️ [EXPLORE] 42P05 detected. Attempting DEALLOCATE ALL then single retry."
      );
      try {
        await prisma.$executeRawUnsafe("DEALLOCATE ALL");
      } catch (deErr) {
        console.warn("⚠️ [EXPLORE] DEALLOCATE ALL failed:", deErr.message);
      }
      const retryStart = process.hrtime.bigint();
      const posts = await prisma.post.findMany({
        where,
        orderBy: [{ created_at: "desc" }],
        take: limit,
        skip,
      });
      const retryElapsedMs = Number(process.hrtime.bigint() - retryStart) / 1e6;
      return { posts, retry: true, elapsedMs: retryElapsedMs };
    }
    throw err;
  }
}

// GET /api/posts/explore - Get explore feed (public posts) with diagnostics & retry logic
router.get("/posts/explore", async (req, res) => {
  const reqId = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  const reqStart = process.hrtime.bigint();
  try {
    console.log(`📋 [EXPLORE][${reqId}] Request received params=%j`, req.query);
    const { page = 1, limit = 20, eventId } = req.query;
    const parsedLimit = Math.min(parseInt(limit), 100);
    const parsedPage = Math.max(parseInt(page), 1);
    const skip = (parsedPage - 1) * parsedLimit;
    const where = {};
    if (eventId) where.event_id = parseInt(eventId);

    const { posts, retry, elapsedMs } = await fetchExplorePosts({
      where,
      limit: parsedLimit,
      skip,
    });
    const countStart = process.hrtime.bigint();
    const totalPosts = await prisma.post.count({ where });
    const countElapsedMs = Number(process.hrtime.bigint() - countStart) / 1e6;

    console.log(
      `📋 [EXPLORE][${reqId}] posts=${
        posts.length
      } total=${totalPosts} queryMs=${elapsedMs.toFixed(
        2
      )} countMs=${countElapsedMs.toFixed(2)} retry=${retry}`
    );

    const transformStart = process.hrtime.bigint();
    const flutterPosts = await Promise.all(
      posts.map((p) => transformPostForFlutter(p))
    );
    const transformElapsedMs =
      Number(process.hrtime.bigint() - transformStart) / 1e6;

    const totalElapsedMs = Number(process.hrtime.bigint() - reqStart) / 1e6;
    console.log(
      `📋 [EXPLORE][${reqId}] response posts=${
        flutterPosts.length
      } transformMs=${transformElapsedMs.toFixed(
        2
      )} totalMs=${totalElapsedMs.toFixed(2)}`
    );

    res.json({
      success: true,
      posts: flutterPosts,
      pagination: {
        page: parsedPage,
        limit: parsedLimit,
        total: totalPosts,
        totalPages: Math.ceil(totalPosts / parsedLimit),
      },
      diagnostics: {
        retry,
        queryMs: elapsedMs,
        countMs: countElapsedMs,
        transformMs: transformElapsedMs,
        totalMs: totalElapsedMs,
      },
    });
  } catch (error) {
    const totalElapsedMs = Number(process.hrtime.bigint() - reqStart) / 1e6;
    console.error(
      `❌ [EXPLORE][${reqId}] Error after ${totalElapsedMs.toFixed(2)}ms:`,
      error
    );
    const isPreparedStmt = error?.message?.includes("42P05");
    res.status(500).json({
      success: false,
      error: "Failed to fetch explore feed",
      code: isPreparedStmt ? "PREPARED_STATEMENT_COLLISION" : "UNKNOWN",
      message: error.message,
      retryHint: isPreparedStmt
        ? "Consider adding ?pgbouncer=true to DATABASE_URL or ensure single PrismaClient per process"
        : undefined,
    });
  }
});

// GET /api/posts/:postId - Get single post by ID
router.get("/posts/:postId", verifyJWT, async (req, res) => {
  try {
    const { postId } = req.params;
    const currentUserId = req.user.userId;

    const post = await prisma.post.findUnique({
      where: { id: postId },
      include: {
        likes: {
          select: {
            userId: true,
          },
        },
      },
    });

    if (!post) {
      return res.status(404).json({
        success: false,
        error: "Post not found",
      });
    }

    const transformedPost = await transformPostForFlutter(post);

    res.json({
      success: true,
      post: transformedPost,
    });
  } catch (error) {
    console.error("Error fetching post:", error);
    res.status(500).json({
      success: false,
      error: "Failed to fetch post",
    });
  }
});

// POST /api/posts - Create new post with optional image upload
router.post(
  "/posts",
  verifyJWT,
  getUploadMiddleware("images", 5),
  async (req, res) => {
    try {
      const reqId =
        req._reqId || `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
      console.log(
        `📝 [POST CREATION][${reqId}] Start ip=${req.ip} contentType='${
          req.headers["content-type"]
        }' files=${req.files?.length || 0}`
      );
      console.log(`📝 [POST CREATION][${reqId}] User payload:`, {
        user: req.user,
      });
      console.log(
        `📝 [POST CREATION][${reqId}] Body keys:`,
        Object.keys(req.body || {})
      );

      const userId = req.user.userId || req.user.user_id || req.user.id;
      const { content, eventId } = req.body;

      console.log("Extracted userId:", userId);
      console.log("Content:", content);

      if (!content && !req.files?.length) {
        console.log(
          "❌ [POST CREATION] Validation failed: No content or images"
        );
        return res.status(400).json({
          success: false,
          error: "Post must have content or images",
        });
      }

      let mediaUrl = null;
      let uploadedImageCount = 0;

      // Upload images to Cloudinary if provided
      if (req.files && req.files.length > 0) {
        console.log(`Uploading ${req.files.length} images to Cloudinary...`);

        const uploadResult = await uploadMultipleImages(req.files, {
          folder: "eventbn/posts",
          transformation: [{ quality: "auto:good" }, { fetch_format: "auto" }],
        });

        if (!uploadResult.success) {
          return res.status(500).json({
            success: false,
            error: "Failed to upload images",
            details: uploadResult.error,
          });
        }

        mediaUrl = uploadResult.mediaUrl; // This is already formatted for single/multiple images
        uploadedImageCount = uploadResult.totalUploaded;
        console.log(`Successfully uploaded ${uploadedImageCount} images`);
      }

      // Fetch user data via RabbitMQ (optional - don't fail if this fails)
      let userData = null;
      try {
        console.log("🔍 [POST CREATION] Fetching user data via RabbitMQ...");
        const userResponse = await getUserData(userId.toString());
        if (userResponse.success && userResponse.user) {
          userData = userResponse.user;
          console.log("✅ [POST CREATION] User data fetched successfully");
        } else {
          console.log(
            "⚠️ [POST CREATION] User data not found in RabbitMQ response"
          );
        }
      } catch (error) {
        console.warn(
          "⚠️ [POST CREATION] Failed to fetch user info via RabbitMQ:",
          error.message
        );
      }

      console.log("💾 [POST CREATION] Creating post in database...");
      const post = await prisma.post.create({
        data: {
          caption: content || "",
          image_url: mediaUrl, // Store single image URL
          user_id: parseInt(userId),
          event_id: eventId ? parseInt(eventId) : null,
        },
      });

      console.log("✅ [POST CREATION] Post created in database:", post.post_id);

      // Publish to RabbitMQ for real-time updates
      try {
        await publishPostCreated({
          postId: post.post_id,
          authorId: post.user_id,
          eventId: post.event_id,
          hasImages: uploadedImageCount > 0,
          imageCount: uploadedImageCount,
          timestamp: new Date().toISOString(),
        });
      } catch (rabbitError) {
        console.error("Failed to publish post creation event:", rabbitError);
      }

      console.log("🔄 [POST CREATION] Transforming post for Flutter...");
      const transformedPost = await transformPostForFlutter(post);
      console.log("✅ [POST CREATION] Post transformed successfully");

      console.log("✅ [POST CREATION] Post creation completed successfully!");
      res.status(201).json({
        success: true,
        message: "Post created successfully",
        post: transformedPost,
        uploadedImages: uploadedImageCount,
      });
    } catch (error) {
      const reqId = req._reqId || "no-id";
      console.error(`❌ [POST CREATION][${reqId}] Error creating post:`, error);
      console.error("Stack trace:", error.stack);
      res.status(500).json({
        success: false,
        error: "Failed to create post",
        details: error.message,
      });
    }
  }
);

// Lightweight debug endpoint to test device connectivity & auth header presence
router.get("/posts/debug/ping", (req, res) => {
  res.json({
    success: true,
    message: "post-service alive",
    preparedStatementsDisabled:
      process.env.PRISMA_CLIENT_DISABLE_PREPARED_STATEMENTS === "1",
    timestamp: new Date().toISOString(),
  });
});

// PUT /api/posts/:postId - Update post
router.put("/posts/:postId", verifyJWT, async (req, res) => {
  try {
    const { postId } = req.params;
    const userId = req.user.userId || req.user.user_id || req.user.id;
    const { content, mediaUrl } = req.body;

    // Check if post exists and user owns it
    const existingPost = await prisma.post.findUnique({
      where: { id: postId },
    });

    if (!existingPost) {
      return res.status(404).json({
        success: false,
        error: "Post not found",
      });
    }

    if (existingPost.authorId !== userId.toString()) {
      return res.status(403).json({
        success: false,
        error: "Not authorized to update this post",
      });
    }

    const updatedPost = await prisma.post.update({
      where: { id: postId },
      data: {
        content,
        mediaUrl,
        updatedAt: new Date(),
      },
      include: {
        likes: {
          select: {
            userId: true,
          },
        },
      },
    });

    const transformedPost = await transformPostForFlutter(updatedPost);

    res.json({
      success: true,
      message: "Post updated successfully",
      post: transformedPost,
    });
  } catch (error) {
    console.error("Error updating post:", error);
    res.status(500).json({
      success: false,
      error: "Failed to update post",
    });
  }
});

// DELETE /api/posts/:postId - Delete post
router.delete("/posts/:postId", verifyJWT, async (req, res) => {
  try {
    const { postId } = req.params;
    const userId = req.user.userId || req.user.user_id || req.user.id;

    // Check if post exists and user owns it
    const existingPost = await prisma.post.findUnique({
      where: { id: postId },
    });

    if (!existingPost) {
      return res.status(404).json({
        success: false,
        error: "Post not found",
      });
    }

    if (existingPost.authorId !== userId.toString()) {
      return res.status(403).json({
        success: false,
        error: "Not authorized to delete this post",
      });
    }

    // Delete post (cascade should handle likes/comments)
    await prisma.post.delete({
      where: { id: postId },
    });

    res.json({
      success: true,
      message: "Post deleted successfully",
    });
  } catch (error) {
    console.error("Error deleting post:", error);
    res.status(500).json({
      success: false,
      error: "Failed to delete post",
    });
  }
});

// POST /api/posts/:postId/like - Toggle like on post
router.post("/posts/:postId/like", verifyJWT, async (req, res) => {
  try {
    const { postId } = req.params;
    const userId = req.user.userId || req.user.user_id || req.user.id;

    // Check if post exists
    const post = await prisma.post.findUnique({
      where: { id: postId },
    });

    if (!post) {
      return res.status(404).json({
        success: false,
        error: "Post not found",
      });
    }

    // Check if user already liked the post
    const existingLike = await prisma.postLike.findUnique({
      where: {
        postId_userId: {
          postId: postId,
          userId: userId.toString(),
        },
      },
    });

    let liked;
    if (existingLike) {
      // Unlike the post
      await prisma.postLike.delete({
        where: {
          postId_userId: {
            postId: postId,
            userId: userId.toString(),
          },
        },
      });

      // Decrement likes count
      await prisma.post.update({
        where: { id: postId },
        data: { likesCount: { decrement: 1 } },
      });

      liked = false;
    } else {
      // Like the post
      await prisma.postLike.create({
        data: {
          postId: postId,
          userId: userId.toString(),
        },
      });

      // Increment likes count
      await prisma.post.update({
        where: { id: postId },
        data: { likesCount: { increment: 1 } },
      });

      liked = true;

      // Publish like event for real-time notifications
      try {
        await publishToQueue("post_liked", {
          postId: postId,
          userId: userId.toString(),
          postAuthorId: post.authorId,
          timestamp: new Date().toISOString(),
        });
      } catch (rabbitError) {
        console.error("Failed to publish like event:", rabbitError);
      }
    }

    // Get updated likes count
    const updatedPost = await prisma.post.findUnique({
      where: { id: postId },
      select: { likesCount: true },
    });

    res.json({
      success: true,
      liked,
      likesCount: updatedPost.likesCount,
    });
  } catch (error) {
    console.error("Error toggling like:", error);
    res.status(500).json({
      success: false,
      error: "Failed to toggle like",
    });
  }
});

module.exports = router;
