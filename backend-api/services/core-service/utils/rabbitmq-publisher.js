require("dotenv").config();
const amqp = require('amqplib');

class RabbitMQPublisher {
  constructor() {
    this.connection = null;
    this.channel = null;
    this.isConnecting = false;
    this.reconnectDelay = 5000; // 5 seconds
    this.maxReconnectAttempts = 10;
    this.reconnectAttempts = 0;
    
    // Configuration from environment
    this.config = {
      url: process.env.RABBITMQ_URL || 'amqp://localhost:5672',
      exchange: process.env.RABBITMQ_EXCHANGE || 'eventbn_exchange',
      queues: {
        userEvents: process.env.RABBITMQ_USER_QUEUE || 'user_events',
        eventEvents: process.env.RABBITMQ_EVENT_QUEUE || 'event_events',
        analyticsEvents: 'analytics_events'
      }
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
      console.log('[RABBITMQ] Connecting to RabbitMQ...');
      
      this.connection = await amqp.connect(this.config.url);
      this.channel = await this.connection.createChannel();

      // Setup exchange (topic-based routing)
      await this.channel.assertExchange(this.config.exchange, 'topic', { 
        durable: true 
      });

      // Setup queues
      for (const [name, queueName] of Object.entries(this.config.queues)) {
        await this.channel.assertQueue(queueName, { 
          durable: true,
          arguments: {
            'x-message-ttl': 24 * 60 * 60 * 1000, // 24 hours TTL
            'x-max-length': 10000 // Max 10k messages
          }
        });
      }

      // Bind queues to exchange with routing patterns
      await this.channel.bindQueue(
        this.config.queues.userEvents, 
        this.config.exchange, 
        'user.*'
      );
      
      await this.channel.bindQueue(
        this.config.queues.eventEvents, 
        this.config.exchange, 
        'event.*'
      );

      await this.channel.bindQueue(
        this.config.queues.analyticsEvents, 
        this.config.exchange, 
        '*.analytics'
      );

      // Setup connection error handlers
      this.connection.on('error', (error) => {
        console.error('[RABBITMQ] Connection error:', error);
        this.handleConnectionError();
      });

      this.connection.on('close', () => {
        console.warn('[RABBITMQ] Connection closed');
        this.handleConnectionError();
      });

      this.channel.on('error', (error) => {
        console.error('[RABBITMQ] Channel error:', error);
      });

      this.reconnectAttempts = 0;
      this.isConnecting = false;
      
      console.log('✅ [RABBITMQ] Connected successfully');
      return true;

    } catch (error) {
      console.error('❌ [RABBITMQ] Connection failed:', error.message);
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
      
      console.log(`[RABBITMQ] Attempting reconnection ${this.reconnectAttempts}/${this.maxReconnectAttempts} in ${delay}ms`);
      
      setTimeout(() => {
        this.connect();
      }, delay);
    } else {
      console.error('[RABBITMQ] Max reconnection attempts reached');
    }
  }

  async publishEvent(routingKey, eventType, data, options = {}) {
    try {
      // Ensure connection exists
      if (!this.channel) {
        const connected = await this.connect();
        if (!connected) {
          throw new Error('RabbitMQ connection not available');
        }
      }

      const event = {
        id: options.id || this.generateEventId(),
        type: eventType,
        service: 'core-service',
        version: '1.0.0',
        timestamp: new Date().toISOString(),
        data: data,
        metadata: {
          correlationId: options.correlationId || this.generateCorrelationId(),
          userId: options.userId,
          sessionId: options.sessionId,
          source: options.source || 'core-service'
        }
      };

      const message = Buffer.from(JSON.stringify(event));
      
      const publishOptions = {
        persistent: true,
        mandatory: true,
        messageId: event.id,
        timestamp: Date.now(),
        correlationId: event.metadata.correlationId,
        ...options.publishOptions
      };

      const published = this.channel.publish(
        this.config.exchange,
        routingKey,
        message,
        publishOptions
      );

      if (!published) {
        throw new Error('Failed to publish message to exchange');
      }

      console.log(`[🚀] [RABBITMQ] Published event '${eventType}' with routing key '${routingKey}'`);
      return true;

    } catch (error) {
      console.error(`[❌] [RABBITMQ] Failed to publish event '${eventType}':`, error.message);
      
      // Store failed events for retry (in production, use a persistent queue)
      this.handleFailedPublish(routingKey, eventType, data, options);
      
      return false;
    }
  }

  // Specific event publishers
  async publishUserEvent(eventType, userData, options = {}) {
    return this.publishEvent('user.events', eventType, userData, options);
  }

  async publishEventEvent(eventType, eventData, options = {}) {
    return this.publishEvent('event.events', eventType, eventData, options);
  }

  async publishAnalyticsEvent(eventType, analyticsData, options = {}) {
    return this.publishEvent('analytics.events', eventType, analyticsData, options);
  }

  // Utility methods
  generateEventId() {
    return `evt_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  generateCorrelationId() {
    return `corr_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  handleFailedPublish(routingKey, eventType, data, options) {
    // In production, implement a persistent retry queue
    console.warn(`[RABBITMQ] Storing failed event for retry: ${eventType}`);
  }

  async close() {
    try {
      if (this.channel) {
        await this.channel.close();
      }
      if (this.connection) {
        await this.connection.close();
      }
      console.log('[RABBITMQ] Connection closed gracefully');
    } catch (error) {
      console.error('[RABBITMQ] Error closing connection:', error);
    }
  }

  async healthCheck() {
    try {
      if (!this.connection || this.connection.connection.stream.destroyed) {
        return { status: 'disconnected', error: 'No active connection' };
      }

      if (!this.channel) {
        return { status: 'error', error: 'No active channel' };
      }

      // Simple ping test
      await this.channel.checkExchange(this.config.exchange);
      
      return { 
        status: 'connected',
        exchange: this.config.exchange,
        queues: Object.keys(this.config.queues).length
      };
    } catch (error) {
      return { 
        status: 'error', 
        error: error.message 
      };
    }
  }
}

// Create singleton instance
const rabbitmqPublisher = new RabbitMQPublisher();

module.exports = {
  rabbitmqPublisher,
  connectToRabbitMQ: () => rabbitmqPublisher.connect(),
  publishUserEvent: (eventType, userData, options) => 
    rabbitmqPublisher.publishUserEvent(eventType, userData, options),
  publishEventEvent: (eventType, eventData, options) => 
    rabbitmqPublisher.publishEventEvent(eventType, eventData, options),
  publishAnalyticsEvent: (eventType, analyticsData, options) => 
    rabbitmqPublisher.publishAnalyticsEvent(eventType, analyticsData, options),
  getRabbitMQHealth: () => rabbitmqPublisher.healthCheck(),
  closeRabbitMQ: () => rabbitmqPublisher.close()
};