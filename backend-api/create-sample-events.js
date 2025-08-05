// Test script to create sample events
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function createSampleEvents() {
  try {
    // Create a test organization first
    let organization;
    try {
      organization = await prisma.organization.create({
        data: {
          user_id: 1, // Assuming user with ID 1 exists
          name: 'Tech Events Co.',
          description: 'We organize amazing tech events',
          contact_email: 'contact@techevents.com',
        }
      });
      console.log('✅ Created organization:', organization);
    } catch (orgError) {
      console.log('Organization might already exist, continuing...');
      organization = await prisma.organization.findFirst();
    }

    // Create sample events
    const sampleEvents = [
      {
        title: 'Tech Conference 2025',
        description: 'A comprehensive tech conference featuring the latest innovations',
        category: 'Technology',
        venue: 'Convention Center',
        location: 'New York, NY',
        start_time: new Date('2025-09-15T09:00:00Z'),
        end_time: new Date('2025-09-15T18:00:00Z'),
        capacity: 500,
        status: 'published',
        cover_image_url: 'https://example.com/tech-conf.jpg',
        organization_id: organization?.organization_id || null,
      },
      {
        title: 'Startup Meetup',
        description: 'Network with fellow entrepreneurs and investors',
        category: 'Business',
        venue: 'WeWork Space',
        location: 'San Francisco, CA',
        start_time: new Date('2025-08-20T18:00:00Z'),
        end_time: new Date('2025-08-20T21:00:00Z'),
        capacity: 100,
        status: 'published',
        cover_image_url: 'https://example.com/startup-meetup.jpg',
        organization_id: organization?.organization_id || null,
      },
      {
        title: 'Music Festival',
        description: 'Three days of amazing music and entertainment',
        category: 'Entertainment',
        venue: 'Central Park',
        location: 'New York, NY',
        start_time: new Date('2025-07-01T12:00:00Z'),
        end_time: new Date('2025-07-03T23:00:00Z'),
        capacity: 10000,
        status: 'published',
        cover_image_url: 'https://example.com/music-fest.jpg',
        organization_id: organization?.organization_id || null,
      }
    ];

    for (const eventData of sampleEvents) {
      try {
        const event = await prisma.event.create({
          data: eventData
        });
        console.log('✅ Created event:', event.title);
      } catch (error) {
        console.log(`❌ Failed to create event ${eventData.title}:`, error.message);
      }
    }

    console.log('🎉 Sample events created successfully!');
  } catch (error) {
    console.error('❌ Error creating sample events:', error);
  } finally {
    await prisma.$disconnect();
  }
}

createSampleEvents();
