// Core Service - Monolithic service containing all core event management features
// This service can run as a standalone monolithic application or as a microservice

const auth = require('./auth');
const users = require('./users');
const organizations = require('./organizations');
const events = require('./events');
const tickets = require('./tickets');

class CoreService {
  constructor() {
    this.auth = auth;
    this.users = users;
    this.organizations = organizations;
    this.events = events;
    this.tickets = tickets;
  }

  // Health check
  async healthCheck() {
    return {
      service: 'core-service',
      status: 'healthy',
      timestamp: new Date().toISOString(),
      version: '1.0.0',
    };
  }

  // Initialize service
  async initialize() {
    try {
      // Any initialization logic here
      console.log('Core Service initialized successfully');
      return true;
    } catch (error) {
      console.error('Core Service initialization failed:', error);
      return false;
    }
  }
}

module.exports = new CoreService();
