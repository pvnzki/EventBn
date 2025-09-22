// post-service/user-event-consumer.js
require("dotenv").config();
const amqp = require("amqplib");
// Use shared Prisma instance to avoid creating multiple PrismaClient connections
const { prisma } = require("./lib/database");

// Use environment variables
const RABBITMQ_URL = process.env.RABBITMQ_URL || "amqp://localhost";
const queueName = process.env.RABBITMQ_USER_QUEUE || "user_events_queue";

console.log(
  `[POST-SERVICE][USER-EVENT-CONSUMER] Using shared Prisma client (pid=${process.pid})`
);

async function handleUserEvent(event) {
  console.log(`[📥] Received event: ${event.type}`);

  const userData = event.data;

  try {
    // Use Prisma upsert operation
    // This will INSERT a new user if they don't exist,
    // or UPDATE their details if they already exist.
    const user = await prisma.user.upsert({
      where: { id: userData.id },
      update: {
        full_name: userData.full_name,
        avatar_url: userData.avatar_url,
      },
      create: {
        id: userData.id,
        full_name: userData.full_name,
        avatar_url: userData.avatar_url,
      },
    });

    console.log(`[💾] Successfully replicated data for user: ${userData.id}`);
    return true;
  } catch (error) {
    console.error("❌ Error upserting user data:", error);
    // In production, you would return false to signal the message should be re-queued
    return false;
  }
}

async function startConsumer() {
  try {
    const connection = await amqp.connect(RABBITMQ_URL);
    const channel = await connection.createChannel();
    await channel.assertQueue(queueName, { durable: true });

    console.log(
      `[👂] Waiting for messages in queue: ${queueName}. To exit press CTRL+C`
    );

    channel.consume(queueName, async (msg) => {
      if (msg !== null) {
        try {
          const event = JSON.parse(msg.content.toString());
          const success = await handleUserEvent(event);

          if (success) {
            // Acknowledge the message to remove it from the queue
            channel.ack(msg);
          } else {
            // Reject the message but ask RabbitMQ to re-queue it
            console.log("Processing failed, re-queueing message.");
            channel.nack(msg, false, true);
          }
        } catch (e) {
          console.error("Error processing message", e);
          // Reject and don't re-queue a poison message
          channel.nack(msg, false, false);
        }
      }
    });
  } catch (error) {
    console.error("❌ Consumer failed to start:", error);
  }
}

module.exports = { startConsumer };
