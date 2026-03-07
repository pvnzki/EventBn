const { PrismaClient } = require("@prisma/client");

const prisma = new PrismaClient({
  log:
    process.env.NODE_ENV === "Dev"
      ? ["query", "info", "warn", "error"]
      : ["error"],
});

// ── DB Keep-alive ─────────────────────────────────────────────────────
// NeonDB free-tier suspends compute after 5 min idle.
// Ping every 4 min to keep connections alive and avoid stale-pool errors.
const DB_KEEPALIVE_MS = 4 * 60 * 1000;
let _keepAliveTimer = null;

function startDbKeepAlive() {
  if (_keepAliveTimer) return;
  _keepAliveTimer = setInterval(async () => {
    try {
      await prisma.$queryRaw`SELECT 1`;
    } catch (e) {
      console.warn("[CORE-DB] Keep-alive ping failed:", e.message);
      try { await prisma.$disconnect(); } catch (_) {}
    }
  }, DB_KEEPALIVE_MS);
  if (_keepAliveTimer.unref) _keepAliveTimer.unref();
}

startDbKeepAlive();

// Graceful shutdown
process.on("beforeExit", async () => {
  if (_keepAliveTimer) clearInterval(_keepAliveTimer);
  await prisma.$disconnect();
});

module.exports = prisma;