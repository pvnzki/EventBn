/**
 * Temporary seed script — creates test posts linked to events.
 * Run from the post-service directory:
 *   node seed-event-posts.js
 *
 * Remove this file when done testing.
 */

const { PrismaClient } = require("@prisma/client");
require("dotenv").config();

const prisma = new PrismaClient();

const SAMPLE_IMAGES = [
  "https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=800&h=600&fit=crop",
  "https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=800&h=600&fit=crop",
  "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800&h=600&fit=crop",
  "https://images.unsplash.com/photo-1429962714451-bb934ecdc4ec?w=800&h=600&fit=crop",
  "https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=800&h=600&fit=crop",
  "https://images.unsplash.com/photo-1506157786151-b8491531f063?w=800&h=600&fit=crop",
  "https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?w=800&h=600&fit=crop",
  "https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=800&h=600&fit=crop",
  "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=800&h=600&fit=crop",
  "https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=800&h=600&fit=crop",
];

const CAPTIONS = [
  "Amazing vibes at this event! 🎉🔥 #EventBn",
  "Best night ever! The energy was unreal 🚀",
  "Can't believe how incredible this was 🎶✨",
  "Throwback to an unforgettable evening 💫",
  "Who else was here? Drop a comment! 🙌",
  "The crowd went absolutely wild tonight 🤩",
  "Memories that will last a lifetime 📸",
  "This event exceeded all expectations 🌟",
  "Living my best life at this event 💃🕺",
  "Nothing beats live events! Pure magic ✨🎵",
];

async function seed() {
  // Seed posts for event IDs 1–100 (covers most likely existing events)
  // Each event gets 7 posts so we can test pagination (3 per page → 3 pages)
  const EVENT_IDS = Array.from({ length: 100 }, (_, i) => i + 1);
  const POSTS_PER_EVENT = 7;

  let created = 0;

  for (const eventId of EVENT_IDS) {
    for (let i = 0; i < POSTS_PER_EVENT; i++) {
      const imgIdx = (eventId + i) % SAMPLE_IMAGES.length;
      const capIdx = (eventId + i) % CAPTIONS.length;

      await prisma.post.create({
        data: {
          user_id: 1,
          event_id: eventId,
          caption: `${CAPTIONS[capIdx]} (Event #${eventId}, Post ${i + 1})`,
          images: [SAMPLE_IMAGES[imgIdx]],
          image_url: SAMPLE_IMAGES[imgIdx],
          videos: [],
          engagement_count: Math.floor(Math.random() * 50),
          comment_count: Math.floor(Math.random() * 10),
          created_at: new Date(Date.now() - (POSTS_PER_EVENT - i) * 3600000), // stagger timestamps
        },
      });
      created++;
    }
  }

  console.log(`✅ Created ${created} test posts for ${EVENT_IDS.length} events (${POSTS_PER_EVENT} each).`);
}

seed()
  .catch((e) => {
    console.error("❌ Seed error:", e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
