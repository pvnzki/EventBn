const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: "postgresql://postgres.ascylwnesivibozjatlq:rWvjd3ccDdfojRY4@aws-0-ap-south-1.pooler.supabase.com:5432/postgres"
    }
  }
});

async function cleanEvent57() {
  try {
    console.log('Checking event 57...\n');
    
    // Get event 57
    const event = await prisma.event.findUnique({
      where: { event_id: 57 },
      select: { event_id: true, title: true, seat_map: true }
    });
    
    if (!event) {
      console.log('Event 57 not found');
      return;
    }
    
    console.log('Event 57:', event.title);
    console.log('Seat map type:', typeof event.seat_map);
    console.log('Seat map keys:', Object.keys(event.seat_map || {}));
    
    // Check if seat_map has an 'image' field with base64 data
    if (event.seat_map && typeof event.seat_map === 'object') {
      if (event.seat_map.image && event.seat_map.image.startsWith('data:image')) {
        console.log('\n⚠️  Found base64 image in seat_map! Cleaning...\n');
        
        // Extract just the seats array if it exists
        const cleanedSeatMap = event.seat_map.seats || [];
        
        // Update the event
        await prisma.event.update({
          where: { event_id: 57 },
          data: { seat_map: cleanedSeatMap }
        });
        
        console.log('✅ Event 57 cleaned! Removed', (event.seat_map.image.length / 1024).toFixed(2), 'KB of image data');
      } else if (Array.isArray(event.seat_map)) {
        console.log('✅ Seat map is already clean (array format)');
      } else if (event.seat_map.seats && Array.isArray(event.seat_map.seats)) {
        console.log('\n⚠️  Seat map has nested structure. Flattening...\n');
        
        await prisma.event.update({
          where: { event_id: 57 },
          data: { seat_map: event.seat_map.seats }
        });
        
        console.log('✅ Event 57 flattened!');
      } else {
        console.log('✅ No image data found, but structure might be optimizable');
        console.log('Current structure:', JSON.stringify(event.seat_map).substring(0, 200) + '...');
      }
    }
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

cleanEvent57();
