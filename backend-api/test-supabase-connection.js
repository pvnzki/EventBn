const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: "postgresql://postgres.ascylwnesivibozjatlq:rWvjd3ccDdfojRY4@aws-0-ap-south-1.pooler.supabase.com:5432/postgres"
    }
  }
});

async function testConnection() {
  try {
    console.log('Testing direct connection to Supabase...\n');
    
    const result = await prisma.$queryRaw`SELECT COUNT(*) as count FROM "Event"`;
    console.log('✅ Connection successful!');
    console.log('Total events:', result[0].count);
    
  } catch (error) {
    console.error('❌ Connection failed:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

testConnection();
