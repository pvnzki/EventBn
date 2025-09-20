// Entry point for core-service microservice.
// Keeps user/org/event/ticket logic isolated from post-service.
// Only export service groupings; no direct dependency on post-service code.

// Entry point for core-service microservice.
// Keeps user/org/event/ticket logic isolated from post-service.
// Only export service groupings; no direct dependency on post-service code.

module.exports = {
  users: require("./users"),
  organizations: require("./organizations"),
  events: require("./events"),
  tickets: require("./tickets"),
  auth: require("./auth"),
  // Health probe for service monitoring
  async health() {
    return {
      service: "core-service",
      status: "ok",
      mode: "microservice",
      timestamp: new Date().toISOString(),
      components: ["users", "organizations", "events", "tickets", "auth"],
    };
  },
};
