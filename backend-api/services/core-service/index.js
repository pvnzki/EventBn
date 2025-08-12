// Entry point for core-service microservice
module.exports = {
  users: require('./users'),
  organizations: require('./organizations'),
  events: require('../../modules/core/events'),
  tickets: require('../../modules/core/tickets'),
};
