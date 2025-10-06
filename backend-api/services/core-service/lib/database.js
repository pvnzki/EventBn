const { PrismaClient } = require("@prisma/client");

console.log("[DATABASE] Initializing Prisma client...");

// Initialize Prisma client
const prisma = new PrismaClient({
  log: ["query", "info", "warn", "error"],
});

console.log("[DATABASE] Prisma client initialized:", !!prisma);
console.log("[DATABASE] Available methods:", Object.keys(prisma));

module.exports = prisma;
