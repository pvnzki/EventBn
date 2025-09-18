const axios = require('axios');

// Test configuration
const BASE_URL = 'http://localhost:5000/api';
const EVENT_ID = 'test-event-123';
const SEAT_ID = 'A1';

// Mock JWT token (you'll need to replace with a real token)
const AUTH_TOKEN = 'your-jwt-token-here';

const api = axios.create({
  baseURL: BASE_URL,
  headers: {
    'Authorization': `Bearer ${AUTH_TOKEN}`,
    'Content-Type': 'application/json'
  }
});

async function testDirectLocking() {
  console.log('🧪 Testing Direct Seat Locking...\n');
  
  try {
    // Test direct lock
    console.log('1. Attempting to lock seat directly...');
    const lockResponse = await api.post(`/seat-locks/events/${EVENT_ID}/seats/${SEAT_ID}/lock`);
    console.log('✅ Direct lock response:', lockResponse.data);

    // Test lock status
    console.log('\n2. Checking lock status...');
    const statusResponse = await api.get(`/seat-locks/events/${EVENT_ID}/seats/${SEAT_ID}/lock`);
    console.log('📊 Lock status:', statusResponse.data);

    // Test extend lock
    console.log('\n3. Extending lock...');
    const extendResponse = await api.put(`/seat-locks/events/${EVENT_ID}/seats/${SEAT_ID}/lock/extend`);
    console.log('⏰ Extend response:', extendResponse.data);

    // Test release lock
    console.log('\n4. Releasing lock...');
    const releaseResponse = await api.delete(`/seat-locks/events/${EVENT_ID}/seats/${SEAT_ID}/lock`);
    console.log('🔓 Release response:', releaseResponse.data);

  } catch (error) {
    console.error('❌ Error in direct locking test:', error.response?.data || error.message);
  }
}

async function testHybridLocking() {
  console.log('\n🚀 Testing Hybrid Seat Locking...\n');
  
  try {
    // Test hybrid lock
    console.log('1. Attempting to lock seat with hybrid approach...');
    const lockResponse = await api.post(`/seat-locks/events/${EVENT_ID}/seats/${SEAT_ID}/hybrid/lock`);
    console.log('✅ Hybrid lock response:', lockResponse.data);

    if (lockResponse.data.queued) {
      // If queued, poll for result
      console.log('\n2. Request was queued, polling for result...');
      const requestId = lockResponse.data.requestId;
      
      try {
        const pollResponse = await api.get(`/seat-locks/hybrid/requests/${requestId}/result?timeout=30000`);
        console.log('📋 Poll result:', pollResponse.data);
      } catch (pollError) {
        console.log('⏰ Polling timed out or failed:', pollError.response?.data || pollError.message);
      }
    }

    // Test load stats
    console.log('\n3. Getting load statistics...');
    const statsResponse = await api.get(`/seat-locks/events/${EVENT_ID}/hybrid/stats`);
    console.log('📊 Load stats:', statsResponse.data);

    // Test hybrid release
    console.log('\n4. Releasing seat with hybrid approach...');
    const releaseResponse = await api.delete(`/seat-locks/events/${EVENT_ID}/seats/${SEAT_ID}/hybrid/release`);
    console.log('🔓 Hybrid release response:', releaseResponse.data);

  } catch (error) {
    console.error('❌ Error in hybrid locking test:', error.response?.data || error.message);
  }
}

async function testHighConcurrency() {
  console.log('\n⚡ Testing High Concurrency (Multiple Users)...\n');
  
  const users = ['user1', 'user2', 'user3', 'user4', 'user5'];
  const promises = [];

  for (let i = 0; i < users.length; i++) {
    const userId = users[i];
    const seatId = `A${i + 1}`;
    
    promises.push(
      (async () => {
        try {
          console.log(`👤 User ${userId} attempting to lock seat ${seatId}...`);
          const response = await api.post(`/seat-locks/events/${EVENT_ID}/seats/${seatId}/hybrid/lock`);
          console.log(`✅ User ${userId} result:`, response.data);
          return { userId, seatId, result: response.data };
        } catch (error) {
          console.error(`❌ User ${userId} error:`, error.response?.data || error.message);
          return { userId, seatId, error: error.response?.data || error.message };
        }
      })()
    );
  }

  const results = await Promise.all(promises);
  
  console.log('\n📊 Concurrency Test Results:');
  results.forEach(result => {
    console.log(`   ${result.userId} (${result.seatId}):`, result.error ? '❌ Failed' : '✅ Success');
  });
}

async function testQueueSystem() {
  console.log('\n🔄 Testing Queue System Directly...\n');
  
  try {
    // Test queue lock
    console.log('1. Adding lock request to queue...');
    const queueResponse = await api.post(`/queue/events/${EVENT_ID}/seats/${SEAT_ID}/queue/lock`);
    console.log('📝 Queue response:', queueResponse.data);

    if (queueResponse.data.requestId) {
      // Poll for result
      console.log('\n2. Polling for queue result...');
      try {
        const pollResponse = await api.get(`/queue/requests/${queueResponse.data.requestId}/poll?timeout=30000`);
        console.log('📋 Queue poll result:', pollResponse.data);
      } catch (pollError) {
        console.log('⏰ Queue polling failed:', pollError.response?.data || pollError.message);
      }
    }

    // Test queue stats
    console.log('\n3. Getting queue statistics...');
    const statsResponse = await api.get(`/queue/events/${EVENT_ID}/queue/stats`);
    console.log('📊 Queue stats:', statsResponse.data);

  } catch (error) {
    console.error('❌ Error in queue system test:', error.response?.data || error.message);
  }
}

async function runAllTests() {
  console.log('🚀 EventBn Queue System Test Suite\n');
  console.log('=====================================\n');

  // Note: You need to start the backend server and update the AUTH_TOKEN
  if (AUTH_TOKEN === 'your-jwt-token-here') {
    console.log('⚠️  Please update AUTH_TOKEN with a valid JWT token before running tests');
    console.log('   You can get a token by logging in through the API\n');
  }

  await testDirectLocking();
  await testHybridLocking();
  await testHighConcurrency();
  await testQueueSystem();

  console.log('\n✅ All tests completed!');
  console.log('\n💡 Tips:');
  console.log('   - Start the backend server: npm start');
  console.log('   - Update AUTH_TOKEN with a valid JWT');
  console.log('   - Monitor console logs for queue processing');
  console.log('   - Check Redis for stored data');
}

if (require.main === module) {
  runAllTests().catch(console.error);
}

module.exports = {
  testDirectLocking,
  testHybridLocking,
  testHighConcurrency,
  testQueueSystem
};
