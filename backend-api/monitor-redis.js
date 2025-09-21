#!/usr/bin/env node

/**
 * Redis Seat Lock Monitor
 * 
 * This script helps monitor Redis seat locks in real-time during testing.
 * Shows current locks, TTL values, and queue status.
 */

const { getRedisClient } = require('./lib/redis');

const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

async function monitorRedisLocks() {
  try {
    const redis = getRedisClient();
    
    // Clear screen
    console.clear();
    
    log('🔍 Redis Seat Lock Monitor', 'cyan');
    log('=' .repeat(60), 'cyan');
    log(`📅 ${new Date().toLocaleString()}`, 'yellow');
    
    // Get all seat locks
    log('\n🔒 Current Seat Locks:', 'bright');
    const lockKeys = await redis.keys('seat_lock:*');
    
    if (lockKeys.length === 0) {
      log('   No active seat locks', 'yellow');
    } else {
      for (const key of lockKeys) {
        const ttl = await redis.ttl(key);
        const value = await redis.get(key);
        
        // Parse key: seat_lock:eventId:seatId
        const [, eventId, seatId] = key.split(':');
        const [userId, timestamp] = value ? value.split(':') : ['unknown', 'unknown'];
        
        const ttlColor = ttl > 60 ? 'green' : ttl > 30 ? 'yellow' : 'red';
        const ttlText = ttl > 0 ? `${ttl}s` : 'EXPIRED';
        
        log(`   🎪 ${eventId} | 💺 ${seatId} | 👤 ${userId} | ⏰ ${ttlText}`, ttlColor);
      }
    }
    
    // Get all queues
    log('\n📋 Current Queues:', 'bright');
    const queueKeys = await redis.keys('seat_lock_queue:*');
    
    if (queueKeys.length === 0) {
      log('   No active queues', 'yellow');
    } else {
      for (const queueKey of queueKeys) {
        const queueLength = await redis.llen(queueKey);
        const eventId = queueKey.split(':')[1];
        
        if (queueLength > 0) {
          log(`   🎪 ${eventId} | 📊 ${queueLength} queued requests`, 'magenta');
          
          // Show first few items in queue
          const items = await redis.lrange(queueKey, 0, 2);
          items.forEach((item, index) => {
            try {
              const parsed = JSON.parse(item);
              log(`      ${index + 1}. ${parsed.action} seat ${parsed.seatId} by ${parsed.userId}`, 'cyan');
            } catch (e) {
              log(`      ${index + 1}. ${item}`, 'cyan');
            }
          });
          
          if (queueLength > 3) {
            log(`      ... and ${queueLength - 3} more`, 'cyan');
          }
        }
      }
    }
    
    // Get queue results
    log('\n📤 Recent Queue Results:', 'bright');
    const resultKeys = await redis.keys('queue_result:*');
    
    if (resultKeys.length === 0) {
      log('   No recent results', 'yellow');
    } else {
      // Show only first 5 results
      const recentResults = resultKeys.slice(0, 5);
      for (const resultKey of recentResults) {
        const ttl = await redis.ttl(resultKey);
        const result = await redis.get(resultKey);
        
        if (result) {
          try {
            const parsed = JSON.parse(result);
            const requestId = resultKey.split(':')[1].substring(0, 8) + '...';
            const status = parsed.success ? '✅' : '❌';
            log(`   📝 ${requestId} | ${status} ${parsed.action} | ⏰ ${ttl}s TTL`, 'blue');
          } catch (e) {
            log(`   📝 ${resultKey} | ⏰ ${ttl}s TTL`, 'blue');
          }
        }
      }
    }
    
    // Show Redis connection status
    log('\n🔌 Redis Status:', 'bright');
    const ping = await redis.ping();
    log(`   Connection: ${ping === 'PONG' ? '✅ Connected' : '❌ Disconnected'}`, 'green');
    
    // Show memory usage
    const info = await redis.info('memory');
    const memoryMatch = info.match(/used_memory_human:([^\r\n]+)/);
    if (memoryMatch) {
      log(`   Memory Usage: ${memoryMatch[1]}`, 'blue');
    }
    
    log('\n💡 Commands:', 'bright');
    log('   Press Ctrl+C to exit', 'yellow');
    log('   Refresh every 3 seconds...', 'yellow');
    
  } catch (error) {
    log(`❌ Monitor error: ${error.message}`, 'red');
    
    if (error.code === 'ECONNREFUSED') {
      log('   Redis server not running. Start with: redis-server', 'yellow');
    }
  }
}

async function clearAllLocks() {
  try {
    const redis = getRedisClient();
    
    log('🧹 Clearing all seat locks and queues...', 'yellow');
    
    // Clear all locks
    const lockKeys = await redis.keys('seat_lock:*');
    if (lockKeys.length > 0) {
      await redis.del(...lockKeys);
      log(`   Cleared ${lockKeys.length} seat locks`, 'green');
    }
    
    // Clear all queues
    const queueKeys = await redis.keys('seat_lock_queue:*');
    if (queueKeys.length > 0) {
      await redis.del(...queueKeys);
      log(`   Cleared ${queueKeys.length} queues`, 'green');
    }
    
    // Clear all results
    const resultKeys = await redis.keys('queue_result:*');
    if (resultKeys.length > 0) {
      await redis.del(...resultKeys);
      log(`   Cleared ${resultKeys.length} results`, 'green');
    }
    
    log('✅ All seat locks cleared!', 'green');
    
  } catch (error) {
    log(`❌ Clear error: ${error.message}`, 'red');
  }
}

// Command line arguments
const args = process.argv.slice(2);

if (args.includes('--clear')) {
  clearAllLocks().then(() => process.exit(0));
} else if (args.includes('--once')) {
  monitorRedisLocks().then(() => process.exit(0));
} else {
  // Continuous monitoring
  log('🔍 Starting Redis Seat Lock Monitor...', 'cyan');
  log('   Use --clear to clear all locks', 'yellow');
  log('   Use --once for single check', 'yellow');
  log('   Press Ctrl+C to exit\n', 'yellow');
  
  // Monitor every 3 seconds
  const interval = setInterval(monitorRedisLocks, 3000);
  
  // Initial run
  monitorRedisLocks();
  
  // Handle Ctrl+C
  process.on('SIGINT', () => {
    clearInterval(interval);
    log('\n👋 Monitor stopped', 'cyan');
    process.exit(0);
  });
}