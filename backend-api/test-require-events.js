// Test requiring the events service file
try {
  console.log('Requiring events service...');
  const EventsService = require('./services/core-service/events/index.js');
  console.log('Events service loaded:', typeof EventsService);
  console.log('Events service constructor:', EventsService.constructor.name);
  console.log('Events service properties:', Object.keys(EventsService));
  
  // Try to access prototype methods
  console.log('Events service prototype:', Object.getOwnPropertyNames(Object.getPrototypeOf(EventsService)));
  
} catch (error) {
  console.log('Error requiring events service:', error.message);
  console.log('Stack:', error.stack);
}
