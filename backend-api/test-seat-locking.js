#!/usr/bin/env node

/**
 * EventBn Seat Locking System - Automated Testing Script
 * 
 * This script helps automate API testing for the seat locking system.
 * Run different test scenarios to verify the Redis-based locking works correctly.
 */

const axios = require('axios');
const readline = require('readline');

// Configuration
const BASE_URL = 'http://localhost:3000/api';
const EVENT_ID = 'test-concert-123';

// Test user tokens (replace with real JWT tokens)
const TEST_USERS = {
  userA: 'your-jwt-token-user-a',
  userB: 'your-jwt-token-user-b'
};

// Colors for console output
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

function createApiClient(userToken) {
  return axios.create({
    baseURL: BASE_URL,
    headers: {
      'Authorization': `Bearer ${userToken}`,
      'Content-Type': 'application/json'
    }
  });
}

// Test 1: Basic Seat Lock Testing
async function testBasicSeatLocking() {
  log('\n🧪 Test 1: Basic Seat Locking', 'cyan');
  log('=====================================', 'cyan');

  const userA = createApiClient(TEST_USERS.userA);
  
  try {
    // Test 1.1: Lock a seat
    log('\n1.1 Testing seat lock...', 'blue');
    const lockResponse = await userA.post(`/seat-locks/events/${EVENT_ID}/seats/A1/hybrid/lock`);
    log(`✅ Lock Result: ${JSON.stringify(lockResponse.data, null, 2)}`, 'green');

    // Test 1.2: Check lock status
    log('\n1.2 Checking lock status...', 'blue');
    const statusResponse = await userA.get(`/seat-locks/events/${EVENT_ID}/seats/A1/lock`);
    log(`📊 Status: ${JSON.stringify(statusResponse.data, null, 2)}`, 'yellow');

    // Test 1.3: Try to lock same seat (should fail)
    log('\n1.3 Testing duplicate lock (should fail)...', 'blue');
    try {
      const duplicateResponse = await userA.post(`/seat-locks/events/${EVENT_ID}/seats/A1/hybrid/lock`);
      log(`❌ Unexpected success: ${JSON.stringify(duplicateResponse.data)}`, 'red');
    } catch (error) {
      log(`✅ Correctly failed: ${error.response?.status} - ${error.response?.data?.message}`, 'green');
    }

    // Test 1.4: Release lock
    log('\n1.4 Releasing lock...', 'blue');
    const releaseResponse = await userA.delete(`/seat-locks/events/${EVENT_ID}/seats/A1/hybrid/release`);
    log(`🔓 Release Result: ${JSON.stringify(releaseResponse.data, null, 2)}`, 'green');

  } catch (error) {
    log(`❌ Test failed: ${error.message}`, 'red');
    if (error.response) {
      log(`Response: ${JSON.stringify(error.response.data)}`, 'red');
    }
  }
}

// Test 2: Multi-User Competition
async function testMultiUserCompetition() {
  log('\n🤝 Test 2: Multi-User Competition', 'cyan');
  log('=====================================', 'cyan');

  const userA = createApiClient(TEST_USERS.userA);
  const userB = createApiClient(TEST_USERS.userB);

  try {
    // Test 2.1: User A locks seat
    log('\n2.1 User A locks seat A1...', 'blue');
    const lockA = await userA.post(`/seat-locks/events/${EVENT_ID}/seats/A1/hybrid/lock`);
    log(`👤 User A: ${JSON.stringify(lockA.data, null, 2)}`, 'green');

    // Test 2.2: User B tries to lock same seat
    log('\n2.2 User B tries to lock same seat (should fail)...', 'blue');
    try {
      const lockB = await userB.post(`/seat-locks/events/${EVENT_ID}/seats/A1/hybrid/lock`);
      log(`❌ User B unexpectedly succeeded: ${JSON.stringify(lockB.data)}`, 'red');
    } catch (error) {
      log(`✅ User B correctly blocked: ${error.response?.status} - ${error.response?.data?.message}`, 'green');
    }

    // Test 2.3: User B locks different seat
    log('\n2.3 User B locks different seat (B1)...', 'blue');
    const lockB2 = await userB.post(`/seat-locks/events/${EVENT_ID}/seats/B1/hybrid/lock`);
    log(`👤 User B: ${JSON.stringify(lockB2.data, null, 2)}`, 'green');

    // Test 2.4: Check all event locks
    log('\n2.4 Getting all event locks...', 'blue');
    const allLocks = await userA.get(`/seat-locks/events/${EVENT_ID}/locks`);
    log(`📋 All Locks: ${JSON.stringify(allLocks.data, null, 2)}`, 'yellow');

    // Cleanup
    log('\n2.5 Cleaning up...', 'blue');
    await userA.delete(`/seat-locks/events/${EVENT_ID}/seats/A1/hybrid/release`);
    await userB.delete(`/seat-locks/events/${EVENT_ID}/seats/B1/hybrid/release`);
    log('🧹 Cleanup completed', 'green');

  } catch (error) {
    log(`❌ Multi-user test failed: ${error.message}`, 'red');
  }
}

// Test 3: Queue System Testing
async function testQueueSystem() {
  log('\n🚀 Test 3: Queue System', 'cyan');
  log('=====================================', 'cyan');

  const userA = createApiClient(TEST_USERS.userA);

  try {
    // Test 3.1: Check queue stats
    log('\n3.1 Checking queue statistics...', 'blue');
    const stats = await axios.get(`${BASE_URL}/seat-locks/events/${EVENT_ID}/hybrid/stats`);
    log(`📊 Queue Stats: ${JSON.stringify(stats.data, null, 2)}`, 'yellow');

    // Test 3.2: Force queue mode by rapid requests
    log('\n3.2 Testing queue with multiple rapid requests...', 'blue');
    const seatIds = ['C1', 'C2', 'C3', 'C4', 'C5'];
    const promises = seatIds.map(async (seatId, index) => {
      try {
        log(`   Requesting seat ${seatId}...`, 'blue');
        const response = await userA.post(`/seat-locks/events/${EVENT_ID}/seats/${seatId}/hybrid/lock`);
        return { seatId, success: true, data: response.data };
      } catch (error) {
        return { seatId, success: false, error: error.response?.data };
      }
    });

    const results = await Promise.all(promises);
    
    results.forEach(result => {
      if (result.success) {
        if (result.data.queued) {
          log(`✅ ${result.seatId}: Queued (${result.data.requestId})`, 'yellow');
        } else {
          log(`✅ ${result.seatId}: Direct processing`, 'green');
        }
      } else {
        log(`❌ ${result.seatId}: Failed - ${result.error?.message}`, 'red');
      }
    });

    // Test 3.3: Check updated queue stats
    log('\n3.3 Checking updated queue statistics...', 'blue');
    const updatedStats = await axios.get(`${BASE_URL}/seat-locks/events/${EVENT_ID}/hybrid/stats`);
    log(`📊 Updated Stats: ${JSON.stringify(updatedStats.data, null, 2)}`, 'yellow');

    // Cleanup
    log('\n3.4 Cleaning up seats...', 'blue');
    for (const seatId of seatIds) {
      try {
        await userA.delete(`/seat-locks/events/${EVENT_ID}/seats/${seatId}/hybrid/release`);
      } catch (error) {
        // Ignore cleanup errors
      }
    }
    log('🧹 Queue test cleanup completed', 'green');

  } catch (error) {
    log(`❌ Queue test failed: ${error.message}`, 'red');
  }
}

// Test 4: Timer and TTL Testing
async function testTimerTTL() {
  log('\n⏱️  Test 4: Timer & TTL Testing', 'cyan');
  log('=====================================', 'cyan');

  const userA = createApiClient(TEST_USERS.userA);

  try {
    // Test 4.1: Lock seat and check TTL
    log('\n4.1 Locking seat and checking TTL...', 'blue');
    const lockResponse = await userA.post(`/seat-locks/events/${EVENT_ID}/seats/D1/hybrid/lock`);
    log(`🔒 Lock Response: ${JSON.stringify(lockResponse.data, null, 2)}`, 'green');

    // Test 4.2: Check status immediately
    const statusResponse = await userA.get(`/seat-locks/events/${EVENT_ID}/seats/D1/lock`);
    log(`📊 Initial Status: ${JSON.stringify(statusResponse.data, null, 2)}`, 'yellow');

    // Test 4.3: Wait and check TTL again
    log('\n4.2 Waiting 10 seconds to check TTL decrease...', 'blue');
    await new Promise(resolve => setTimeout(resolve, 10000));
    
    const statusResponse2 = await userA.get(`/seat-locks/events/${EVENT_ID}/seats/D1/lock`);
    log(`📊 Status after 10s: ${JSON.stringify(statusResponse2.data, null, 2)}`, 'yellow');

    // Test 4.4: Extend lock
    log('\n4.3 Testing lock extension...', 'blue');
    const extendResponse = await userA.put(`/seat-locks/events/${EVENT_ID}/seats/D1/hybrid/extend`);
    log(`⏰ Extend Response: ${JSON.stringify(extendResponse.data, null, 2)}`, 'green');

    // Cleanup
    await userA.delete(`/seat-locks/events/${EVENT_ID}/seats/D1/hybrid/release`);
    log('🧹 Timer test cleanup completed', 'green');

  } catch (error) {
    log(`❌ Timer test failed: ${error.message}`, 'red');
  }
}

// Interactive menu
function showMenu() {
  console.log('\n' + '='.repeat(50));
  log('🧪 EventBn Seat Locking Test Suite', 'bright');
  console.log('='.repeat(50));
  console.log('1. Basic Seat Locking Test');
  console.log('2. Multi-User Competition Test');  
  console.log('3. Queue System Test');
  console.log('4. Timer & TTL Test');
  console.log('5. Run All Tests');
  console.log('6. Check Backend Status');
  console.log('0. Exit');
  console.log('='.repeat(50));
}

async function checkBackendStatus() {
  log('\n🏥 Backend Health Check', 'cyan');
  log('=====================================', 'cyan');
  
  try {
    // Check if backend is running
    const healthCheck = await axios.get(`${BASE_URL}/../health`).catch(() => null);
    if (healthCheck) {
      log('✅ Backend is running', 'green');
    } else {
      log('❌ Backend health endpoint not found', 'yellow');
    }

    // Check stats endpoint (doesn't require auth)
    const statsResponse = await axios.get(`${BASE_URL}/seat-locks/events/${EVENT_ID}/hybrid/stats`);
    log(`📊 Queue Stats: ${JSON.stringify(statsResponse.data.stats, null, 2)}`, 'green');

  } catch (error) {
    log(`❌ Backend is not responding: ${error.message}`, 'red');
    log('   Make sure to run: npm start in backend-api directory', 'yellow');
  }
}

async function runAllTests() {
  log('\n🚀 Running All Tests...', 'bright');
  await testBasicSeatLocking();
  await testMultiUserCompetition();
  await testQueueSystem();
  await testTimerTTL();
  log('\n✅ All tests completed!', 'bright');
}

// Main execution
async function main() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  // Check if tokens are configured
  if (TEST_USERS.userA === 'your-jwt-token-user-a') {
    log('⚠️  Please update TEST_USERS tokens in the script before running tests', 'yellow');
    log('   You can get tokens by logging in through the API', 'yellow');
  }

  while (true) {
    showMenu();
    const choice = await new Promise(resolve => {
      rl.question('\nSelect a test to run: ', resolve);
    });

    switch (choice) {
      case '1':
        await testBasicSeatLocking();
        break;
      case '2':
        await testMultiUserCompetition();
        break;
      case '3':
        await testQueueSystem();
        break;
      case '4':
        await testTimerTTL();
        break;
      case '5':
        await runAllTests();
        break;
      case '6':
        await checkBackendStatus();
        break;
      case '0':
        log('👋 Goodbye!', 'cyan');
        rl.close();
        process.exit(0);
      default:
        log('❌ Invalid choice. Please try again.', 'red');
    }
  }
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = {
  testBasicSeatLocking,
  testMultiUserCompetition,
  testQueueSystem,
  testTimerTTL,
  checkBackendStatus
};