# 📧 EventBn Automated Email Setup Guide

## Overview
Your EventBn system now has automated email functionality that sends beautiful PDF e-tickets to users immediately after successful ticket purchases.

## ✨ Features
- 🎫 **PDF E-Tickets**: Professional-looking tickets with QR codes
- 📧 **Automated Sending**: Emails sent immediately after payment
- 🖼️ **QR Code Generation**: Each ticket has a unique QR code
- 📱 **Mobile-Friendly**: Responsive email templates
- 🎨 **Branded Design**: EventBn-branded email templates
- 📄 **Multiple Tickets**: Handles single and bulk ticket purchases

## 🛠️ Setup Instructions

### 1. Email Configuration
Update your `.env` file with email settings:

```env
# Email Configuration (Gmail SMTP)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-gmail@gmail.com
EMAIL_PASS=your-app-password
EMAIL_FROM=EventBn <your-gmail@gmail.com>
```

### 2. Gmail Setup (Recommended)
1. **Enable 2-Factor Authentication** on your Gmail account
2. **Generate App Password**:
   - Go to Google Account settings
   - Security → 2-Step Verification → App passwords
   - Generate password for "Mail"
   - Use this password in `EMAIL_PASS`

### 3. Alternative Email Providers
You can also use other SMTP providers:

**SendGrid:**
```env
EMAIL_HOST=smtp.sendgrid.net
EMAIL_PORT=587
EMAIL_USER=apikey
EMAIL_PASS=your-sendgrid-api-key
```

**Mailgun:**
```env
EMAIL_HOST=smtp.mailgun.org
EMAIL_PORT=587
EMAIL_USER=your-mailgun-username
EMAIL_PASS=your-mailgun-password
```

**Outlook/Hotmail:**
```env
EMAIL_HOST=smtp-mail.outlook.com
EMAIL_PORT=587
EMAIL_USER=your-outlook@outlook.com
EMAIL_PASS=your-password
```

## 🧪 Testing

### Test Email Configuration
Run the test script to verify your email setup:

```bash
node test-email.js
```

This will send a test e-ticket to verify your configuration works.

### Manual Test
You can also test by making a ticket purchase through your app.

## 📋 How It Works

### 1. User Purchases Ticket
- User completes payment through your app
- Payment is processed and confirmed

### 2. Ticket Creation
- System creates ticket records in database
- Generates unique QR codes for each ticket

### 3. Email Generation
- Creates professional PDF tickets with:
  - Event details (name, date, time, venue)
  - User information
  - Seat/ticket information
  - QR code for entry
  - Payment confirmation

### 4. Email Delivery
- Sends HTML email with PDF attachment
- Works for single tickets or multiple tickets
- Includes booking confirmation and instructions

## 📁 Files Created/Modified

### New Files:
- `services/core-service/email/index.js` - Email service
- `test-email.js` - Email testing script

### Modified Files:
- `routes/payments.js` - Added email sending after ticket creation
- `.env` - Added email configuration
- `package.json` - Added dependencies (nodemailer, puppeteer, qrcode)

## 🔧 Troubleshooting

### Common Issues:

**1. "Email service initialization failed"**
- Check your email credentials in `.env`
- Verify SMTP settings for your provider
- For Gmail, ensure you're using an App Password

**2. "PDF generation failed"**
- Puppeteer might need additional setup on some systems
- Try restarting the server

**3. "QR code not showing"**
- Check if the `qrcode` package is properly installed
- Verify ticket data includes `qr_code` field

**4. Emails not receiving**
- Check spam/junk folder
- Verify email address is correct
- Check email service logs in console

### Debug Mode:
The system will log email status:
- ✅ Success: "Ticket email sent successfully"
- ❌ Failure: "Failed to send ticket email"
- ⚠️ Disabled: "Email service not available"

## 📧 Email Template Features

### Single Ticket Email:
- Subject: "🎫 Your EventBn Ticket - [Event Name]"
- HTML formatted with event details
- PDF attachment with QR code
- Instructions for venue entry

### Multiple Tickets Email:
- Subject: "🎫 Your EventBn Tickets - [Event Name] (X tickets)"
- List of all purchased tickets
- Individual PDF for each ticket
- Bulk booking confirmation

## 🎨 Customization

### Email Templates:
You can customize the email HTML in:
`services/core-service/email/index.js`

### PDF Styling:
Modify the CSS in the `createTicketHTML` method to change:
- Colors and branding
- Layout and typography
- Logo and images

### QR Code Settings:
Adjust QR code appearance in the `generateQRCode` method

## 🚀 Production Recommendations

1. **Use Professional Email Service**: SendGrid, Mailgun, or AWS SES
2. **Set Up SPF/DKIM**: Improve deliverability
3. **Monitor Email Logs**: Track delivery success
4. **Backup Email Settings**: Keep credentials secure
5. **Test Regularly**: Ensure emails work after updates

## 📞 Support

If you encounter issues:
1. Check console logs for error messages
2. Run the test email script
3. Verify all environment variables are set
4. Check your email provider's documentation

---

**🎉 Your automated email system is now ready!**
Users will receive beautiful PDF e-tickets immediately after booking.