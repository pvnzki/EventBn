require("dotenv").config();
const { PrismaClient } = require("@prisma/client");
const bcrypt = require("bcrypt");

async function seed() {
  const prisma = new PrismaClient();
  try {
    console.log("🌱 Seeding database...");

    // Create test organizer
    const hash1 = await bcrypt.hash("Test@1234", 12);
    const organizer = await prisma.user.create({
      data: {
        name: "John Event Organizer",
        email: "organizer@eventbn.com",
        password_hash: hash1,
        role: "ORGANIZER",
        is_email_verified: true,
        profile_completed: true,
        billing_country: "Sri Lanka",
      },
    });
    console.log("✅ Organizer created:", organizer.email);

    // Create regular user
    const hash2 = await bcrypt.hash("Test@1234", 12);
    const attendee = await prisma.user.create({
      data: {
        name: "Jane Attendee",
        email: "attendee@eventbn.com",
        password_hash: hash2,
        role: "USER",
        is_email_verified: true,
        profile_completed: true,
        billing_country: "Sri Lanka",
      },
    });
    console.log("✅ Attendee created:", attendee.email);

    // Create organization
    const org = await prisma.organization.create({
      data: {
        user_id: organizer.user_id,
        name: "EventBn Demo Org",
        description: "Demo organization for testing",
        contact_email: organizer.email,
      },
    });
    console.log("✅ Organization created:", org.name);

    // Create sample events
    const events = [
      {
        title: "Summer Music Festival 2026",
        description: "Join us for live music featuring top artists from around the world!",
        category: "Music",
        venue: "Central Park Amphitheater",
        location: "Colombo, Sri Lanka",
        start_time: new Date("2026-04-15T18:00:00Z"),
        end_time: new Date("2026-04-15T23:30:00Z"),
        capacity: 500,
        status: "ACTIVE",
        organization_id: org.organization_id,
        cover_image_url: "https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=800&h=400&fit=crop",
      },
      {
        title: "Tech Innovation Summit",
        description: "Discover the latest in technology trends, AI innovations, and startup pitches.",
        category: "Technology",
        venue: "BMICH Convention Center",
        location: "Colombo, Sri Lanka",
        start_time: new Date("2026-05-20T09:00:00Z"),
        end_time: new Date("2026-05-20T17:00:00Z"),
        capacity: 300,
        status: "ACTIVE",
        organization_id: org.organization_id,
        cover_image_url: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&h=400&fit=crop",
      },
      {
        title: "Food & Wine Tasting Evening",
        description: "An exquisite evening of wine tasting paired with gourmet dishes.",
        category: "Food & Drink",
        venue: "Hilton Colombo",
        location: "Colombo, Sri Lanka",
        start_time: new Date("2026-06-10T19:00:00Z"),
        end_time: new Date("2026-06-10T22:00:00Z"),
        capacity: 100,
        status: "ACTIVE",
        organization_id: org.organization_id,
        cover_image_url: "https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=800&h=400&fit=crop",
      },
      {
        title: "Art Gallery Opening Night",
        description: "Celebrate contemporary art from emerging local artists.",
        category: "Art",
        venue: "Modern Art Gallery",
        location: "Kandy, Sri Lanka",
        start_time: new Date("2026-07-25T18:30:00Z"),
        end_time: new Date("2026-07-25T21:00:00Z"),
        capacity: 200,
        status: "ACTIVE",
        organization_id: org.organization_id,
        cover_image_url: "https://images.unsplash.com/photo-1578321272176-b7bbc0679853?w=800&h=400&fit=crop",
      },
      {
        title: "Marathon Training Workshop",
        description: "Professional tips on marathon preparation, nutrition, and injury prevention.",
        category: "Sports",
        venue: "City Sports Complex",
        location: "Galle, Sri Lanka",
        start_time: new Date("2026-08-05T08:00:00Z"),
        end_time: new Date("2026-08-05T12:00:00Z"),
        capacity: 150,
        status: "ACTIVE",
        organization_id: org.organization_id,
        cover_image_url: "https://images.unsplash.com/photo-1544717297-fa95b6ee9643?w=800&h=400&fit=crop",
      },
    ];

    for (const eventData of events) {
      const event = await prisma.event.create({ data: eventData });
      console.log(`✅ Event: ${event.title}`);
    }

    console.log("\n🎉 Seeding complete!");
    console.log("📋 Test Accounts:");
    console.log("   Organizer: organizer@eventbn.com / Test@1234");
    console.log("   Attendee:  attendee@eventbn.com / Test@1234");
  } catch (e) {
    console.error("❌ Seeding error:", e.message);
  } finally {
    await prisma.$disconnect();
  }
}

seed();
