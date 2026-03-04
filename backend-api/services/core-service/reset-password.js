const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');
const prisma = new PrismaClient();

async function main() {
  const hash = await bcrypt.hash('Test@1234', 12);
  console.log('New hash:', hash);

  // Verify hash works before saving
  const verify = await bcrypt.compare('Test@1234', hash);
  console.log('Verify before update:', verify);

  // Update ALL users
  const users = await prisma.user.findMany({ select: { user_id: true, email: true } });
  for (const user of users) {
    await prisma.user.update({
      where: { user_id: user.user_id },
      data: { password_hash: hash },
    });
    console.log(`Updated: ${user.user_id} ${user.email}`);
  }

  // Final verification
  const check = await prisma.user.findUnique({ where: { user_id: 146 }, select: { password_hash: true } });
  const finalCheck = await bcrypt.compare('Test@1234', check.password_hash);
  console.log('Final verify from DB:', finalCheck);

  await prisma.$disconnect();
}

main().catch(e => { console.error(e); process.exit(1); });
