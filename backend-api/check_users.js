const { PrismaClient } = require('@prisma/client');
require('dotenv').config();

console.log('🚀 Starting user check script...');
console.log('Database URL configured:', process.env.DATABASE_URL ? 'Yes' : 'No');

const prisma = new PrismaClient({
  log: ['query', 'info', 'warn', 'error'],
});

async function checkUsers() {
  try {
    console.log('🔍 Checking all users in the database...');
    
    const users = await prisma.user.findMany({
      select: {
        user_id: true,
        name: true,
        email: true,
        role: true,
        is_active: true,
        is_email_verified: true
      }
    });
    
    console.log(`📊 Total users found: ${users.length}`);
    
    if (users.length > 0) {
      console.log('\n👥 Users in database:');
      users.forEach((user, index) => {
        console.log(`${index + 1}. ID: ${user.user_id}`);
        console.log(`   Name: ${user.name}`);
        console.log(`   Email: ${user.email}`);
        console.log(`   Role: ${user.role}`);
        console.log(`   Active: ${user.is_active}`);
        console.log(`   Email Verified: ${user.is_email_verified}`);
        console.log(`   Created: ${user.created_at || 'N/A'}`);
        console.log('   ---');
      });
    } else {
      console.log('❌ No users found in the database');
    }
    
    // Check specifically for test3@example.com
    const testUser = await prisma.user.findUnique({
      where: { email: 'test3@example.com' }
    });
    
    if (testUser) {
      console.log('\n🎯 Found test3@example.com user:');
      console.log(JSON.stringify(testUser, null, 2));
    } else {
      console.log('\n❌ test3@example.com user NOT found');
    }
    
  } catch (error) {
    console.error('❌ Error checking users:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkUsers();
