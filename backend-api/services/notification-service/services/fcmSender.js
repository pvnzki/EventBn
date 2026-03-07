/**
 * FCM Push Notification Sender
 *
 * Uses Firebase Admin SDK to send push notifications to device tokens.
 * Integrates with the Observer pattern: after a notification is saved to DB,
 * this module sends the push to the user's registered devices.
 */

const admin = require("firebase-admin");
const path = require("path");
const prisma = require("../lib/database");

let firebaseInitialized = false;

/**
 * Initialize Firebase Admin SDK.
 * Expects GOOGLE_APPLICATION_CREDENTIALS env var or a service account key file.
 */
function initializeFirebase() {
  if (firebaseInitialized) return;

  try {
    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
    const serviceAccountBase64 = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;

    if (serviceAccountBase64) {
      // Cloud deployment: credentials passed as base64-encoded JSON env var
      const serviceAccount = JSON.parse(
        Buffer.from(serviceAccountBase64, "base64").toString("utf-8")
      );
      // Normalize private key line endings — Windows CRLF encoding can corrupt PEM
      if (serviceAccount.private_key) {
        serviceAccount.private_key = serviceAccount.private_key
          .replace(/\\r\\n/g, "\\n")
          .replace(/\r\n/g, "\n")
          .replace(/\r/g, "\n");
      }
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    } else if (serviceAccountPath) {
      // Local development: credentials loaded from a file
      const resolvedPath = path.resolve(process.cwd(), serviceAccountPath);
      const serviceAccount = require(resolvedPath);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      // Auto-detected from env
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
      });
    } else {
      console.warn(
        "[FCM] No Firebase credentials found. Push notifications disabled."
      );
      return;
    }

    firebaseInitialized = true;
    console.log("[✅] [FCM] Firebase Admin SDK initialized");
  } catch (error) {
    console.error("[❌] [FCM] Firebase init error:", error.message);
  }
}

/**
 * Send push notification to a single user's devices.
 * @param {number} userId - The user to notify
 * @param {object} notification - { title, body }
 * @param {object} data - Additional data payload (all values must be strings)
 */
async function sendPushToUser(userId, notification, data = {}) {
  if (!firebaseInitialized) return;

  try {
    // Look up user's device tokens
    const deviceTokens = await prisma.deviceToken.findMany({
      where: { user_id: parseInt(userId) },
      select: { token: true, id: true },
    });

    if (deviceTokens.length === 0) {
      return;
    }

    const tokens = deviceTokens.map((dt) => dt.token);

    // Convert all data values to strings (FCM requires string values)
    const stringData = {};
    for (const [key, value] of Object.entries(data)) {
      stringData[key] = String(value);
    }

    const message = {
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: stringData,
      android: {
        priority: "high",
        notification: {
          channelId: "eventbn_notifications",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    // Send to each token individually to handle failures per-token
    const results = await Promise.allSettled(
      tokens.map((token) =>
        admin.messaging().send({ ...message, token })
      )
    );

    // Clean up invalid tokens
    const tokensToRemove = [];
    results.forEach((result, index) => {
      if (result.status === "rejected") {
        const errCode = result.reason?.code;
        if (
          errCode === "messaging/invalid-registration-token" ||
          errCode === "messaging/registration-token-not-registered"
        ) {
          tokensToRemove.push(deviceTokens[index].id);
        }
      }
    });

    if (tokensToRemove.length > 0) {
      await prisma.deviceToken.deleteMany({
        where: { id: { in: tokensToRemove } },
      });
      console.log(
        `[FCM] Cleaned up ${tokensToRemove.length} invalid token(s)`
      );
    }

    const successCount = results.filter(
      (r) => r.status === "fulfilled"
    ).length;
    console.log(
      `[FCM] Push sent to user ${userId}: ${successCount}/${tokens.length} succeeded`
    );
  } catch (error) {
    console.error(`[FCM] Error sending push to user ${userId}:`, error.message);
  }
}

/**
 * Send push notification to multiple users.
 * @param {number[]} userIds - Array of user IDs
 * @param {object} notification - { title, body }
 * @param {object} data - Additional data payload
 */
async function sendPushToUsers(userIds, notification, data = {}) {
  if (!firebaseInitialized) return;

  await Promise.allSettled(
    userIds.map((uid) => sendPushToUser(uid, notification, data))
  );
}

module.exports = {
  initializeFirebase,
  sendPushToUser,
  sendPushToUsers,
};
