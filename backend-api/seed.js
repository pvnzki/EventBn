const prisma = require('./lib/database');

async function seedEvents() {
  console.log('🌱 Seeding events data...');
  
  try {
    // First, let's check if we have any users to create events for
    let user = await prisma.user.findFirst();
    
    if (!user) {
      // Create a test user first
      user = await prisma.user.create({
        data: {
          name: 'John Event Organizer',
          email: 'organizer@eventbn.com',
          password_hash: '$2b$12$dummy.hash.for.testing', // This is a dummy hash
          role: 'ORGANIZER'
        }
      });
      console.log('✅ Created test user');
    }

    // Create sample events
    const events = [
      {
        title: 'Summer Music Festival 2025',
        description: 'Join us for an unforgettable night of live music featuring top artists from around the world. Food trucks, art installations, and amazing vibes!',
        category: 'Music',
        venue: 'Central Park Amphitheater',
        location: 'Central Park, New York, NY',
        start_time: new Date('2025-07-15T18:00:00Z'),
        end_time: new Date('2025-07-15T23:30:00Z'),
        capacity: 5000,
        cover_image_url: 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=800&h=400&fit=crop',
        status: 'ACTIVE',
        creator_id: user.user_id
      },
      {
        title: 'Tech Innovation Summit',
        description: 'Discover the latest in technology trends, AI innovations, and startup pitches. Network with industry leaders and investors.',
        category: 'Technology',
        venue: 'Convention Center',
        location: 'San Francisco, CA',
        start_time: new Date('2025-08-20T09:00:00Z'),
        end_time: new Date('2025-08-20T17:00:00Z'),
        capacity: 1500,
        cover_image_url: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&h=400&fit=crop',
        status: 'ACTIVE',
        creator_id: user.user_id
      },
      {
        title: 'Food & Wine Tasting',
        description: 'An exquisite evening of wine tasting paired with gourmet dishes from renowned chefs. Perfect for food enthusiasts!',
        category: 'Food & Drink',
        venue: 'Downtown Wine Bar',
        location: 'Chicago, IL',
        start_time: new Date('2025-09-10T19:00:00Z'),
        end_time: new Date('2025-09-10T22:00:00Z'),
        capacity: 100,
        cover_image_url: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=800&h=400&fit=crop',
        status: 'ACTIVE',
        creator_id: user.user_id
      },
      {
        title: 'Art Gallery Opening',
        description: 'Celebrate the opening of our new contemporary art exhibition featuring works from emerging local artists.',
        category: 'Art',
        venue: 'Modern Art Gallery',
        location: 'Los Angeles, CA',
        start_time: new Date('2025-08-25T18:30:00Z'),
        end_time: new Date('2025-08-25T21:00:00Z'),
        capacity: 200,
        cover_image_url: 'https://images.unsplash.com/photo-1578321272176-b7bbc0679853?w=800&h=400&fit=crop',
        status: 'ACTIVE',
        creator_id: user.user_id
      },
      {
        title: 'Marathon Training Workshop',
        description: 'Join professional trainers for tips on marathon preparation, nutrition, and injury prevention. All skill levels welcome!',
        category: 'Sports',
        venue: 'City Sports Complex',
        location: 'Boston, MA',
        start_time: new Date('2025-09-05T08:00:00Z'),
        end_time: new Date('2025-09-05T12:00:00Z'),
        capacity: 300,
        cover_image_url: 'https://images.unsplash.com/photo-1544717297-fa95b6ee9643?w=800&h=400&fit=crop',
        status: 'ACTIVE',
        creator_id: user.user_id
      }
    ];

    for (const eventData of events) {
      const event = await prisma.event.create({
        data: eventData
      });
      console.log(`✅ Created event: ${event.title}`);
    }

    console.log('🎉 Seeding completed successfully!');
    console.log(`📊 Created ${events.length} events`);
    
  } catch (error) {
    console.error('❌ Seeding failed:', error);
  } finally {
    await prisma.$disconnect();
  }
}

seedEvents();
