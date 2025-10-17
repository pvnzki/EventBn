const prisma = require('./lib/database');
const { Decimal } = require('@prisma/client/runtime/library');

async function createPaymentsAndTickets() {
  console.log('💳 Creating payments and ticket purchases...');
  
  try {
    // Get existing users and events
    const users = await prisma.user.findMany({
      where: {
        role: 'USER'
      }
    });
    
    const events = await prisma.event.findMany();
    
    if (users.length === 0 || events.length === 0) {
      console.log('❌ No users or events found. Please run comprehensive-seed.js first.');
      return;
    }

    console.log(`Found ${users.length} users and ${events.length} events`);

    // Create payments first
    const paymentData = [
      {
        user_id: users[0].user_id, // Emma Rodriguez
        event_id: events[0].event_id, // Summer Music Festival
        amount: new Decimal('299.98'),
        status: 'completed',
        payment_method: 'credit_card',
        transaction_ref: 'txn_music_fest_001'
      },
      {
        user_id: users[1].user_id, // David Johnson
        event_id: events[1].event_id, // Tech Innovation Summit
        amount: new Decimal('599.99'),
        status: 'completed',
        payment_method: 'paypal',
        transaction_ref: 'txn_tech_summit_001'
      },
      {
        user_id: users[2].user_id, // Lisa Park
        event_id: events[2].event_id, // Food & Wine Experience
        amount: new Decimal('89.99'),
        status: 'completed',
        payment_method: 'credit_card',
        transaction_ref: 'txn_wine_tasting_001'
      },
      {
        user_id: users[0].user_id, // Emma Rodriguez (second purchase)
        event_id: events[3].event_id, // Art Gallery Opening
        amount: new Decimal('75.00'),
        status: 'completed',
        payment_method: 'debit_card',
        transaction_ref: 'txn_art_gallery_001'
      },
      {
        user_id: users[1].user_id, // David Johnson (second purchase)
        event_id: events[4].event_id, // Marathon Training Workshop
        amount: new Decimal('49.99'),
        status: 'pending',
        payment_method: 'bank_transfer',
        transaction_ref: 'txn_marathon_001'
      }
    ];

    const payments = [];
    for (const payment of paymentData) {
      const createdPayment = await prisma.payment.create({
        data: payment
      });
      payments.push(createdPayment);
      console.log(`✅ Created payment: $${payment.amount} for user ${payment.user_id}`);
    }

    // Create ticket purchases
    const ticketData = [
      {
        event_id: events[0].event_id, // Summer Music Festival
        user_id: users[0].user_id,
        payment_id: payments[0].payment_id,
        seat_label: 'General-A-101',
        purchase_date: new Date('2025-06-15T10:30:00Z'),
        price: BigInt(14999), // $149.99 in cents
        attended: false
      },
      {
        event_id: events[0].event_id, // Summer Music Festival (second ticket)
        user_id: users[0].user_id,
        payment_id: payments[0].payment_id,
        seat_label: 'General-A-102',
        purchase_date: new Date('2025-06-15T10:30:00Z'),
        price: BigInt(14999), // $149.99 in cents
        attended: false
      },
      {
        event_id: events[1].event_id, // Tech Innovation Summit
        user_id: users[1].user_id,
        payment_id: payments[1].payment_id,
        seat_label: 'Conference-VIP-001',
        purchase_date: new Date('2025-07-10T14:15:00Z'),
        price: BigInt(59999), // $599.99 in cents
        attended: false
      },
      {
        event_id: events[2].event_id, // Food & Wine Experience
        user_id: users[2].user_id,
        payment_id: payments[2].payment_id,
        seat_label: 'Table-Premium-05',
        purchase_date: new Date('2025-08-20T16:45:00Z'),
        price: BigInt(8999), // $89.99 in cents
        attended: false
      },
      {
        event_id: events[3].event_id, // Art Gallery Opening
        user_id: users[0].user_id,
        payment_id: payments[3].payment_id,
        seat_label: 'Patron-Access-001',
        purchase_date: new Date('2025-08-01T09:20:00Z'),
        price: BigInt(7500), // $75.00 in cents
        attended: false
      },
      {
        event_id: events[4].event_id, // Marathon Training Workshop
        user_id: users[1].user_id,
        payment_id: payments[4].payment_id,
        seat_label: 'Workshop-Spot-025',
        purchase_date: new Date('2025-08-25T11:00:00Z'),
        price: BigInt(4999), // $49.99 in cents
        attended: false
      }
    ];

    const tickets = [];
    for (const ticket of ticketData) {
      const createdTicket = await prisma.ticketPurchase.create({
        data: ticket
      });
      tickets.push(createdTicket);
      console.log(`✅ Created ticket: ${ticket.seat_label} - $${(Number(ticket.price) / 100).toFixed(2)}`);
    }

    // Create some additional pending/failed payments for realism
    const additionalPayments = [
      {
        user_id: users[2].user_id,
        event_id: events[5].event_id, // Startup Pitch Night
        amount: new Decimal('15.00'),
        status: 'failed',
        payment_method: 'credit_card',
        transaction_ref: 'txn_startup_failed_001'
      },
      {
        user_id: users[0].user_id,
        event_id: events[6].event_id, // Jazz Night
        amount: new Decimal('65.00'),
        status: 'pending',
        payment_method: 'bank_transfer',
        transaction_ref: 'txn_jazz_pending_001'
      }
    ];

    for (const payment of additionalPayments) {
      await prisma.payment.create({
        data: payment
      });
      console.log(`✅ Created ${payment.status} payment: $${payment.amount}`);
    }

    console.log('\n🎉 Payments and tickets created successfully!');
    console.log('📊 Summary:');
    console.log(`   • ${payments.length + additionalPayments.length} payments created`);
    console.log(`   • ${tickets.length} tickets purchased`);
    console.log(`   • Payment statuses: completed, pending, failed`);
    console.log(`   • Various payment methods: credit_card, paypal, debit_card, bank_transfer`);
    
  } catch (error) {
    console.error('❌ Payment and ticket creation failed:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

// Run if called directly
if (require.main === module) {
  createPaymentsAndTickets();
}

module.exports = { createPaymentsAndTickets };