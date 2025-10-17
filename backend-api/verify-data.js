const prisma = require('./lib/database');

async function verifyData() {
  console.log('🔍 Verifying database data...');
  
  try {
    // Check payments
    const payments = await prisma.payment.findMany({
      include: {
        user: { select: { name: true, email: true } },
        event: { select: { title: true } }
      }
    });
    
    console.log(`\n💳 PAYMENTS (${payments.length} total):`);
    payments.forEach(payment => {
      console.log(`  • $${payment.amount} - ${payment.status.toUpperCase()} - ${payment.user.name} for "${payment.event.title}"`);
    });

    // Check ticket purchases
    const tickets = await prisma.ticketPurchase.findMany({
      include: {
        user: { select: { name: true } },
        event: { select: { title: true } },
        payment: { select: { amount: true, status: true } }
      }
    });
    
    console.log(`\n🎫 TICKET PURCHASES (${tickets.length} total):`);
    tickets.forEach(ticket => {
      const price = (Number(ticket.price) / 100).toFixed(2);
      console.log(`  • ${ticket.seat_label} - $${price} - ${ticket.user.name} for "${ticket.event.title}"`);
    });

    // Check events with ticket sales
    const eventsWithSales = await prisma.event.findMany({
      include: {
        ticket_purchases: true,
        payments: true,
        _count: {
          select: {
            ticket_purchases: true,
            payments: true
          }
        }
      }
    });

    console.log(`\n🎉 EVENTS WITH SALES:`);
    eventsWithSales.forEach(event => {
      if (event._count.ticket_purchases > 0 || event._count.payments > 0) {
        console.log(`  • "${event.title}" - ${event._count.ticket_purchases} tickets, ${event._count.payments} payments`);
      }
    });

    // Summary statistics
    const totalRevenue = payments
      .filter(p => p.status === 'completed')
      .reduce((sum, p) => sum + Number(p.amount), 0);
    
    const pendingRevenue = payments
      .filter(p => p.status === 'pending')
      .reduce((sum, p) => sum + Number(p.amount), 0);

    console.log(`\n📊 REVENUE SUMMARY:`);
    console.log(`  • Completed: $${totalRevenue.toFixed(2)}`);
    console.log(`  • Pending: $${pendingRevenue.toFixed(2)}`);
    console.log(`  • Total Tickets Sold: ${tickets.length}`);

    console.log('\n✅ Database verification complete!');
    
  } catch (error) {
    console.error('❌ Verification failed:', error);
  } finally {
    await prisma.$disconnect();
  }
}

verifyData();