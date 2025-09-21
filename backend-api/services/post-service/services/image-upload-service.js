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

class ImageUploadService {
  constructor() {
    this.upload = multer({
      storage: multer.memoryStorage(),
      limits: {
        fileSize: 5 * 1024 * 1024, // 5MB limit
      },
      fileFilter: (req, file, cb) => {
        console.log("📎 File upload - MIME type:", file.mimetype);
        console.log("📎 File upload - Original name:", file.originalname);
        console.log("📎 File upload - Field name:", file.fieldname);

        if (file.mimetype.startsWith("image/")) {
          console.log("✅ File accepted as image");
          cb(null, true);
        } else {
          console.log("❌ File rejected - not an image:", file.mimetype);
          cb(new Error("Only image files are allowed"), false);
        }
      },
    });
  }

  // Upload single image to Cloudinary
  async uploadImage(buffer, options = {}) {
    try {
      const result = await new Promise((resolve, reject) => {
        const uploadOptions = {
          resource_type: "image",
          folder: "eventbn/posts", // Organize images in folders
          quality: "auto:good", // Optimize image quality
          fetch_format: "auto", // Auto-select best format
          ...options,
        };

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
      };
    } catch (error) {
      console.error("Error uploading image to Cloudinary:", error);
      return {
        success: false,
        error: error.message || "Failed to upload image",
      };
    }
  }

  // Upload multiple images
  async uploadMultipleImages(files, options = {}) {
    try {
      const uploadPromises = files.map((file) =>
        this.uploadImage(file.buffer, {
          ...options,
          public_id: `${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        })
      );

      const results = await Promise.allSettled(uploadPromises);

      const successful = [];
      const failed = [];

      results.forEach((result, index) => {
        if (result.status === "fulfilled" && result.value.success) {
          successful.push(result.value);
        } else {
          failed.push({
            index,
            error: result.reason || result.value?.error || "Upload failed",
          });
        }
      });

      // Format mediaUrl for database storage
      let mediaUrl = null;
      if (successful.length > 0) {
        if (successful.length === 1) {
          // Single image: store as simple string
          mediaUrl = successful[0].url;
        } else {
          // Multiple images: store as JSON array
          mediaUrl = JSON.stringify(successful.map((img) => img.url));
        }
      }

      return {
        success: failed.length === 0,
        mediaUrl, // This will be stored in the mediaUrl field
        successful,
        failed,
        urls: successful.map((img) => img.url),
        totalUploaded: successful.length,
        totalFailed: failed.length,
      };
    } catch (error) {
      console.error("Error uploading multiple images:", error);
      return {
        success: false,
        error: error.message || "Failed to upload images",
      };
    }
  }

  // Delete image from Cloudinary
  async deleteImage(publicId) {
    try {
      const result = await cloudinary.uploader.destroy(publicId);
      return {
        success: result.result === "ok",
        result: result.result,
      };
    } catch (error) {
      console.error("Error deleting image from Cloudinary:", error);
      return {
        success: false,
        error: error.message || "Failed to delete image",
      };
    }
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
const imageUploadService = new ImageUploadService();

module.exports = {
  imageUploadService,
  uploadImage: (buffer, options) =>
    imageUploadService.uploadImage(buffer, options),
  uploadMultipleImages: (files, options) =>
    imageUploadService.uploadMultipleImages(files, options),
  deleteImage: (publicId) => imageUploadService.deleteImage(publicId),
  generateOptimizedUrl: (publicId, options) =>
    imageUploadService.generateOptimizedUrl(publicId, options),
  generateThumbnail: (publicId, width, height) =>
    imageUploadService.generateThumbnail(publicId, width, height),
  getUploadMiddleware: (fieldName, maxCount) =>
    imageUploadService.getUploadMiddleware(fieldName, maxCount),
  getSingleUploadMiddleware: (fieldName) =>
    imageUploadService.getSingleUploadMiddleware(fieldName),
  getImageUploadHealth: () => imageUploadService.healthCheck(),
};
