require("dotenv").config();
const amqp = require("amqplib");

class PostServiceRabbitMQPublisher {
  constructor() {
    this.connection = null;
    this.channel = null;
    this.isConnecting = false;
    this.reconnectDelay = 5000;
    this.maxReconnectAttempts = 10;
    this.reconnectAttempts = 0;

    this.config = {
      url: process.env.RABBITMQ_URL || "amqp://localhost:5672",
      exchange: process.env.RABBITMQ_EXCHANGE || "eventbn_exchange",
      queues: {
        postEvents: process.env.RABBITMQ_POST_QUEUE || "post_events",
        socialEvents: process.env.RABBITMQ_SOCIAL_QUEUE || "social_events",
        analyticsEvents: "analytics_events",
      },
    };
  }

  async connect() {
    if (this.connection && !this.connection.connection.stream.destroyed) {
      return true;
    }

    if (this.isConnecting) {
      return false;
    }

    this.isConnecting = true;

    try {
      console.log("[POST-RABBITMQ] Connecting to RabbitMQ...");

      this.connection = await amqp.connect(this.config.url);
      this.channel = await this.connection.createChannel();

      // Setup exchange
      await this.channel.assertExchange(this.config.exchange, "topic", {
        durable: true,
      });

      // Setup queues
      for (const [name, queueName] of Object.entries(this.config.queues)) {
        await this.channel.assertQueue(queueName, {
          durable: true,
          arguments: {
            "x-message-ttl": 24 * 60 * 60 * 1000,
            "x-max-length": 10000,
          },
        });
      }

      // Bind queues to exchange with routing patterns
      await this.channel.bindQueue(
        this.config.queues.postEvents,
        this.config.exchange,
        "post.*"
      );

      await this.channel.bindQueue(
        this.config.queues.socialEvents,
        this.config.exchange,
        "social.*"
      );

      await this.channel.bindQueue(
        this.config.queues.analyticsEvents,
        this.config.exchange,
        "*.analytics"
      );

      // Connection error handlers
      this.connection.on("error", (error) => {
        console.error("[POST-RABBITMQ] Connection error:", error);
        this.handleConnectionError();
      });

      this.connection.on("close", () => {
        console.warn("[POST-RABBITMQ] Connection closed");
        this.handleConnectionError();
      });

      this.reconnectAttempts = 0;
      this.isConnecting = false;

      console.log("✅ [POST-RABBITMQ] Connected successfully");
      return true;
    } catch (error) {
      console.error("❌ [POST-RABBITMQ] Connection failed:", error.message);
      this.isConnecting = false;
      this.handleConnectionError();
      return false;
    }
  }

  async handleConnectionError() {
    this.connection = null;
    this.channel = null;
    this.isConnecting = false;

    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++;
      const delay = this.reconnectDelay * this.reconnectAttempts;

      console.log(
        `[POST-RABBITMQ] Attempting reconnection ${this.reconnectAttempts}/${this.maxReconnectAttempts} in ${delay}ms`
      );

      setTimeout(() => {
        this.connect();
      }, delay);
    }
  }

  async publishEvent(routingKey, eventType, data, options = {}) {
    try {
      if (!this.channel) {
        const connected = await this.connect();
        if (!connected) {
          throw new Error("RabbitMQ connection not available");
        }
      }

      const event = {
        id: options.id || this.generateEventId(),
        type: eventType,
        service: "post-service",
        version: "1.0.0",
        timestamp: new Date().toISOString(),
        data: data,
        metadata: {
          correlationId: options.correlationId || this.generateCorrelationId(),
          userId: options.userId,
          sessionId: options.sessionId,
          source: options.source || "post-service",
        },
      };

      const message = Buffer.from(JSON.stringify(event));

      const publishOptions = {
        persistent: true,
        mandatory: true,
        messageId: event.id,
        timestamp: Date.now(),
        correlationId: event.metadata.correlationId,
        ...options.publishOptions,
      };

      const published = this.channel.publish(
        this.config.exchange,
        routingKey,
        message,
        publishOptions
      );

      if (!published) {
        throw new Error("Failed to publish message to exchange");
      }

      console.log(
        `[🚀] [POST-RABBITMQ] Published event '${eventType}' with routing key '${routingKey}'`
      );
      return true;
    } catch (error) {
      console.error(
        `[❌] [POST-RABBITMQ] Failed to publish event '${eventType}':`,
        error.message
      );
      return false;
    }
  }

  // Post-specific event publishers
  async publishPostEvent(eventType, postData, options = {}) {
    return this.publishEvent("post.events", eventType, postData, options);
  }

  async publishSocialEvent(eventType, socialData, options = {}) {
    return this.publishEvent("social.events", eventType, socialData, options);
  }

  async publishAnalyticsEvent(eventType, analyticsData, options = {}) {
    return this.publishEvent(
      "post.analytics",
      eventType,
      analyticsData,
      options
    );
  }

  // Specific event methods for common use cases
  async publishPostCreated(postData, options = {}) {
    return this.publishPostEvent(
      "POST_CREATED",
      {
        post_id: postData.post_id,
        user_id: postData.user_id,
        content: postData.content,
        media_urls: postData.media_urls,
        event_id: postData.event_id,
        created_at: postData.created_at,
      },
      options
    );
  }

  async publishPostLiked(postData, likeData, options = {}) {
    return this.publishSocialEvent(
      "POST_LIKED",
      {
        post_id: postData.post_id,
        post_user_id: postData.user_id,
        liked_by_user_id: likeData.user_id,
        like_id: likeData.like_id,
        timestamp: likeData.created_at,
      },
      options
    );
  }

  async publishPostUnliked(postData, unlikeData, options = {}) {
    return this.publishSocialEvent(
      "POST_UNLIKED",
      {
        post_id: postData.post_id,
        post_user_id: postData.user_id,
        unliked_by_user_id: unlikeData.user_id,
        timestamp: unlikeData.timestamp,
      },
      options
    );
  }

  async publishCommentCreated(commentData, options = {}) {
    return this.publishSocialEvent(
      "COMMENT_CREATED",
      {
        comment_id: commentData.comment_id,
        post_id: commentData.post_id,
        user_id: commentData.user_id,
        content: commentData.content,
        parent_comment_id: commentData.parent_comment_id,
        created_at: commentData.created_at,
      },
      options
    );
  }

  async publishUserFollowed(followData, options = {}) {
    return this.publishSocialEvent(
      "USER_FOLLOWED",
      {
        follower_id: followData.follower_id,
        following_id: followData.following_id,
        created_at: followData.created_at,
      },
      options
    );
  }

  async publishEngagementMetrics(metricsData, options = {}) {
    return this.publishAnalyticsEvent(
      "ENGAGEMENT_METRICS",
      {
        user_id: metricsData.user_id,
        post_id: metricsData.post_id,
        engagement_type: metricsData.type, // 'like', 'comment', 'share', 'view'
        timestamp: metricsData.timestamp,
        metadata: metricsData.metadata,
      },
      options
    );
  }

  async publishFeedInteraction(interactionData, options = {}) {
    return this.publishAnalyticsEvent(
      "FEED_INTERACTION",
      {
        user_id: interactionData.user_id,
        post_id: interactionData.post_id,
        interaction_type: interactionData.type, // 'view', 'scroll_past', 'click'
        duration: interactionData.duration,
        position: interactionData.position,
        timestamp: interactionData.timestamp,
      },
      options
    );
  }

  // Utility methods
  generateEventId() {
    return `post_evt_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  generateCorrelationId() {
    return `post_corr_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  async close() {
    try {
      if (this.channel) {
        await this.channel.close();
      }
      if (this.connection) {
        await this.connection.close();
      }
      console.log("[POST-RABBITMQ] Connection closed gracefully");
    } catch (error) {
      console.error("[POST-RABBITMQ] Error closing connection:", error);
    }
  }

  async healthCheck() {
    try {
      if (!this.connection || this.connection.connection.stream.destroyed) {
        return { status: "disconnected", error: "No active connection" };
      }

      if (!this.channel) {
        return { status: "error", error: "No active channel" };
      }

      await this.channel.checkExchange(this.config.exchange);

      return {
        status: "connected",
        exchange: this.config.exchange,
        queues: Object.keys(this.config.queues).length,
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
const postRabbitMQPublisher = new PostServiceRabbitMQPublisher();

module.exports = {
  postRabbitMQPublisher,
  connectToRabbitMQ: () => postRabbitMQPublisher.connect(),
  publishPostEvent: (eventType, postData, options) =>
    postRabbitMQPublisher.publishPostEvent(eventType, postData, options),
  publishSocialEvent: (eventType, socialData, options) =>
    postRabbitMQPublisher.publishSocialEvent(eventType, socialData, options),
  publishAnalyticsEvent: (eventType, analyticsData, options) =>
    postRabbitMQPublisher.publishAnalyticsEvent(
      eventType,
      analyticsData,
      options
    ),

  // Convenience methods
  publishPostCreated: (postData, options) =>
    postRabbitMQPublisher.publishPostCreated(postData, options),
  publishPostLiked: (postData, likeData, options) =>
    postRabbitMQPublisher.publishPostLiked(postData, likeData, options),
  publishPostUnliked: (postData, unlikeData, options) =>
    postRabbitMQPublisher.publishPostUnliked(postData, unlikeData, options),
  publishCommentCreated: (commentData, options) =>
    postRabbitMQPublisher.publishCommentCreated(commentData, options),
  publishUserFollowed: (followData, options) =>
    postRabbitMQPublisher.publishUserFollowed(followData, options),
  publishEngagementMetrics: (metricsData, options) =>
    postRabbitMQPublisher.publishEngagementMetrics(metricsData, options),
  publishFeedInteraction: (interactionData, options) =>
    postRabbitMQPublisher.publishFeedInteraction(interactionData, options),

  getRabbitMQHealth: () => postRabbitMQPublisher.healthCheck(),
  closeRabbitMQ: () => postRabbitMQPublisher.close(),
};
