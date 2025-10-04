const express = require("express");
const jwt = require("jsonwebtoken");
const axios = require("axios");
// Use shared Prisma client (avoid multiple PrismaClient instances causing prepared statement collisions)
const { prisma } = require("../lib/database");
// Import RabbitMQ publisher - functions are disabled internally for analytics separation
const {
  publishPostCreated,
  publishPostLiked,
  publishPostUnliked,
  publishCommentCreated,
} = require("../utils/rabbitmq-publisher");
const { getUserData, getUsersBatch } = require("../services/user-data-service");
const {
  getUploadMiddleware,
  getFieldsUploadMiddleware, // Add the new method
  uploadMultipleMedia, // Updated to use the new media upload method
  uploadImage,
  getSingleUploadMiddleware,
  generateVideoThumbnail, // Add video thumbnail generation
} = require("../services/image-upload-service");

const router = express.Router();
console.log(
  `[POST-SERVICE] Using shared Prisma client (pid=${process.pid}) for routes/api.js`
);

// Helper function to safely parse userId - handle both string and numeric formats
function parseUserId(userId) {
  if (!userId) {
    console.warn("⚠️ parseUserId: userId is null or undefined");
    return null;
  }

  // If already a number, return it
  if (typeof userId === "number") {
    return userId;
  }

  // If string and starts with 'user_', extract the numeric part
  if (typeof userId === "string") {
    if (userId.startsWith("user_") && userId.length > 5) {
      const numericPart = parseInt(userId.substring(5));
      if (!isNaN(numericPart)) {
        return numericPart;
      } else {
        console.warn(
          `⚠️ parseUserId: Could not parse numeric part from '${userId}'`
        );
        return null;
      }
    } else {
      // Try to parse as direct number
      const numericValue = parseInt(userId);
      if (!isNaN(numericValue)) {
        return numericValue;
      } else {
        console.warn(`⚠️ parseUserId: Could not parse '${userId}' as number`);
        return null;
      }
    }
  }

  console.warn(
    `⚠️ parseUserId: Unexpected userId type: ${typeof userId}, value: ${userId}`
  );
  return null;
}

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
      return res.status(401).json({
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
      return res.status(401).json({
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
    return res.status(401).json({
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

// Helper function to fetch event info via RabbitMQ
const { getEventData } = require("../services/event-data-service");

const fetchEventInfo = async (eventId) => {
  try {
    console.log(
      `🎫 [EVENT-FETCH] Fetching event data via RabbitMQ for ID: ${eventId}`
    );
    const response = await getEventData(eventId);

    if (response.success && response.event) {
      console.log(
        `✅ [EVENT-FETCH] Successfully fetched event via RabbitMQ: ${response.event.title}`
      );
      return response.event;
    } else {
      console.warn(
        `❌ [EVENT-FETCH] Event not found for ID ${eventId}:`,
        response.message
      );
      return null;
    }
  } catch (error) {
    console.warn(
      `❌ [EVENT-FETCH] Failed to fetch event info via RabbitMQ for ID ${eventId}:`,
      error.message
    );
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

  // Handle media URLs from the new images and videos columns
  let imageUrls = [];
  let videoUrls = [];

  // Use new images column if available
  if (post.images && Array.isArray(post.images)) {
    imageUrls = post.images;
  } else if (post.image_url) {
    // Fallback to legacy image_url field for backward compatibility
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

  // Handle videos from the new videos column
  if (post.videos && Array.isArray(post.videos)) {
    videoUrls = post.videos;
  }

  // Generate video thumbnails for better display performance
  const videoThumbnails = videoUrls
    .map((videoUrl) => {
      try {
        console.log(
          "🎬 [TRANSFORM] Processing video URL for thumbnail:",
          videoUrl
        );

        // More robust publicId extraction for Cloudinary URLs
        // Handle URLs like: https://res.cloudinary.com/cloudname/video/upload/v123456/folder/filename.mp4
        const cloudinaryUrlRegex =
          /cloudinary\.com\/[^\/]+\/video\/upload\/(?:v\d+\/)?(.+?)(?:\.[^.]+)?$/;
        const match = videoUrl.match(cloudinaryUrlRegex);

        if (match && match[1]) {
          const publicId = match[1];
          console.log(
            "✅ [TRANSFORM] Extracted publicId for thumbnail:",
            publicId
          );
          const thumbnailUrl = generateVideoThumbnail(publicId, 300, 200);
          console.log("🖼️ [TRANSFORM] Generated thumbnail URL:", thumbnailUrl);
          return thumbnailUrl;
        } else {
          console.warn(
            "⚠️ [TRANSFORM] Could not extract publicId from video URL:",
            videoUrl
          );
          return null;
        }
      } catch (error) {
        console.warn(
          "⚠️ [TRANSFORM] Failed to generate video thumbnail:",
          error.message
        );
        return null;
      }
    })
    .filter(Boolean); // Remove null entries

  console.log(
    `🎬 [TRANSFORM] Generated ${videoThumbnails.length} video thumbnails from ${videoUrls.length} videos`
  );

  // Fetch event data if event_id exists
  let eventData = null;
  if (post.event_id) {
    try {
      console.log(
        "🎫 [TRANSFORM] Fetching event data for event_id:",
        post.event_id
      );
      eventData = await fetchEventInfo(post.event_id);
      if (eventData) {
        console.log(
          "✅ [TRANSFORM] Event data fetched successfully:",
          eventData.title
        );
      }
    } catch (error) {
      console.warn("⚠️ [TRANSFORM] Failed to fetch event info:", error.message);
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
    videoUrls: videoUrls, // Add video URLs for Flutter
    videoThumbnails: videoThumbnails, // Add video thumbnails for better UX
    eventId: post.event_id || null,
    relatedEventName: eventData?.title || null,
    relatedEventImage:
      eventData?.imageUrl || eventData?.cover_image_url || null,
    relatedEventDate:
      eventData?.startDateTime || eventData?.start_date_time || null,
    relatedEventLocation: eventData?.venue || eventData?.location || null,
    likesCount: post.engagement_count || 0,
    commentsCount: post.comment_count || 0,
    sharesCount: post.sharesCount || 0,
    isLiked: (() => {
      const hasCurrentUser = currentUserId !== null;
      const hasLikes = post.likes && post.likes.length > 0;
      const isLikedByUser =
        hasCurrentUser && hasLikes
          ? post.likes.some((like) => like.user_id === currentUserId)
          : false;

      console.log(`🔄 [TRANSFORM] Like status for post ${post.post_id}:`, {
        currentUserId,
        hasCurrentUser,
        hasLikes,
        likesCount: post.likes ? post.likes.length : 0,
        likeUserIds: post.likes ? post.likes.map((l) => l.user_id) : [],
        isLikedByUser,
      });

      return isLikedByUser;
    })(),
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
      select: {
        post_id: true,
        user_id: true,
        event_id: true,
        caption: true,
        image_url: true,
        images: true, // Add new images column
        videos: true, // Add new videos column
        engagement_count: true,
        comment_count: true,
        allow_comments: true,
        created_at: true,
        updated_at: true,
        likes: {
          select: {
            user_id: true,
          },
        },
      },
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
        select: {
          post_id: true,
          user_id: true,
          event_id: true,
          caption: true,
          image_url: true,
          engagement_count: true,
          comment_count: true,
          allow_comments: true,
          created_at: true,
          updated_at: true,
          likes: {
            select: {
              user_id: true,
            },
          },
        },
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

// GET /api/health - Health check endpoint
router.get("/health", async (req, res) => {
  console.log("🏥 [HEALTH] Health check request received");

  // Test database connectivity
  let dbStatus = "unknown";
  try {
    await prisma.$queryRaw`SELECT 1 as test`;
    dbStatus = "connected";
  } catch (dbError) {
    dbStatus = "disconnected";
    console.error("🏥 [HEALTH] Database test failed:", dbError.message);
  }

  res.status(200).json({
    success: true,
    service: "post-service",
    status: "healthy",
    timestamp: new Date().toISOString(),
    version: "1.0.0",
    uptime: process.uptime(),
    pid: process.pid,
    database: dbStatus,
    environment: process.env.NODE_ENV || "unknown",
    port: process.env.POST_SERVICE_PORT || "3002",
  });
});

// GET /api/test - Test endpoint for debugging mobile connectivity (no auth required)
router.get("/test", async (req, res) => {
  console.log(
    "🧪 [TEST] Test endpoint called from:",
    req.headers["user-agent"] || "unknown"
  );

  // Count posts in database
  let postCount = 0;
  try {
    postCount = await prisma.post.count();
  } catch (error) {
    console.error("🧪 [TEST] Error counting posts:", error.message);
  }

  res.status(200).json({
    success: true,
    message: "Post service is reachable from mobile app",
    timestamp: new Date().toISOString(),
    postCount,
    clientInfo: {
      ip: req.ip || req.connection?.remoteAddress,
      userAgent: req.headers["user-agent"],
      origin: req.headers["origin"],
    },
  });
});

// GET /api/debug/test-token - Generate a test JWT token for testing (development only)
router.get("/debug/test-token", async (req, res) => {
  if (process.env.NODE_ENV === "production") {
    return res
      .status(403)
      .json({ success: false, message: "Not available in production" });
  }

  console.log("🔑 [DEBUG] Generating test token...");

  try {
    // Create a test user payload with numeric user_id to match database schema
    const testUserPayload = {
      userId: 1001, // Use numeric ID to match database schema
      user_id: 1001, // Alternative format
      id: 1001, // Another alternative
      email: "test@eventbn.com",
      name: "Test User",
      role: "USER",
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 7 * 24 * 60 * 60, // 7 days
    };

    const token = jwt.sign(testUserPayload, process.env.JWT_SECRET);

    res.status(200).json({
      success: true,
      message: "Test token generated successfully",
      token: token,
      payload: testUserPayload,
      instructions:
        "Use this token in the Authorization header as 'Bearer <token>'",
    });
  } catch (error) {
    console.error("🔑 [DEBUG] Error generating test token:", error);
    res
      .status(500)
      .json({ success: false, message: "Failed to generate test token" });
  }
});

// GET /api/debug/check-posts - Check existing posts and comments for debugging
router.get("/debug/check-posts", async (req, res) => {
  if (process.env.NODE_ENV === "production") {
    return res
      .status(403)
      .json({ success: false, message: "Not available in production" });
  }

  console.log("🔍 [DEBUG] Checking existing posts and comments...");

  try {
    const posts = await prisma.post.findMany({
      take: 10,
      orderBy: { created_at: "desc" },
    });

    const comments = await prisma.comment.findMany({
      take: 20,
      orderBy: { created_at: "desc" },
    });

    const postCount = await prisma.post.count();
    const commentCount = await prisma.comment.count();

    console.log(
      `📊 [DEBUG] Found ${postCount} posts and ${commentCount} comments`
    );

    res.status(200).json({
      success: true,
      data: {
        summary: {
          totalPosts: postCount,
          totalComments: commentCount,
        },
        recentPosts: posts,
        recentComments: comments,
      },
    });
  } catch (error) {
    console.error("🔍 [DEBUG] Error checking posts:", error);
    res.status(500).json({ success: false, message: error.message });
  }
});

// POST /api/debug/seed-posts - Create test posts for development
router.post("/debug/seed-posts", async (req, res) => {
  if (process.env.NODE_ENV === "production") {
    return res
      .status(403)
      .json({ success: false, message: "Not available in production" });
  }

  console.log("🌱 [DEBUG] Creating test posts...");

  try {
    const testPosts = [
      {
        content:
          "🎉 Excited for the upcoming Summer Music Festival! Who else is going? #EventBn #MusicFestival",
        media_urls: [
          "https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=800&h=600&fit=crop",
        ],
        user_id: "test-user-001",
        post_type: "event_moment",
      },
      {
        content:
          "Just registered for the Tech Innovation Summit. Can't wait to see all the latest AI demos! 🚀",
        media_urls: [],
        user_id: "test-user-001",
        post_type: "event_moment",
      },
      {
        content:
          "Morning run preparation for the City Marathon 🏃‍♂️ Training has been intense but so worth it!",
        media_urls: [
          "https://images.unsplash.com/photo-1544717297-fa95b6ee9643?w=800&h=600&fit=crop",
        ],
        user_id: "test-user-001",
        post_type: "event_moment",
      },
    ];

    const createdPosts = [];
    for (const postData of testPosts) {
      const post = await prisma.post.create({
        data: {
          ...postData,
          created_at: new Date(),
          updated_at: new Date(),
        },
      });
      createdPosts.push(post);
      console.log(`✅ Created test post: ${post.post_id}`);
    }

    res.status(200).json({
      success: true,
      message: `Created ${createdPosts.length} test posts`,
      posts: createdPosts,
    });
  } catch (error) {
    console.error("🌱 [DEBUG] Error creating test posts:", error);
    res.status(500).json({
      success: false,
      message: "Failed to create test posts",
      error: error.message,
    });
  }
});

// GET /api/posts/explore - Get explore feed (public posts) with diagnostics & retry logic
router.get("/posts/explore", async (req, res) => {
  const reqId = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  const reqStart = process.hrtime.bigint();

  // Optional JWT verification - get user ID if authenticated, but don't require auth
  let currentUserId = null;
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith("Bearer ")) {
    try {
      const token = authHeader.substring(7);
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      currentUserId = decoded.userId || decoded.user_id || decoded.id;
      console.log(
        `👤 [EXPLORE][${reqId}] Authenticated user: ${currentUserId}`
      );
    } catch (err) {
      console.log(
        `⚠️ [EXPLORE][${reqId}] Invalid JWT token, proceeding as guest`
      );
    }
  } else {
    console.log(`👤 [EXPLORE][${reqId}] No auth token, proceeding as guest`);
  }

  try {
    console.log(`📋 [EXPLORE][${reqId}] Request received params=%j`, req.query);
    const { page = 1, limit = 20, eventId, userId } = req.query;
    const parsedLimit = Math.min(parseInt(limit), 100);
    const parsedPage = Math.max(parseInt(page), 1);
    const skip = (parsedPage - 1) * parsedLimit;
    const where = {};
    if (eventId) where.event_id = parseInt(eventId);
    if (userId) {
      // Handle both numeric and string user IDs (e.g., "user_123" -> 123)
      const numericUserId = parseUserId(userId);
      if (numericUserId === null) {
        console.warn(`⚠️ [EXPLORE][${reqId}] Invalid userId format: ${userId}`);
        return res.status(400).json({
          success: false,
          error: "Invalid userId format",
        });
      }

      if (!isNaN(numericUserId)) {
        where.user_id = numericUserId;
        console.log(
          `📋 [EXPLORE][${reqId}] Filtering by user_id: ${numericUserId} (from: ${userId})`
        );
      } else {
        console.warn(`📋 [EXPLORE][${reqId}] Invalid userId format: ${userId}`);
      }
    }

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
      posts.map((p) => transformPostForFlutter(p, currentUserId))
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

// POST /api/posts - Create new post with optional media upload (images and videos)
router.post(
  "/posts",
  verifyJWT,
  getFieldsUploadMiddleware([
    { name: "images", maxCount: 5 },
    { name: "videos", maxCount: 5 },
  ]),
  async (req, res) => {
    try {
      const reqId =
        req._reqId || `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
      console.log(
        `📝 [POST CREATION][${reqId}] Start ip=${req.ip} contentType='${
          req.headers["content-type"]
        }' imageFiles=${req.files?.images?.length || 0} videoFiles=${
          req.files?.videos?.length || 0
        }`
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

      const hasFiles =
        req.files?.images?.length > 0 || req.files?.videos?.length > 0;

      if (!content && !hasFiles) {
        console.log(
          "❌ [POST CREATION] Validation failed: No content or media files"
        );
        return res.status(400).json({
          success: false,
          error: "Post must have content or media files",
        });
      }

      let images = [];
      let videos = [];
      let uploadedFileCount = 0;

      // Combine all files from both images and videos fields
      const allFiles = [];
      if (req.files?.images) allFiles.push(...req.files.images);
      if (req.files?.videos) allFiles.push(...req.files.videos);

      // Upload media files to Cloudinary if provided
      if (allFiles.length > 0) {
        console.log(
          `Uploading ${allFiles.length} media files to Cloudinary...`
        );

        const uploadResult = await uploadMultipleMedia(allFiles, {
          folder: "eventbn/posts",
          // Remove heavy transformations to speed up upload
          // Apply minimal processing during upload for faster response
          quality: "auto:eco", // Use eco instead of good for faster upload
          // Remove fetch_format auto to avoid conversion during upload
        });

        if (!uploadResult.success) {
          return res.status(500).json({
            success: false,
            error: "Failed to upload media files",
            details: uploadResult.error,
          });
        }

        images = uploadResult.images || [];
        videos = uploadResult.videos || [];
        uploadedFileCount = uploadResult.totalUploaded;
        console.log(
          `Successfully uploaded ${images.length} images and ${videos.length} videos`
        );
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

      // Handle both numeric and string user IDs (e.g., "user_123" -> 123)
      const numericUserId = parseUserId(userId);
      if (numericUserId === null) {
        console.error(`❌ [POST CREATION] Invalid userId format: ${userId}`);
        return res.status(400).json({
          success: false,
          error: "Invalid user ID format",
        });
      }

      const post = await prisma.post.create({
        data: {
          caption: content || "",
          image_url: images.length > 0 ? images[0] : null, // For backward compatibility
          images: images, // New images array column
          videos: videos, // New videos array column
          user_id: numericUserId,
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
          hasImages: images.length > 0,
          hasVideos: videos.length > 0,
          imageCount: images.length,
          videoCount: videos.length,
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
        uploadedImages: images.length,
        uploadedVideos: videos.length,
        totalMediaFiles: uploadedFileCount,
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

    // Handle both numeric and string user IDs (e.g., "user_123" -> 123)
    const numericUserId = parseUserId(userId);
    if (numericUserId === null) {
      console.error(`❌ [LIKE] Invalid userId format: ${userId}`);
      return res.status(400).json({
        success: false,
        error: "Invalid user ID format",
      });
    }

    // Check if post exists
    const post = await prisma.post.findUnique({
      where: { post_id: parseInt(postId) },
    });

    if (!post) {
      return res.status(404).json({
        success: false,
        error: "Post not found",
      });
    }

    // Check if user already liked the post
    const existingLike = await prisma.postLike.findFirst({
      where: {
        post_id: parseInt(postId),
        user_id: numericUserId,
      },
    });

    let liked;
    if (existingLike) {
      // Unlike the post
      await prisma.postLike.delete({
        where: {
          id: existingLike.id,
        },
      });

      // Decrement likes count
      await prisma.post.update({
        where: { post_id: parseInt(postId) },
        data: { engagement_count: { decrement: 1 } },
      });

      liked = false;

      // Publish unlike event for real-time notifications
      try {
        await publishPostUnliked(post, {
          userId: numericUserId,
          timestamp: new Date().toISOString(),
        });
        console.log(
          `✅ [UNLIKE] Published unlike event for post ${postId} by user ${userId}`
        );
      } catch (rabbitError) {
        console.error(
          "❌ [UNLIKE] Failed to publish unlike event:",
          rabbitError
        );
      }
    } else {
      // Like the post
      await prisma.postLike.create({
        data: {
          post_id: parseInt(postId),
          user_id: numericUserId,
        },
      });

      // Increment likes count
      await prisma.post.update({
        where: { post_id: parseInt(postId) },
        data: { engagement_count: { increment: 1 } },
      });

      liked = true;

      // Publish like event for real-time notifications (temporarily disabled - analytics tables not available)
      /*
      try {
        await publishPostLiked(post, {
          userId: parseInt(userId),
          timestamp: new Date().toISOString(),
        });
        console.log(`✅ [LIKE] Published like event for post ${postId} by user ${userId}`);
      } catch (rabbitError) {
        console.error("❌ [LIKE] Failed to publish like event:", rabbitError);
      }
      */
    }

    // Get updated likes count
    const updatedPost = await prisma.post.findUnique({
      where: { post_id: parseInt(postId) },
      select: { engagement_count: true },
    });

    res.json({
      success: true,
      liked,
      likesCount: updatedPost.engagement_count || 0,
    });
  } catch (error) {
    console.error("Error toggling like:", error);
    res.status(500).json({
      success: false,
      error: "Failed to toggle like",
    });
  }
});

// ========== COMMENT ROUTES ==========

// Get comments for a post
router.get("/posts/:postId/comments", verifyJWT, async (req, res) => {
  try {
    const { postId } = req.params;
    const { page = 1, limit = 20 } = req.query;
    const requestingUserId = req.user.userId || req.user.user_id || req.user.id;

    console.log(
      `📖 [GET_COMMENTS] Request - postId: ${postId}, page: ${page}, limit: ${limit}, userId: ${requestingUserId}`
    );

    const offset = (parseInt(page) - 1) * parseInt(limit);
    const numericPostId = parseInt(postId);

    if (isNaN(numericPostId)) {
      console.error(`📖 [GET_COMMENTS] Invalid postId format: ${postId}`);
      return res.status(400).json({
        success: false,
        message: "Invalid post ID format",
      });
    }

    // Fetch top-level comments with their replies
    const comments = await prisma.comment.findMany({
      where: {
        post_id: numericPostId,
        parent_comment_id: null, // Only get top-level comments
      },
      select: {
        comment_id: true,
        post_id: true,
        user_id: true,
        comment_text: true,
        created_at: true,
        updated_at: true,
        like_count: true,
        _count: {
          select: { replies: true },
        },
        likes: {
          select: {
            user_id: true,
          },
        },
        replies: {
          select: {
            comment_id: true,
            post_id: true,
            user_id: true,
            comment_text: true,
            created_at: true,
            updated_at: true,
            like_count: true,
            parent_comment_id: true,
            likes: {
              select: {
                user_id: true,
              },
            },
          },
          orderBy: { created_at: "asc" },
        },
      },
      orderBy: { created_at: "desc" },
      skip: offset,
      take: parseInt(limit),
    });

    console.log(
      `📖 [GET_COMMENTS] Found ${comments.length} comments for post ${postId}`
    );

    // Get all user IDs (including from replies)
    const userIds = [
      ...new Set([
        ...comments.map((c) => c.user_id),
        ...comments.flatMap((c) => c.replies?.map((r) => r.user_id) || []),
      ]),
    ];

    let usersData = [];
    if (userIds.length > 0) {
      try {
        console.log(
          `📖 [GET_COMMENTS] Fetching user data for ${userIds.length} users (including reply authors)`
        );
        const userResponse = await getUsersBatch(userIds);
        // Handle different response formats from user service
        usersData = userResponse?.users || userResponse?.data?.users || [];
        console.log(
          `📖 [GET_COMMENTS] Received ${usersData.length} user records`
        );
        console.log(
          `📖 [GET_COMMENTS] User response structure:`,
          Object.keys(userResponse || {})
        );
      } catch (userError) {
        console.warn(
          "⚠️ [GET_COMMENTS] Failed to fetch users data from service, trying local database:",
          userError.message
        );

        // Fallback: Try to get user data from local users table
        try {
          const localUsers = await prisma.users.findMany({
            where: {
              id: {
                in: userIds.map((id) => id.toString()),
              },
            },
            select: {
              id: true,
              full_name: true,
              avatar_url: true,
            },
          });

          usersData = localUsers.map((user) => ({
            id: parseInt(user.id),
            full_name: user.full_name,
            name: user.full_name,
            avatar_url: user.avatar_url,
          }));

          console.log(
            `📖 [GET_COMMENTS] Found ${usersData.length} users in local database`
          );
        } catch (localError) {
          console.warn(
            "⚠️ [GET_COMMENTS] Local user lookup also failed:",
            localError.message
          );
          // Final fallback: use generic user names
        }
      }
    }

    // Format comments with replies and user data
    const commentsWithUsers = comments.map((comment) => {
      const userData = usersData.find((u) => u.id == comment.user_id) || {
        id: comment.user_id,
        full_name: `User ${comment.user_id}`,
        avatar_url: null,
      };

      // Check if current user has liked this comment
      const isLikedByUser =
        requestingUserId && comment.likes
          ? comment.likes.some((like) => like.user_id === requestingUserId)
          : false;

      // Format replies with user data
      const formattedReplies =
        comment.replies?.map((reply) => {
          const replyUserData = usersData.find(
            (u) => u.id == reply.user_id
          ) || {
            id: reply.user_id,
            full_name: `User ${reply.user_id}`,
            avatar_url: null,
          };

          const isReplyLikedByUser =
            requestingUserId && reply.likes
              ? reply.likes.some((like) => like.user_id === requestingUserId)
              : false;

          return {
            comment_id: reply.comment_id,
            post_id: reply.post_id,
            user_id: reply.user_id,
            comment_text: reply.comment_text,
            created_at: reply.created_at,
            updated_at: reply.updated_at,
            like_count: reply.like_count || 0,
            is_liked: isReplyLikedByUser,
            parent_comment_id: reply.parent_comment_id,
            user_display_name:
              replyUserData.full_name ||
              replyUserData.name ||
              `User ${reply.user_id}`,
            user_name:
              replyUserData.full_name ||
              replyUserData.name ||
              `User ${reply.user_id}`,
            user: replyUserData,
          };
        }) || [];

      console.log(
        `💖 [COMMENT_LIKE] Comment ${
          comment.comment_id
        }: userId=${requestingUserId}, hasLikes=${
          comment.likes?.length || 0
        }, isLiked=${isLikedByUser}, replies=${formattedReplies.length}`
      );

      return {
        comment_id: comment.comment_id,
        post_id: comment.post_id,
        user_id: comment.user_id,
        comment_text: comment.comment_text,
        created_at: comment.created_at,
        updated_at: comment.updated_at,
        like_count: comment.like_count || 0,
        is_liked: isLikedByUser,
        user_display_name:
          userData.full_name || userData.name || `User ${comment.user_id}`,
        user_name:
          userData.full_name || userData.name || `User ${comment.user_id}`,
        user: userData,
        replies_count: comment._count?.replies || 0,
        replies: formattedReplies,
      };
    });

    console.log(
      `📖 [GET_COMMENTS] Formatted ${commentsWithUsers.length} comments with user data`
    );

    // Optimized: Skip total count for first page to improve speed
    // Only calculate total when explicitly needed (pagination info)
    let totalComments = null;
    const needsPaginationInfo =
      parseInt(page) > 1 || req.query.includePagination === "true";

    if (needsPaginationInfo) {
      totalComments = await prisma.comment.count({
        where: {
          post_id: numericPostId,
          parent_comment_id: null,
        },
      });
    }

    const response = {
      success: true,
      data: {
        comments: commentsWithUsers,
        pagination:
          totalComments !== null
            ? {
                page: parseInt(page),
                limit: parseInt(limit),
                total: totalComments,
                pages: Math.ceil(totalComments / parseInt(limit)),
              }
            : {
                page: parseInt(page),
                limit: parseInt(limit),
                hasMore: commentsWithUsers.length >= parseInt(limit), // Simple check for more data
              },
      },
    };

    console.log(
      `✅ [GET_COMMENTS] Returning ${commentsWithUsers.length} comments for post ${postId}`
    );
    return res.status(200).json(response);
  } catch (error) {
    console.error("❌ [GET_COMMENTS] Database error:", error);
    console.error("❌ [GET_COMMENTS] Error stack:", error.stack);

    return res.status(500).json({
      success: false,
      message: error.message || "Failed to fetch comments",
      details:
        process.env.NODE_ENV === "development"
          ? {
              originalError: error.message,
              postId: req.params.postId,
              userId: req.user.userId || req.user.user_id || req.user.id,
            }
          : undefined,
    });
  }
});

// Add comment to post
router.post("/posts/:postId/comments", verifyJWT, async (req, res) => {
  try {
    const { postId } = req.params;
    const { content, parentCommentId } = req.body;
    const authorId = req.user.userId || req.user.user_id || req.user.id;

    console.log(
      `💬 [ADD_COMMENT] Request - postId: ${postId}, authorId: ${authorId}, content: "${content}"`
    );
    console.log(`💬 [ADD_COMMENT] User object:`, req.user);

    if (!content || content.trim().length === 0) {
      console.warn(`💬 [ADD_COMMENT] Invalid content: "${content}"`);
      return res.status(400).json({
        success: false,
        message: "Comment content is required",
      });
    }

    if (!authorId) {
      console.error(`💬 [ADD_COMMENT] No user ID found in token:`, req.user);
      return res.status(400).json({
        success: false,
        message: "User ID not found in authentication token",
      });
    }

    // Validate IDs are numeric
    const numericPostId = parseInt(postId);
    const numericAuthorId = parseInt(authorId);

    if (isNaN(numericPostId) || isNaN(numericAuthorId)) {
      console.error(
        `💬 [ADD_COMMENT] Invalid ID format - postId: ${postId} (${numericPostId}), authorId: ${authorId} (${numericAuthorId})`
      );
      return res.status(400).json({
        success: false,
        message: `Invalid ID format - postId: ${postId}, authorId: ${authorId}`,
      });
    }

    console.log(
      `💬 [ADD_COMMENT] Creating comment - post_id: ${numericPostId}, user_id: ${numericAuthorId}`
    );

    // Create comment directly with correct field names
    const comment = await prisma.comment.create({
      data: {
        post_id: numericPostId,
        user_id: numericAuthorId,
        comment_text: content.trim(),
        parent_comment_id: parentCommentId ? parseInt(parentCommentId) : null,
      },
    });

    console.log(`✅ [ADD_COMMENT] Comment created successfully:`, comment);

    // Store/update user data in local users table for future reference
    try {
      await prisma.users.upsert({
        where: { id: authorId.toString() },
        update: {
          full_name:
            req.user.name ||
            req.user.fullName ||
            req.user.full_name ||
            `User ${authorId}`,
          avatar_url:
            req.user.avatar ||
            req.user.avatarUrl ||
            req.user.avatar_url ||
            null,
          updated_at: new Date(),
        },
        create: {
          id: authorId.toString(),
          full_name:
            req.user.name ||
            req.user.fullName ||
            req.user.full_name ||
            `User ${authorId}`,
          avatar_url:
            req.user.avatar ||
            req.user.avatarUrl ||
            req.user.avatar_url ||
            null,
        },
      });
      console.log(
        `💾 [ADD_COMMENT] Updated local user data for user ${authorId}`
      );
    } catch (userStoreError) {
      console.warn(
        `⚠️ [ADD_COMMENT] Failed to store user data locally:`,
        userStoreError.message
      );
    }

    // Update comment count on post
    await prisma.post.update({
      where: { post_id: parseInt(postId) },
      data: { comment_count: { increment: 1 } },
    });

    // Publish comment created event for real-time notifications (temporarily disabled - analytics tables not available)
    /*
    try {
      await publishCommentCreated({
        ...comment,
        postId: numericPostId,
        timestamp: new Date().toISOString(),
      });
      console.log(`✅ [ADD_COMMENT] Published comment created event for post ${postId} by user ${authorId}`);
    } catch (rabbitError) {
      console.error("❌ [ADD_COMMENT] Failed to publish comment event:", rabbitError);
    }
    */

    // Get user data from JWT token instead of making service call
    const userData = {
      id: authorId,
      full_name:
        req.user.name ||
        req.user.fullName ||
        req.user.full_name ||
        `User ${authorId}`,
      name:
        req.user.name ||
        req.user.fullName ||
        req.user.full_name ||
        `User ${authorId}`,
      avatar_url:
        req.user.avatar || req.user.avatarUrl || req.user.avatar_url || null,
      email: req.user.email || null,
    };

    console.log(`💬 [ADD_COMMENT] Using JWT user data:`, userData);

    const response = {
      success: true,
      message: "Comment added successfully",
      data: {
        comment: {
          ...comment,
          user_display_name: userData.full_name,
          user_name: userData.name,
          user: userData,
        },
      },
    };

    console.log(`✅ [ADD_COMMENT] Full response:`, response);
    return res.status(201).json(response);
  } catch (error) {
    console.error("❌ [ADD_COMMENT] Database error:", error);
    console.error("❌ [ADD_COMMENT] Error stack:", error.stack);

    // Provide more specific error messages based on error type
    let errorMessage = "Failed to add comment";
    let statusCode = 500;

    if (error.code === "P2003") {
      errorMessage = "Invalid post ID - post does not exist";
      statusCode = 400;
    } else if (error.code === "P2002") {
      errorMessage = "Duplicate comment detected";
      statusCode = 409;
    } else if (
      error.message.includes("Invalid") ||
      error.message.includes("format")
    ) {
      errorMessage = `Data format error: ${error.message}`;
      statusCode = 400;
    }

    return res.status(statusCode).json({
      success: false,
      message: errorMessage,
      details:
        process.env.NODE_ENV === "development"
          ? {
              originalError: error.message,
              code: error.code,
              postId: req.params.postId,
              authorId: req.user.userId || req.user.user_id || req.user.id,
            }
          : undefined,
    });
  }
});

// Update comment
router.put("/comments/:commentId", verifyJWT, async (req, res) => {
  try {
    const { commentId } = req.params;
    const { content } = req.body;

    // Parse userId - handle both string and numeric formats
    const authorId = parseUserId(req.user.userId);
    if (authorId === null) {
      console.error(
        `❌ [COMMENT UPDATE] Invalid userId format: ${req.user.userId}`
      );
      return res.status(400).json({
        success: false,
        error: "Invalid user ID format",
      });
    }

    if (!content || content.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: "Comment content is required",
      });
    }

    // Check if comment exists and user owns it
    const existingComment = await prisma.comment.findUnique({
      where: { comment_id: parseInt(commentId) },
      select: { user_id: true },
    });

    if (!existingComment) {
      return res.status(404).json({
        success: false,
        message: "Comment not found",
      });
    }

    if (existingComment.user_id !== authorId) {
      return res.status(403).json({
        success: false,
        message: "Not authorized to edit this comment",
      });
    }

    const updatedComment = await prisma.comment.update({
      where: { comment_id: parseInt(commentId) },
      data: {
        comment_text: content.trim(),
        updated_at: new Date(),
      },
    });

    const response = {
      success: true,
      message: "Comment updated successfully",
      data: { comment: updatedComment },
    };

    return res.status(200).json(response);
  } catch (error) {
    console.error("Update comment error:", error);
    return res.status(500).json({
      success: false,
      message: error.message || "Failed to update comment",
    });
  }
});

// Delete comment
router.delete("/comments/:commentId", verifyJWT, async (req, res) => {
  try {
    const { commentId } = req.params;

    // Parse userId - handle both string and numeric formats
    const authorId = parseUserId(req.user.userId);
    if (authorId === null) {
      console.error(
        `❌ [COMMENT DELETE] Invalid userId format: ${req.user.userId}`
      );
      return res.status(400).json({
        success: false,
        error: "Invalid user ID format",
      });
    }

    // Check if comment exists and get post_id for count update
    const comment = await prisma.comment.findUnique({
      where: { comment_id: parseInt(commentId) },
      select: { user_id: true, post_id: true },
    });

    if (!comment) {
      return res.status(404).json({
        success: false,
        message: "Comment not found",
      });
    }

    if (comment.user_id !== authorId) {
      return res.status(403).json({
        success: false,
        message: "Not authorized to delete this comment",
      });
    }

    // Delete the comment
    await prisma.comment.delete({
      where: { comment_id: parseInt(commentId) },
    });

    // Update comment count on post
    await prisma.post.update({
      where: { post_id: comment.post_id },
      data: { comment_count: { decrement: 1 } },
    });

    const response = {
      success: true,
      message: "Comment deleted successfully",
    };

    return res.status(200).json(response);
  } catch (error) {
    console.error("Delete comment error:", error);
    return res.status(500).json({
      success: false,
      message: error.message || "Failed to delete comment",
    });
  }
});

// Like/Unlike comment
router.post("/comments/:commentId/like", verifyJWT, async (req, res) => {
  try {
    const { commentId } = req.params;

    // Parse userId - handle both string and numeric formats
    const userId = parseUserId(req.user.userId);
    if (userId === null) {
      console.error(
        `❌ [COMMENT LIKE] Invalid userId format: ${req.user.userId}`
      );
      return res.status(400).json({
        success: false,
        error: "Invalid user ID format",
      });
    }

    // Check if comment exists
    const comment = await prisma.comment.findUnique({
      where: { comment_id: parseInt(commentId) },
    });

    if (!comment) {
      return res.status(404).json({
        success: false,
        message: "Comment not found",
      });
    }

    // Check if user already liked this comment
    const existingLike = await prisma.commentLike.findFirst({
      where: {
        user_id: userId,
        comment_id: parseInt(commentId),
      },
    });

    let isLiked;

    if (existingLike) {
      // Unlike comment
      await prisma.commentLike.delete({
        where: {
          id: existingLike.id,
        },
      });

      await prisma.comment.update({
        where: { comment_id: parseInt(commentId) },
        data: { like_count: { decrement: 1 } },
      });

      isLiked = false;
    } else {
      // Like comment
      await prisma.commentLike.create({
        data: {
          user_id: userId,
          comment_id: parseInt(commentId),
        },
      });

      await prisma.comment.update({
        where: { comment_id: parseInt(commentId) },
        data: { like_count: { increment: 1 } },
      });

      isLiked = true;
    }

    const response = {
      success: true,
      message: isLiked
        ? "Comment liked successfully"
        : "Comment unliked successfully",
      data: { isLiked },
    };

    return res.status(200).json(response);
  } catch (error) {
    console.error("Comment like toggle error:", error);
    return res.status(500).json({
      success: false,
      message: error.message || "Failed to toggle comment like",
    });
  }
});

// GET /api/comments/:commentId/replies - Fast endpoint for loading replies on-demand
router.get("/comments/:commentId/replies", verifyJWT, async (req, res) => {
  try {
    const { commentId } = req.params;
    const { page = 1, limit = 10 } = req.query;
    const requestingUserId = req.user.userId || req.user.user_id || req.user.id;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    console.log(
      `🔄 [GET_REPLIES] Loading replies for comment ${commentId}, userId: ${requestingUserId}`
    );

    const replies = await prisma.comment.findMany({
      where: { parent_comment_id: parseInt(commentId) },
      select: {
        comment_id: true,
        post_id: true,
        user_id: true,
        comment_text: true,
        created_at: true,
        updated_at: true,
        like_count: true,
        parent_comment_id: true,
        likes: {
          select: {
            user_id: true,
          },
        },
      },
      orderBy: { created_at: "asc" },
      skip: offset,
      take: parseInt(limit),
    });

    // Fast user data fetch for replies
    const userIds = [...new Set(replies.map((r) => r.user_id))];
    let usersData = [];

    if (userIds.length > 0) {
      try {
        const userResponse = await getUsersBatch(userIds);
        usersData = userResponse?.users || [];
      } catch (error) {
        console.warn(
          "⚠️ [GET_REPLIES] Failed to fetch user data:",
          error.message
        );
      }
    }

    const repliesWithUsers = replies.map((reply) => {
      const userData = usersData.find((u) => u.id == reply.user_id) || {
        id: reply.user_id,
        full_name: `User ${reply.user_id}`,
        avatar_url: null,
      };

      // Check if current user has liked this reply
      const isLikedByUser =
        requestingUserId && reply.likes
          ? reply.likes.some((like) => like.user_id === requestingUserId)
          : false;

      console.log(
        `💖 [REPLY_LIKE] Reply ${
          reply.comment_id
        }: userId=${requestingUserId}, hasLikes=${
          reply.likes?.length || 0
        }, isLiked=${isLikedByUser}`
      );

      return {
        comment_id: reply.comment_id,
        post_id: reply.post_id,
        user_id: reply.user_id,
        comment_text: reply.comment_text,
        created_at: reply.created_at,
        updated_at: reply.updated_at,
        like_count: reply.like_count || 0,
        is_liked: isLikedByUser,
        parent_comment_id: reply.parent_comment_id,
        user_display_name:
          userData.full_name || userData.name || `User ${reply.user_id}`,
        user: userData,
      };
    });

    console.log(
      `✅ [GET_REPLIES] Returning ${repliesWithUsers.length} replies`
    );

    return res.status(200).json({
      success: true,
      data: {
        replies: repliesWithUsers,
        hasMore: repliesWithUsers.length >= parseInt(limit),
      },
    });
  } catch (error) {
    console.error("❌ [GET_REPLIES] Error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to load replies",
    });
  }
});

module.exports = router;
