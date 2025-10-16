// Post Service - Microservice for handling posts, comments, likes, shares
// This service can run independently and communicate with core-service

const posts = require("./posts");

class PostService {
  constructor() {
    this.posts = posts;
  }

  // Health check
  async health() {
    return {
      service: "post-service",
      status: "ok",
      timestamp: new Date().toISOString(),
      version: "1.0.0",
    };
  }

  // Legacy healthCheck method for backward compatibility
  async healthCheck() {
    return await this.health();
  }

  // Initialize service
  async initialize() {
    try {
      // Any initialization logic here
      console.log("Post Service initialized successfully");
      return true;
    } catch (error) {
      console.error("Post Service initialization failed:", error);
      return false;
    }
  }
}

// NOTE: Server startup is handled by server.js
// This file only exports the PostService class for use by server.js

module.exports = new PostService();
