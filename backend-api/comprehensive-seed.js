const prisma = require('./lib/database');
const bcrypt = require('bcrypt');

async function comprehensiveSeed() {
  console.log('🌱 Starting comprehensive database seeding...');
  
  try {
    // Create diverse users
    console.log('👥 Creating users...');
    const users = [];
    
    const userProfiles = [
      {
        name: 'John Event Organizer',
        email: 'organizer@eventbn.com',
        role: 'ORGANIZER',
        phone_number: '+1-555-0101'
      },
      {
        name: 'Sarah Wilson',
        email: 'sarah.wilson@email.com', 
        role: 'ORGANIZER',
        phone_number: '+1-555-0102'
      },
      {
        name: 'Mike Chen',
        email: 'mike.chen@email.com',
        role: 'ORGANIZER', 
        phone_number: '+1-555-0103'
      },
      {
        name: 'Emma Rodriguez',
        email: 'emma.rodriguez@email.com',
        role: 'USER',
        phone_number: '+1-555-0104'
      },
      {
        name: 'David Johnson',
        email: 'david.johnson@email.com',
        role: 'USER',
        phone_number: '+1-555-0105'
      },
      {
        name: 'Lisa Park',
        email: 'lisa.park@email.com',
        role: 'USER',
        phone_number: '+1-555-0106'
      },
      {
        name: 'Admin User',
        email: 'admin@eventbn.com',
        role: 'ADMIN',
        phone_number: '+1-555-0100'
      }
    ];

    const password_hash = await bcrypt.hash('password123', 12);

    for (const profile of userProfiles) {
      const user = await prisma.user.create({
        data: {
          ...profile,
          password_hash,
          is_email_verified: true,
          is_active: true
        }
      });
      users.push(user);
      console.log(`✅ Created user: ${user.name} (${user.role})`);
    }

    // Create organizations
    console.log('🏢 Creating organizations...');
    const organizations = [];
    
    const orgData = [
      {
        name: 'EventBn Productions',
        description: 'Premier event management company specializing in corporate and entertainment events',
        contact_email: 'contact@eventbnproductions.com',
        contact_number: '+1-555-EVENTS',
        website_url: 'https://eventbnproductions.com',
        user_id: users[0].user_id // John Event Organizer
      },
      {
        name: 'TechCorp Events',
        description: 'Technology conference and workshop organizer',
        contact_email: 'hello@techcorpevents.com', 
        contact_number: '+1-555-TECH-01',
        website_url: 'https://techcorpevents.com',
        user_id: users[1].user_id // Sarah Wilson
      },
      {
        name: 'Cultural Arts Society',
        description: 'Promoting arts, culture, and community engagement through events',
        contact_email: 'info@culturalevents.org',
        contact_number: '+1-555-ARTS-01',
        website_url: 'https://culturalevents.org',
        user_id: users[2].user_id // Mike Chen
      },
      {
        name: 'Metro Sports League',
        description: 'Local sports events and fitness workshops',
        contact_email: 'sports@metrosports.com',
        contact_number: '+1-555-SPORT-1',
        website_url: 'https://metrosports.com',
        user_id: users[0].user_id // John Event Organizer (multiple orgs)
      }
    ];

    for (const orgProfile of orgData) {
      const org = await prisma.organization.create({
        data: orgProfile
      });
      organizations.push(org);
      console.log(`✅ Created organization: ${org.name}`);
    }

    // Create comprehensive events
    console.log('🎉 Creating events...');
    const eventCategories = [
      {
        title: 'Summer Music Festival 2025',
        description: 'Join us for an unforgettable night of live music featuring top artists from around the world. Food trucks, art installations, and amazing vibes! This three-day festival will showcase genres from rock to electronic dance music.',
        category: 'Music',
        venue: 'Central Park Amphitheater',
        location: 'Central Park, New York, NY',
        start_time: new Date('2025-07-15T18:00:00Z'),
        end_time: new Date('2025-07-17T23:30:00Z'),
        capacity: 5000,
        cover_image_url: 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=800&h=400&fit=crop',
        status: 'ACTIVE',
        organization_id: organizations[0].organization_id,
        ticket_types: JSON.stringify([
          { name: 'VIP Weekend Pass', price: 299.99, description: 'Full access + backstage tours' },
          { name: 'General Admission', price: 149.99, description: '3-day festival access' },
          { name: 'Single Day Pass', price: 59.99, description: 'One day access' }
        ])
      },
      {
        title: 'Tech Innovation Summit 2025',
        description: 'Discover the latest in technology trends, AI innovations, and startup pitches. Network with industry leaders, investors, and fellow entrepreneurs. Features keynotes from tech giants and hands-on workshops.',
        category: 'Technology',
        venue: 'Convention Center West',
        location: 'San Francisco, CA',
        start_time: new Date('2025-08-20T09:00:00Z'),
        end_time: new Date('2025-08-22T17:00:00Z'),
        capacity: 1500,
        cover_image_url: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&h=400&fit=crop',
        status: 'ACTIVE',
        organization_id: organizations[1].organization_id,
        ticket_types: JSON.stringify([
          { name: 'Full Conference Pass', price: 599.99, description: 'All sessions + networking events' },
          { name: 'Workshop Only', price: 199.99, description: 'Workshop access only' },
          { name: 'Student Pass', price: 99.99, description: 'Discounted student rate' }
        ])
      },
      {
        title: 'Food & Wine Experience',
        description: 'An exquisite evening of wine tasting paired with gourmet dishes from renowned chefs. Perfect for food enthusiasts and wine connoisseurs! Features tastings from 12 local wineries.',
        category: 'Food & Drink',
        venue: 'Downtown Wine Bar & Bistro',
        location: 'Chicago, IL',
        start_time: new Date('2025-09-10T19:00:00Z'),
        end_time: new Date('2025-09-10T22:00:00Z'),
        capacity: 100,
        cover_image_url: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=800&h=400&fit=crop',
        status: 'ACTIVE',
        organization_id: organizations[2].organization_id,
        ticket_types: JSON.stringify([
          { name: 'Premium Tasting', price: 89.99, description: 'Full tasting menu + premium wines' },
          { name: 'Standard Tasting', price: 59.99, description: 'Standard tasting experience' }
        ])
      },
      {
        title: 'Contemporary Art Gallery Opening',
        description: 'Celebrate the opening of our new contemporary art exhibition featuring works from emerging local artists. Meet the artists, enjoy cocktails, and be among the first to view these incredible pieces.',
        category: 'Art & Culture',
        venue: 'Modern Art Gallery',
        location: 'Los Angeles, CA',
        start_time: new Date('2025-08-25T18:30:00Z'),
        end_time: new Date('2025-08-25T21:00:00Z'),
        capacity: 200,
        cover_image_url: 'https://images.unsplash.com/photo-1578321272176-b7bbc0679853?w=800&h=400&fit=crop',
        status: 'ACTIVE',
        organization_id: organizations[2].organization_id,
        ticket_types: JSON.stringify([
          { name: 'Opening Night Pass', price: 25.00, description: 'Gallery access + welcome drink' },
          { name: 'Patron Pass', price: 75.00, description: 'VIP access + artist meet & greet' }
        ])
      },
      {
        title: 'Marathon Training Workshop',
        description: 'Join professional trainers for tips on marathon preparation, nutrition, and injury prevention. All skill levels welcome! Includes training plan, nutrition guide, and follow-up support.',
        category: 'Sports & Fitness',
        venue: 'City Sports Complex',
        location: 'Boston, MA',
        start_time: new Date('2025-09-05T08:00:00Z'),
        end_time: new Date('2025-09-05T12:00:00Z'),
        capacity: 300,
        cover_image_url: 'https://images.unsplash.com/photo-1544717297-fa95b6ee9643?w=800&h=400&fit=crop',
        status: 'ACTIVE',
        organization_id: organizations[3].organization_id,
        ticket_types: JSON.stringify([
          { name: 'Full Workshop', price: 49.99, description: 'Workshop + training materials' },
          { name: 'Basic Access', price: 29.99, description: 'Workshop attendance only' }
        ])
      },
      {
        title: 'Startup Pitch Night',
        description: 'Local entrepreneurs pitch their innovative ideas to investors and the community. Great networking opportunity for startups, investors, and tech enthusiasts.',
        category: 'Business',
        venue: 'Innovation Hub',
        location: 'Austin, TX',
        start_time: new Date('2025-10-03T18:00:00Z'),
        end_time: new Date('2025-10-03T21:00:00Z'),
        capacity: 250,
        cover_image_url: 'https://images.unsplash.com/photo-1559136555-9303baea8ebd?w=800&h=400&fit=crop',
        status: 'ACTIVE',
        organization_id: organizations[1].organization_id,
        ticket_types: JSON.stringify([
          { name: 'General Admission', price: 15.00, description: 'Event access + networking' },
          { name: 'Entrepreneur Pass', price: 0.00, description: 'Free for registered entrepreneurs' }
        ])
      },
      {
        title: 'Jazz Night Under the Stars',
        description: 'An intimate outdoor jazz performance featuring local musicians. Bring a blanket and enjoy an evening of smooth jazz under the night sky.',
        category: 'Music',
        venue: 'Riverside Park Pavilion',
        location: 'Portland, OR',
        start_time: new Date('2025-09-20T19:30:00Z'),
        end_time: new Date('2025-09-20T22:00:00Z'),
        capacity: 150,
        cover_image_url: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800&h=400&fit=crop',
        status: 'ACTIVE',
        organization_id: organizations[2].organization_id,
        ticket_types: JSON.stringify([
          { name: 'Standard Seating', price: 35.00, description: 'Lawn chair provided' },
          { name: 'Premium Table', price: 65.00, description: 'Reserved table for 2' }
        ])
      },
      {
        title: 'Holiday Craft Fair',
        description: 'Browse unique handmade crafts from local artisans. Perfect for holiday shopping! Features over 50 vendors selling jewelry, pottery, textiles, and more.',
        category: 'Shopping & Markets',
        venue: 'Community Center Main Hall',
        location: 'Denver, CO',
        start_time: new Date('2025-11-15T10:00:00Z'),
        end_time: new Date('2025-11-15T16:00:00Z'),
        capacity: 500,
        cover_image_url: 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=800&h=400&fit=crop',
        status: 'ACTIVE',
        organization_id: organizations[0].organization_id,
        ticket_types: JSON.stringify([
          { name: 'Entry Pass', price: 5.00, description: 'Fair admission' },
          { name: 'Family Pass', price: 15.00, description: 'Admission for up to 5 people' }
        ])
      }
    ];

    const events = [];
    for (const eventData of eventCategories) {
      const event = await prisma.event.create({
        data: eventData
      });
      events.push(event);
      console.log(`✅ Created event: ${event.title}`);
    }

    console.log('🎫 Creating sample ticket purchases...');
    
    // Create some sample ticket purchases
    const samplePurchases = [
      {
        user_id: users[3].user_id, // Emma Rodriguez
        event_id: events[0].event_id, // Summer Music Festival
        quantity: 2,
        total_amount: 299.98,
        ticket_type: 'General Admission',
        status: 'CONFIRMED'
      },
      {
        user_id: users[4].user_id, // David Johnson
        event_id: events[1].event_id, // Tech Summit
        quantity: 1,
        total_amount: 599.99,
        ticket_type: 'Full Conference Pass',
        status: 'CONFIRMED'
      },
      {
        user_id: users[5].user_id, // Lisa Park
        event_id: events[2].event_id, // Food & Wine
        quantity: 1,
        total_amount: 89.99,
        ticket_type: 'Premium Tasting',
        status: 'CONFIRMED'
      }
    ];

    for (const purchase of samplePurchases) {
      try {
        const ticketPurchase = await prisma.ticketPurchase.create({
          data: {
            ...purchase,
            purchase_date: new Date(),
            payment_status: 'COMPLETED'
          }
        });
        console.log(`✅ Created ticket purchase for ${purchase.ticket_type}`);
      } catch (error) {
        console.log(`⚠️ Skipped ticket purchase (table may not exist): ${error.message}`);
      }
    }

    console.log('🔍 Creating sample search logs...');
    
    // Create some search activity
    const searchQueries = [
      { user_id: users[3].user_id, search_query: 'music festival summer' },
      { user_id: users[4].user_id, search_query: 'tech conference AI' },
      { user_id: users[5].user_id, search_query: 'wine tasting events' },
      { user_id: null, search_query: 'art gallery opening' }, // Anonymous search
      { user_id: users[3].user_id, search_query: 'jazz concert outdoor' }
    ];

    for (const search of searchQueries) {
      try {
        await prisma.search_Log.create({
          data: search
        });
        console.log(`✅ Created search log: "${search.search_query}"`);
      } catch (error) {
        console.log(`⚠️ Skipped search log (table may not exist): ${error.message}`);
      }
    }

    console.log('\n🎉 Comprehensive seeding completed successfully!');
    console.log('📊 Summary:');
    console.log(`   • ${users.length} users created`);
    console.log(`   • ${organizations.length} organizations created`);
    console.log(`   • ${events.length} events created`);
    console.log(`   • ${samplePurchases.length} ticket purchases created`);
    console.log(`   • ${searchQueries.length} search logs created`);
    console.log('\n✅ Your database now has comprehensive sample data!');
    
  } catch (error) {
    console.error('❌ Comprehensive seeding failed:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

// Run if called directly
if (require.main === module) {
  comprehensiveSeed();
}

module.exports = { comprehensiveSeed };