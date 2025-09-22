#!/usr/bin/env node

// Quick backend health checker
const http = require("http");

const services = [
  { name: "Core Service", url: "http://localhost:3001/api/health", port: 3001 },
  { name: "Post Service", url: "http://localhost:3002/api/health", port: 3002 },
];

console.log("🔍 Checking backend services...\n");

async function checkService(service) {
  return new Promise((resolve) => {
    const req = http.get(service.url, { timeout: 5000 }, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        console.log(`✅ ${service.name} (${service.port}): HEALTHY`);
        console.log(`   Status: ${res.statusCode}`);
        try {
          const parsed = JSON.parse(data);
          console.log(`   Service: ${parsed.service || "unknown"}`);
          console.log(`   Database: ${parsed.database || "unknown"}`);
        } catch (e) {
          console.log(`   Response: ${data.substring(0, 100)}...`);
        }
        resolve(true);
      });
    });

    req.on("error", (err) => {
      console.log(`❌ ${service.name} (${service.port}): FAILED`);
      console.log(`   Error: ${err.message}`);
      resolve(false);
    });

    req.on("timeout", () => {
      console.log(`⏰ ${service.name} (${service.port}): TIMEOUT`);
      resolve(false);
    });
  });
}

async function main() {
  const results = await Promise.all(services.map(checkService));

  console.log("\n📊 Summary:");
  const healthy = results.filter((r) => r).length;
  const total = results.length;

  if (healthy === total) {
    console.log(`🎉 All ${total} services are healthy!`);
  } else {
    console.log(`⚠️  ${healthy}/${total} services are healthy`);
    console.log("\n💡 Troubleshooting tips:");
    console.log(
      "   • Run: cd backend-api/services && node start-microservices.js"
    );
    console.log("   • Check if ports 3001 and 3002 are available");
    console.log("   • Verify database connection in services");
  }
}

main().catch(console.error);
