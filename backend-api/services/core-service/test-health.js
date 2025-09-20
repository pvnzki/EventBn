const http = require("http");

console.log("Testing health endpoint...");

const options = {
  hostname: "localhost",
  port: 3001,
  path: "/health",
  method: "GET",
  timeout: 5000,
};

const req = http.request(options, (res) => {
  console.log(`Status: ${res.statusCode}`);
  console.log(`Headers:`, res.headers);

  let data = "";
  res.on("data", (chunk) => {
    data += chunk;
  });

  res.on("end", () => {
    console.log("Response:", data);
    process.exit(0);
  });
});

req.on("error", (error) => {
  console.error("Error:", error);
  process.exit(1);
});

req.on("timeout", () => {
  console.error("Request timed out");
  req.destroy();
  process.exit(1);
});

req.end();
