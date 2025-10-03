require("dotenv").config();
const cloudinary = require("cloudinary").v2;
const multer = require("multer");
const { Readable } = require("stream");

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

class MediaUploadService {
  constructor() {
    this.upload = multer({
      storage: multer.memoryStorage(),
      limits: {
        fileSize: 100 * 1024 * 1024, // Increased to 100MB for larger videos
      },
      fileFilter: (req, file, cb) => {
        console.log("📎 File upload - MIME type:", file.mimetype);
        console.log("📎 File upload - Original name:", file.originalname);
        console.log("📎 File upload - Field name:", file.fieldname);

        const isImage = file.mimetype.startsWith("image/");
        const isVideo = file.mimetype.startsWith("video/");

        if (isImage || isVideo) {
          // Check file size limits based on type
          if (isVideo && file.size > 100 * 1024 * 1024) {
            console.log("❌ Video file too large:", file.size);
            cb(new Error("Video files must be under 100MB"), false);
          } else if (isImage && file.size > 10 * 1024 * 1024) {
            // Increased image limit too
            console.log("❌ Image file too large:", file.size);
            cb(new Error("Image files must be under 10MB"), false);
          } else {
            console.log(`✅ File accepted as ${isImage ? "image" : "video"}`);
            cb(null, true);
          }
        } else {
          console.log(
            "❌ File rejected - not an image or video:",
            file.mimetype
          );
          cb(new Error("Only image and video files are allowed"), false);
        }
      },
    });
  }

  // Upload single media file (image or video) to Cloudinary
  async uploadMedia(buffer, mimetype, options = {}) {
    try {
      const isVideo = mimetype.startsWith("video/");
      const resourceType = isVideo ? "video" : "image";

      const result = await new Promise((resolve, reject) => {
        const uploadOptions = {
          resource_type: resourceType,
          folder: `eventbn/posts/${resourceType}s`, // Organize by type
          quality: "auto:good",
          fetch_format: "auto",
          ...options,
        };

        // For videos, optimize upload settings
        if (isVideo) {
          // Only apply minimal transformations to speed up upload
          uploadOptions.resource_type = "video";
          // Remove format conversion for faster upload - let Cloudinary handle it naturally
          // uploadOptions.format = "mp4"; // This causes slow conversion
          // uploadOptions.video_codec = "h264"; // This causes slow conversion

          // Instead, use eager transformations that happen asynchronously after upload
          uploadOptions.eager = [
            {
              format: "mp4",
              video_codec: "h264",
              quality: "auto:good",
              width: 1280, // Limit size for web playback
              height: 720,
              crop: "limit", // Don't upscale, only downscale if needed
            },
          ];
          uploadOptions.eager_async = true; // Process transformations in background
        }

        const uploadStream = cloudinary.uploader.upload_stream(
          uploadOptions,
          (error, result) => {
            if (error) {
              reject(error);
            } else {
              resolve(result);
            }
          }
        );

        // Convert buffer to stream and pipe to Cloudinary
        const stream = Readable.from(buffer);
        stream.pipe(uploadStream);
      });

      return {
        success: true,
        url: result.secure_url,
        publicId: result.public_id,
        width: result.width,
        height: result.height,
        format: result.format,
        bytes: result.bytes,
        duration: result.duration, // For videos
        resourceType: result.resource_type,
      };
    } catch (error) {
      console.error(
        `Error uploading ${
          mimetype.startsWith("video/") ? "video" : "image"
        } to Cloudinary:`,
        error
      );
      return {
        success: false,
        error: error.message || "Failed to upload media",
      };
    }
  }

  // Upload multiple media files (images and videos)
  async uploadMultipleMedia(files, options = {}) {
    try {
      const uploadPromises = files.map((file) =>
        this.uploadMedia(file.buffer, file.mimetype, {
          ...options,
          public_id: `${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        })
      );

      const results = await Promise.allSettled(uploadPromises);

      const successful = [];
      const failed = [];
      const images = [];
      const videos = [];

      results.forEach((result, index) => {
        if (result.status === "fulfilled" && result.value.success) {
          const mediaResult = result.value;
          successful.push(mediaResult);

          // Separate images and videos
          if (mediaResult.resourceType === "video") {
            videos.push(mediaResult.url);
          } else {
            images.push(mediaResult.url);
          }
        } else {
          failed.push({
            index,
            error: result.reason || result.value?.error || "Upload failed",
          });
        }
      });

      return {
        success: failed.length === 0,
        successful,
        failed,
        images, // Array of image URLs for database
        videos, // Array of video URLs for database
        totalUploaded: successful.length,
        totalFailed: failed.length,
      };
    } catch (error) {
      console.error("Error uploading multiple media files:", error);
      return {
        success: false,
        error: error.message || "Failed to upload media files",
      };
    }
  }

  // Delete media from Cloudinary
  async deleteImage(publicId) {
    try {
      const result = await cloudinary.uploader.destroy(publicId);
      return {
        success: result.result === "ok",
        result: result.result,
      };
    } catch (error) {
      console.error("Error deleting media from Cloudinary:", error);
      return {
        success: false,
        error: error.message || "Failed to delete media",
      };
    }
  }

  // Generate thumbnail URL for videos
  generateVideoThumbnail(publicId, width = 300, height = 300) {
    const thumbnailUrl = cloudinary.url(publicId, {
      resource_type: "video",
      format: "jpg", // Extract frame as JPEG
      width,
      height,
      crop: "fill",
      gravity: "auto",
      start_offset: "1", // Take thumbnail at 1 second
      quality: "auto:good",
      secure: true, // Force HTTPS URLs
    });

    console.log(
      `🔍 [THUMBNAIL] Generated URL for publicId '${publicId}': ${thumbnailUrl}`
    );

    return thumbnailUrl;
  }

  // Generate optimized image URLs
  generateOptimizedUrl(publicId, options = {}) {
    const defaultOptions = {
      quality: "auto:good",
      fetch_format: "auto",
      crop: "fill",
      gravity: "auto",
      ...options,
    };

    return cloudinary.url(publicId, defaultOptions);
  }

  // Generate thumbnail URL
  generateThumbnail(publicId, width = 300, height = 300) {
    return this.generateOptimizedUrl(publicId, {
      width,
      height,
      crop: "thumb",
      gravity: "face",
    });
  }

  // Get upload middleware for Express with multiple fields
  getFieldsUploadMiddleware(fields) {
    return this.upload.fields(fields);
  }

  // Get upload middleware for Express
  getUploadMiddleware(fieldName = "images", maxCount = 5) {
    return this.upload.array(fieldName, maxCount);
  }

  // Get single upload middleware for Express
  getSingleUploadMiddleware(fieldName = "image") {
    return this.upload.single(fieldName);
  }

  // Health check for Cloudinary
  async healthCheck() {
    try {
      const result = await cloudinary.api.ping();
      return {
        status: "connected",
        cloudName: process.env.CLOUDINARY_CLOUD_NAME,
        result,
      };
    } catch (error) {
      return {
        status: "error",
        error: error.message,
      };
    }
  }
}

// Create singleton instance
const mediaUploadService = new MediaUploadService();

module.exports = {
  mediaUploadService,
  // Backward compatibility
  imageUploadService: mediaUploadService,

  // New media upload methods
  uploadMedia: (buffer, mimetype, options) =>
    mediaUploadService.uploadMedia(buffer, mimetype, options),
  uploadMultipleMedia: (files, options) =>
    mediaUploadService.uploadMultipleMedia(files, options),

  // Legacy image methods for backward compatibility
  uploadImage: (buffer, options) =>
    mediaUploadService.uploadMedia(buffer, "image/jpeg", options),
  uploadMultipleImages: (files, options) =>
    mediaUploadService.uploadMultipleMedia(files, options),

  // Shared methods
  deleteImage: (publicId) => mediaUploadService.deleteImage(publicId),
  generateOptimizedUrl: (publicId, options) =>
    mediaUploadService.generateOptimizedUrl(publicId, options),
  generateThumbnail: (publicId, width, height) =>
    mediaUploadService.generateThumbnail(publicId, width, height),
  generateVideoThumbnail: (publicId, width, height) =>
    mediaUploadService.generateVideoThumbnail(publicId, width, height),
  getUploadMiddleware: (fieldName, maxCount) =>
    mediaUploadService.getUploadMiddleware(fieldName, maxCount),
  getFieldsUploadMiddleware: (fields) =>
    mediaUploadService.getFieldsUploadMiddleware(fields),
  getSingleUploadMiddleware: (fieldName) =>
    mediaUploadService.getSingleUploadMiddleware(fieldName),
  getImageUploadHealth: () => mediaUploadService.healthCheck(),
};
