// Quick test to load events service directly
const eventsService = require('./services/core-service/events');

console.log('Events Service Type:', typeof eventsService);
console.log('Events Service Constructor:', eventsService.constructor.name);

// Try to call methods directly
eventsService.getAllEvents()
  .then(result => {
    console.log('✅ getAllEvents works:', result);
  })
  .catch(error => {
    console.log('❌ getAllEvents error:', error.message);
  });

// Test other methods
try {
  console.log('Available methods:');
  for (const prop in eventsService) {
    if (typeof eventsService[prop] === 'function') {
      console.log(`- ${prop}: ${typeof eventsService[prop]}`);
    }
  }
} catch (error) {
  console.log('Error listing methods:', error.message);
}
