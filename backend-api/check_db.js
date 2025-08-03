const { PrismaClient } = require('@prisma/client');
require('dotenv').config();

const prisma = new PrismaClient();

async function checkDatabase() {
  try {
    console.log('🔍 Checking database connection and users...');
    
    // Try a raw SQL query to see all users
    const result = await prisma.$queryRaw`SELECT user_id, name, email, role, is_active FROM "User" LIMIT 10`;
    
    console.log('📊 Raw SQL query result:');
    console.log(result);
    
    // Also check table existence
    const tables = await prisma.$queryRaw`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_type = 'BASE TABLE'
      ORDER BY table_name
    `;
    
    console.log('\n📋 Tables in database:');
    tables.forEach(table => console.log(`- ${table.table_name}`));
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('Full error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkDatabase();
