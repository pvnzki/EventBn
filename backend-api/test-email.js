// Load environment variables
require('dotenv').config();

const emailService = require('./services/core-service/email');

// Test email configuration
async function testEmail() {
  console.log('🧪 Testing email configuration...');
  
  // Debug environment variables
  console.log('📧 Email configuration:');
  console.log(`   EMAIL_HOST: ${process.env.EMAIL_HOST || 'Not set'}`);
  console.log(`   EMAIL_PORT: ${process.env.EMAIL_PORT || 'Not set'}`);
  console.log(`   EMAIL_USER: ${process.env.EMAIL_USER || 'Not set'}`);
  console.log(`   EMAIL_PASS: ${process.env.EMAIL_PASS ? '[SET]' : 'Not set'}`);
  console.log(`   EMAIL_FROM: ${process.env.EMAIL_FROM || 'Not set'}`);
  console.log('');
  
  // Mock ticket data for testing
  const mockTicketData = {
    user_name: 'John Doe',
    user_email: 'test@example.com', // Change this to your email for testing
    event_title: 'Test Concert 2025',
    event_venue: 'Colombo Convention Center',
    event_location: 'Colombo, Sri Lanka',
    event_start_time: new Date('2025-12-31T20:00:00Z'),
    seat_label: 'VIP Section - A12',
    price: 2500, // In cents (Rs. 25.00)
    qr_code: 'TEST_TICKET_12345_67890',
    payment_id: 'test-payment-id-123',
    purchase_date: new Date()
  };

  try {
    const success = await emailService.sendTicketEmail(mockTicketData, mockTicketData.user_email);
    
    if (success) {
      console.log('✅ Test email sent successfully!');
      console.log('📧 Check your email inbox for the test ticket');
    } else {
      console.log('❌ Test email failed to send');
      console.log('💡 Check your email configuration in .env file');
    }
  } catch (error) {
    console.error('❌ Test email error:', error);
  }
  
  process.exit(0);
}

// Run test if this file is executed directly
if (require.main === module) {
  testEmail();
}

module.exports = { testEmail };