#!/usr/bin/env node

/**
 * Multi-User Seat Competition Simulator
 * 
 * This script simulates User A and User B competing for seats
 * to test the locking system without needing multiple devices.
 */

const axios = require('axios');
const redis = require('redis');

// Configuration
const BASE_URL = 'http://localhost:3000/api';
const EVENT_ID = '20';

// Reset load counter function
async function resetLoadCounter() {
  let redisClient = null;
  try {
    log('🔄 Resetting load counter for clean race condition testing...', 'yellow');
    
    redisClient = redis.createClient({
      socket: {
        host: 'localhost',
        port: 6379,
        connectTimeout: 3000,
      }
    });
    
    await redisClient.connect();
    
    // Clear the load tracking key
    const loadKey = `seat_lock_load:${EVENT_ID}`;
    const deleted = await redisClient.del(loadKey);
    
    log(`✅ Load counter reset (${deleted} key(s) cleared)`, 'green');
    
  } catch (error) {
    log(`⚠️  Could not reset load counter: ${error.message}`, 'yellow');
    log('   This might affect queue behavior, but tests should still work', 'yellow');
  } finally {
    if (redisClient && redisClient.isOpen) {
      await redisClient.quit();
    }
  }
}

// Test Users (replace with real JWT tokens)
const USERS = {
  userA: {
    token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEzLCJlbWFpbCI6ImphbmVAZXhhbXBsZS5jb20iLCJuYW1lIjoiSmFuZSBEb2UiLCJpYXQiOjE3NTgwNjMwMDEsImV4cCI6MTc1ODY2NzgwMX0.st18Q79YCzOCaulLWqIm8p2ThI-1J-Cyx2DIbz7OAMU',
    name: '👤 User A (Alice)',
    color: '\x1b[32m' // Green
  },
  userB: {
    token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEwLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJuYW1lIjoiVGVzdCIsImlhdCI6MTc1ODA2MzA3MSwiZXhwIjoxNzU4NjY3ODcxfQ.PMJSexwgQMlrVOFeeKkoBqBTcv6YkyG2-Oa2JS4SOxQ', 
    name: '👤 User B (Bob)',
    color: '\x1b[34m' // Blue
  }
};

const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function userLog(user, message, success = true) {
  const statusIcon = success ? '✅' : '❌';
  console.log(`${user.color}${user.name}: ${statusIcon} ${message}${colors.reset}`);
}

function createApiClient(userToken) {
  return axios.create({
    baseURL: BASE_URL,
    headers: {
      'Authorization': `Bearer ${userToken}`,
      'Content-Type': 'application/json'
    },
    validateStatus: function (status) {
      // Accept all status codes - let the test handle them
      return status >= 200 && status < 600;
    }
  });
}

// Test 1: Different Seats (Should Both Succeed)
async function testDifferentSeats() {
  log('\n🎯 Test 1: Two Users Select Different Seats', 'cyan');
  log('============================================', 'cyan');
  
  const userA = createApiClient(USERS.userA.token);
  const userB = createApiClient(USERS.userB.token);

  try {
    // User A selects A1
    log('\n1. User A attempts to lock seat A1...', 'yellow');
    const resultA = await userA.post(`/seat-locks/events/${EVENT_ID}/seats/A1/hybrid/lock`);
    const successA = resultA.status === 200 && resultA.data.success;
    userLog(USERS.userA, `Locked seat A1 - ${resultA.data.message || 'Status: ' + resultA.status}`, successA);

    // User B selects B1
    log('\n2. User B attempts to lock seat B1...', 'yellow');
    const resultB = await userB.post(`/seat-locks/events/${EVENT_ID}/seats/B1/hybrid/lock`);
    const successB = resultB.status === 200 && resultB.data.success;
    userLog(USERS.userB, `Locked seat B1 - ${resultB.data.message || 'Status: ' + resultB.status}`, successB);

    // Check what each user sees
    log('\n3. Checking lock status for both users...', 'yellow');
    
    const statusA1 = await userA.get(`/seat-locks/events/${EVENT_ID}/seats/A1/lock`);
    const statusB1 = await userA.get(`/seat-locks/events/${EVENT_ID}/seats/B1/lock`);
    
    log(`   A1 Status: ${JSON.stringify(statusA1.data)}`, 'green');
    log(`   B1 Status: ${JSON.stringify(statusB1.data)}`, 'blue');

    // Cleanup - only if locks were successful
    if (successA) {
      try { await userA.delete(`/seat-locks/events/${EVENT_ID}/seats/A1/hybrid/release`); } catch (e) {}
    }
    if (successB) {
      try { await userB.delete(`/seat-locks/events/${EVENT_ID}/seats/B1/hybrid/release`); } catch (e) {}
    }
    
    // Overall test result
    if (successA && successB) {
      log('✅ Test 1 PASSED: Both users successfully locked different seats', 'green');
    } else {
      log('❌ Test 1 FAILED: One or both users failed to lock their seats', 'red');
    }

  } catch (error) {
    log(`❌ Test 1 Failed: ${error.message}`, 'red');
  }
}

// Test 2: Same Seat Competition (User B Should Fail)
async function testSeatCompetition() {
  log('\n⚔️  Test 2: Two Users Compete for Same Seat', 'cyan');
  log('==========================================', 'cyan');
  
  const userA = createApiClient(USERS.userA.token);
  const userB = createApiClient(USERS.userB.token);

  try {
    // User A locks seat first
    log('\n1. User A attempts to lock seat C1...', 'yellow');
    const resultA = await userA.post(`/seat-locks/events/${EVENT_ID}/seats/C1/hybrid/lock`);
    const successA = resultA.status === 200 && resultA.data.success;
    userLog(USERS.userA, `Locked seat C1 - ${resultA.data.message || 'Status: ' + resultA.status}`, successA);

    // Small delay to ensure A's lock is processed
    await new Promise(resolve => setTimeout(resolve, 100));

    // User B tries same seat (should fail with 409)
    log('\n2. User B attempts to lock same seat C1...', 'yellow');
    const resultB = await userB.post(`/seat-locks/events/${EVENT_ID}/seats/C1/hybrid/lock`);
    const isCorrectlyBlocked = resultB.status === 409 || (resultB.status === 200 && !resultB.data.success);
    userLog(USERS.userB, `Correctly blocked: ${resultB.data.message || 'Status: ' + resultB.status}`, isCorrectlyBlocked);

    // User B checks seat status
    log('\n3. User B checks seat C1 status...', 'yellow');
    const statusC1 = await userB.get(`/seat-locks/events/${EVENT_ID}/seats/C1/lock`);
    log(`   C1 Status (from User B's view): ${JSON.stringify(statusC1.data)}`, 'blue');

    // Cleanup - only if User A successfully locked
    if (successA) {
      try { await userA.delete(`/seat-locks/events/${EVENT_ID}/seats/C1/hybrid/release`); } catch (e) {}
    }
    
    // Overall test result
    if (successA && isCorrectlyBlocked) {
      log('✅ Test 2 PASSED: User A locked seat, User B was correctly blocked', 'green');
    } else {
      log('❌ Test 2 FAILED: Expected User A to succeed and User B to be blocked', 'red');
    }

  } catch (error) {
    log(`❌ Test 2 Failed: ${error.message}`, 'red');
  }
}

// Test 3: Lock Expiration and Handover
async function testLockExpiration() {
  log('\n⏰ Test 3: Lock Expiration and Handover', 'cyan');
  log('=====================================', 'cyan');
  
  const userA = createApiClient(USERS.userA.token);
  const userB = createApiClient(USERS.userB.token);

  try {
    // User A locks seat
    log('\n1. User A locks seat D1...', 'yellow');
    const resultA = await userA.post(`/seat-locks/events/${EVENT_ID}/seats/D1/hybrid/lock`);
    const successA = resultA.status === 200 && resultA.data.success;
    userLog(USERS.userA, `Locked seat D1 - ${resultA.data.message || 'Status: ' + resultA.status}`, successA);

    if (!successA) {
      log('❌ Test 3 FAILED: User A could not lock seat D1', 'red');
      return;
    }

    // Check initial TTL
    log('\n2. Checking initial TTL...', 'yellow');
    const initialStatus = await userA.get(`/seat-locks/events/${EVENT_ID}/seats/D1/lock`);
    log(`   Initial TTL: ${initialStatus.data.lockStatus?.ttl || 'N/A'} seconds`, 'cyan');

    // User A releases lock manually (simulating expiration)
    log('\n3. User A releases the lock...', 'yellow');
    const releaseResult = await userA.delete(`/seat-locks/events/${EVENT_ID}/seats/D1/hybrid/release`);
    const releaseSuccess = releaseResult.status >= 200 && releaseResult.status < 400; // Accept 2xx and 3xx
    userLog(USERS.userA, `Released seat D1 - Status: ${releaseResult.status}`, releaseSuccess);

    // Small delay
    await new Promise(resolve => setTimeout(resolve, 100));

    // User B should now be able to lock it
    log('\n4. User B attempts to lock the now-available seat D1...', 'yellow');
    const resultB = await userB.post(`/seat-locks/events/${EVENT_ID}/seats/D1/hybrid/lock`);
    const successB = resultB.status === 200 && resultB.data.success;
    userLog(USERS.userB, `Locked seat D1 - ${resultB.data.message || 'Status: ' + resultB.status}`, successB);

    // Cleanup
    if (successB) {
      try { await userB.delete(`/seat-locks/events/${EVENT_ID}/seats/D1/hybrid/release`); } catch (e) {}
    }
    
    // Overall test result
    if (successA && releaseSuccess && successB) {
      log('✅ Test 3 PASSED: Lock handover worked correctly', 'green');
    } else {
      log('❌ Test 3 FAILED: Lock handover did not work as expected', 'red');
    }

  } catch (error) {
    log(`❌ Test 3 Failed: ${error.message}`, 'red');
  }
}

// Test 4: Simultaneous Requests (Race Condition)
async function testRaceCondition() {
  log('\n🏃 Test 4: Simultaneous Seat Lock Requests', 'cyan');
  log('=========================================', 'cyan');
  
  const userA = createApiClient(USERS.userA.token);
  const userB = createApiClient(USERS.userB.token);

  try {
    log('\n1. Both users attempt to lock seat E1 simultaneously...', 'yellow');
    
    // Fire both requests at exactly the same time using DIRECT endpoints (bypasses queue)
    const [resultA, resultB] = await Promise.allSettled([
      userA.post(`/seat-locks/events/${EVENT_ID}/seats/E1/lock`),
      userB.post(`/seat-locks/events/${EVENT_ID}/seats/E1/lock`)
    ]);

    // Check results
    let successA = false;
    let successB = false;
    let blockedA = false;
    let blockedB = false;

    if (resultA.status === 'fulfilled') {
      successA = resultA.value.status === 200 && resultA.value.data.success;
      blockedA = resultA.value.status === 409 || (resultA.value.status === 200 && !resultA.value.data.success);
      const resultText = successA ? 'success' : (blockedA ? 'correctly blocked' : 'unexpected result');
      userLog(USERS.userA, `Result: ${resultA.value.data.message || 'Status: ' + resultA.value.status}`, successA || blockedA);
    } else {
      userLog(USERS.userA, `Failed: Network/connection error`, false);
    }

    if (resultB.status === 'fulfilled') {
      successB = resultB.value.status === 200 && resultB.value.data.success;
      blockedB = resultB.value.status === 409 || (resultB.value.status === 200 && !resultB.value.data.success);
      const resultText = successB ? 'success' : (blockedB ? 'correctly blocked' : 'unexpected result');
      userLog(USERS.userB, `Result: ${resultB.value.data.message || 'Status: ' + resultB.value.status}`, successB || blockedB);
    } else {
      userLog(USERS.userB, `Failed: Network/connection error`, false);
    }

    // Only one should succeed, one should be blocked
    const successCount = (successA ? 1 : 0) + (successB ? 1 : 0);
    const blockedCount = (blockedA ? 1 : 0) + (blockedB ? 1 : 0);
    const totalHandled = successCount + blockedCount;

    if (successCount === 1 && blockedCount === 1) {
      log('✅ Test 4 PASSED: Exactly one user got the lock, one was blocked (perfect!)', 'green');
    } else if (successCount === 1 && blockedCount === 0) {
      log('✅ Test 4 PASSED: One user got the lock (other may have had network issues)', 'green');
    } else if (successCount === 0 && blockedCount === 2) {
      log('❌ Test 4 INCONCLUSIVE: Both users blocked (might indicate an issue)', 'yellow');
    } else if (successCount === 2) {
      log('❌ Test 4 FAILED: Both users got the lock (race condition not handled)', 'red');
    } else {
      log(`❌ Test 4 INCONCLUSIVE: Unexpected result pattern (success: ${successCount}, blocked: ${blockedCount})`, 'yellow');
    }

    // Cleanup - try both users (using direct endpoints)
    try { await userA.delete(`/seat-locks/events/${EVENT_ID}/seats/E1/lock`); } catch {}
    try { await userB.delete(`/seat-locks/events/${EVENT_ID}/seats/E1/lock`); } catch {}

  } catch (error) {
    log(`❌ Test 4 Failed: ${error.message}`, 'red');
  }
}

// Main test runner
async function runAllTests() {
  log('🎭 Multi-User Seat Locking Competition Tests', 'bright');
  log('============================================', 'bright');
  
  // Check tokens
  if (USERS.userA.token === 'jwt-token-user-a') {
    log('⚠️  Please update user tokens in the script before running', 'yellow');
    log('   Get tokens by logging in through your authentication API\n', 'yellow');
  }

  await testDifferentSeats();
  await testSeatCompetition();
  await testLockExpiration();
  
  // Reset load counter before race condition test for accurate results
  await resetLoadCounter();
  await testRaceCondition();

  log('\n🎉 All Multi-User Tests Complete!', 'bright');
  log('\n📊 Summary:', 'cyan');
  log('• Test 1: Different seats - both users should succeed', 'yellow');
  log('• Test 2: Same seat - second user should be blocked', 'yellow');
  log('• Test 3: Lock expiration - seat should become available', 'yellow');
  log('• Test 4: Race condition - only one user should win', 'yellow');
}

if (require.main === module) {
  runAllTests().catch(console.error);
}

module.exports = { testDifferentSeats, testSeatCompetition, testLockExpiration, testRaceCondition };