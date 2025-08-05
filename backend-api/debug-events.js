// Debug script to check events service
const coreService = require('./services/core-service');

console.log('Core Service:', typeof coreService);
console.log('Core Service events:', typeof coreService.events);

if (coreService.events) {
  console.log('Events service methods:');
  console.log(Object.getOwnPropertyNames(coreService.events));
  console.log('Events service prototype methods:');
  console.log(Object.getOwnPropertyNames(Object.getPrototypeOf(coreService.events)));
} else {
  console.log('Events service is not available');
}

// Try calling directly
try {
  const eventsService = require('./services/core-service/events');
  console.log('Direct events service:', typeof eventsService);
  console.log('Direct events service methods:');
  console.log(Object.getOwnPropertyNames(eventsService));
  console.log('Direct events service prototype methods:');
  console.log(Object.getOwnPropertyNames(Object.getPrototypeOf(eventsService)));
} catch (error) {
  console.log('Error loading events service directly:', error.message);
}
