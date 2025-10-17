const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: "postgresql://postgres.ascylwnesivibozjatlq:rWvjd3ccDdfojRY4@aws-0-ap-south-1.pooler.supabase.com:6543/postgres?pgbouncer=true"
    }
  }
});

async function fixEvent() {
  try {
    console.log('Attempting to fix event 60...');
    
    // Update event 60 to set seat_map to a simple array
    const result = await prisma.$executeRaw`
      UPDATE "Event" 
      SET seat_map = '[]'::jsonb
      WHERE event_id = 60
    `;
    
    console.log('Event 60 updated successfully. Rows affected:', result);
    
    // Verify the update
    const event = await prisma.event.findUnique({
      where: { event_id: 60 },
      select: { event_id: true, title: true, seat_map: true }
    });
    
    console.log('Event 60 after update:', JSON.stringify(event, null, 2));
    
  } catch (error) {
    console.error('Error fixing event:', error);
  } finally {
    await prisma.$disconnect();
  }
}

fixEvent();
