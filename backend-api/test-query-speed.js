const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: "postgresql://postgres.ascylwnesivibozjatlq:rWvjd3ccDdfojRY4@aws-0-ap-south-1.pooler.supabase.com:5432/postgres"
    }
  },
  log: ['query', 'info', 'warn', 'error'],
});

async function testQuerySpeed() {
  try {
    console.log('Testing event fetch speed...\n');
    
    const start = Date.now();
    
    const events = await prisma.event.findMany({
      orderBy: { start_time: "asc" },
      take: 10,
      select: {
        event_id: true,
        title: true,
        description: true,
        category: true,
        venue: true,
        location: true,
        start_time: true,
        end_time: true,
        capacity: true,
        cover_image_url: true,
        status: true,
        created_at: true,
        organization_id: true,
      },
    });
    
    const end = Date.now();
    const duration = end - start;
    
    console.log(`\n✅ Query completed in ${duration}ms`);
    console.log(`Found ${events.length} events\n`);
    
    if (duration > 1000) {
      console.log('⚠️  Query is SLOW (>1 second)');
    } else if (duration > 500) {
      console.log('⚠️  Query is somewhat slow (>500ms)');
    } else {
      console.log('✅ Query speed is acceptable (<500ms)');
    }
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

testQuerySpeed();
