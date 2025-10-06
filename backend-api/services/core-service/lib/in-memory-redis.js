// In-memory Redis fallback for development
class InMemoryRedis {
  constructor() {
    this.data = new Map();
    this.timers = new Map();
    this.lists = new Map(); // For list operations
    this.counters = new Map(); // For incr/decr operations
  }

  async connect() {
    console.log('✅ Connected to In-Memory Redis (Development Mode)');
  }

  // SET command with options (NX, EX, XX)
  async set(key, value, options = {}) {
    // Handle NX (only if not exists)
    if (options.NX && this.data.has(key)) {
      return null; // Key exists, cannot set
    }
    
    // Handle XX (only if exists)  
    if (options.XX && !this.data.has(key)) {
      return null; // Key doesn't exist, cannot set
    }
    
    this.data.set(key, value);
    
    // Handle EX (expiration in seconds)
    if (options.EX) {
      this._setExpiration(key, options.EX);
    }
    
    return 'OK';
  }

  // SETEX command (for backwards compatibility)
  async setEx(key, seconds, value) {
    this.data.set(key, value);
    this._setExpiration(key, seconds);
    return 'OK';
  }

  // Helper method to set expiration
  _setExpiration(key, seconds) {
    if (this.timers.has(key)) {
      clearTimeout(this.timers.get(key));
    }
    
    const timer = setTimeout(() => {
      this.data.delete(key);
      this.timers.delete(key);
    }, seconds * 1000);
    
    this.timers.set(key, timer);
  }

  // EXPIRE command
  async expire(key, seconds) {
    if (!this.data.has(key)) {
      return 0; // Key doesn't exist
    }
    
    this._setExpiration(key, seconds);
    return 1;
  }

  // GET command
  async get(key) {
    return this.data.get(key) || null;
  }

  // DEL command
  async del(key) {
    const existed = this.data.has(key);
    this.data.delete(key);
    
    if (this.timers.has(key)) {
      clearTimeout(this.timers.get(key));
      this.timers.delete(key);
    }
    
    return existed ? 1 : 0;
  }

  // TTL command
  async ttl(key) {
    if (!this.data.has(key)) {
      return -2; // Key doesn't exist
    }
    
    if (!this.timers.has(key)) {
      return -1; // Key exists but has no expiration
    }
    
    // Simplified - return a reasonable TTL value
    return 300; // 5 minutes default
  }

  // INCR command
  async incr(key) {
    const current = this.counters.get(key) || 0;
    const newValue = current + 1;
    this.counters.set(key, newValue);
    return newValue;
  }

  // DECR command
  async decr(key) {
    const current = this.counters.get(key) || 0;
    const newValue = current - 1;
    this.counters.set(key, newValue);
    return newValue;
  }

  // KEYS command
  async keys(pattern) {
    const regex = new RegExp(pattern.replace(/\*/g, '.*'));
    return Array.from(this.data.keys()).filter(key => regex.test(key));
  }

  // LIST OPERATIONS for queue functionality (Redis v4+ API)

  // LPUSH command (push to left/head of list)
  async lPush(key, ...values) {
    if (!this.lists.has(key)) {
      this.lists.set(key, []);
    }
    const list = this.lists.get(key);
    list.unshift(...values.reverse()); // Add to beginning
    return list.length;
  }

  // RPUSH command (push to right/tail of list)
  async rPush(key, ...values) {
    if (!this.lists.has(key)) {
      this.lists.set(key, []);
    }
    const list = this.lists.get(key);
    list.push(...values); // Add to end
    return list.length;
  }

  // LPOP command (pop from left/head of list)
  async lPop(key) {
    if (!this.lists.has(key)) {
      return null;
    }
    const list = this.lists.get(key);
    if (list.length === 0) {
      return null;
    }
    const value = list.shift();
    if (list.length === 0) {
      this.lists.delete(key);
    }
    return value;
  }

  // RPOP command (pop from right/tail of list)
  async rPop(key) {
    if (!this.lists.has(key)) {
      return null;
    }
    const list = this.lists.get(key);
    if (list.length === 0) {
      return null;
    }
    const value = list.pop();
    if (list.length === 0) {
      this.lists.delete(key);
    }
    return value;
  }

  // LLEN command (get list length)
  async lLen(key) {
    if (!this.lists.has(key)) {
      return 0;
    }
    return this.lists.get(key).length;
  }

  // BRPOP command (blocking right pop) - simplified non-blocking version
  async brPop(key, timeout) {
    const value = await this.rPop(key);
    if (value !== null) {
      return { key: key, element: value }; // Redis v4+ format
    }
    return null; // Simplified - no actual blocking
  }

  // BLPOP command (blocking left pop) - simplified non-blocking version  
  async blPop(key, timeout) {
    const value = await this.lPop(key);
    if (value !== null) {
      return { key: key, element: value }; // Redis v4+ format
    }
    return null; // Simplified - no actual blocking
  }

  // Clean up method
  async quit() {
    // Clear all timers
    for (const timer of this.timers.values()) {
      clearTimeout(timer);
    }
    this.data.clear();
    this.timers.clear();
    this.lists.clear();
    this.counters.clear();
    console.log('✅ In-Memory Redis connection closed');
  }

  // Mock event handlers
  on(event, callback) {
    if (event === 'error') {
      // Store error handler if needed
    }
  }
}

module.exports = InMemoryRedis;
