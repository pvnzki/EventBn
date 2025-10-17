const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: "postgresql://postgres.ascylwnesivibozjatlq:rWvjd3ccDdfojRY4@aws-0-ap-south-1.pooler.supabase.com:5432/postgres"
    }
  }
});

async function checkEvents() {
  try {
    console.log('Checking for events with large seat_map data...\n');
    
    // Get all events and check their seat_map sizes
    const events = await prisma.$queryRaw`
      SELECT 
        event_id, 
        title,
        LENGTH(seat_map::text) as seat_map_size,
        LENGTH(ticket_types::text) as ticket_types_size
      FROM "Event"
      WHERE seat_map IS NOT NULL
      ORDER BY LENGTH(seat_map::text) DESC
      LIMIT 10
    `;
    
    console.log('Top 10 events by seat_map size:');
    console.table(events);
    
    // Find events with seat_map over 100KB
    const largeEvents = events.filter(e => e.seat_map_size > 100000);
    
    if (largeEvents.length > 0) {
      console.log('\n⚠️  Events with large seat_map (>100KB):');
      largeEvents.forEach(e => {
        console.log(`  - Event ${e.event_id}: "${e.title}" - ${(e.seat_map_size / 1024).toFixed(2)}KB`);
      });
    } else {
      console.log('\n✅ No events with excessively large seat_map found');
    }
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

checkEvents();
