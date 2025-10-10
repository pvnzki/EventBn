const nodemailer = require('nodemailer');
const QRCode = require('qrcode');
const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs').promises;

class EmailService {
  constructor() {
    this.transporter = null;
    this.init();
  }

  async init() {
    try {
      // Check if email credentials are available
      if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
        console.log('⚠️ Email credentials not found in environment variables');
        console.log('📧 Email notifications will be disabled');
        console.log('💡 Add EMAIL_USER and EMAIL_PASS to your .env file');
        return;
      }

      // Create transporter
      this.transporter = nodemailer.createTransport({
        host: process.env.EMAIL_HOST || 'smtp.gmail.com',
        port: parseInt(process.env.EMAIL_PORT || '587'),
        secure: false, // true for 465, false for other ports
        auth: {
          user: process.env.EMAIL_USER,
          pass: process.env.EMAIL_PASS
        },
        tls: {
          rejectUnauthorized: false
        }
      });

      // Verify connection
      await this.transporter.verify();
      console.log('✅ Email service initialized successfully');
      console.log(`📧 Using email: ${process.env.EMAIL_USER}`);
    } catch (error) {
      console.error('❌ Email service initialization failed:', error.message);
      console.log('📧 Email notifications will be disabled');
      this.transporter = null;
    }
  }

  /**
   * Generate QR code as base64 image
   */
  async generateQRCode(data) {
    try {
      const qrCodeDataURL = await QRCode.toDataURL(data, {
        width: 200,
        margin: 2,
        color: {
          dark: '#000000',
          light: '#FFFFFF'
        }
      });
      return qrCodeDataURL;
    } catch (error) {
      console.error('Error generating QR code:', error);
      return null;
    }
  }

  /**
   * Generate PDF ticket using Puppeteer
   */
  async generateTicketPDF(ticketData) {
    let browser = null;
    try {
      // Generate QR code
      const qrCodeImage = await this.generateQRCode(ticketData.qr_code);
      
      // EventBn logo as base64 (small black logo)
      const eventbnLogo = 'data:image/svg+xml;base64,' + Buffer.from(`
        <svg width="120" height="40" viewBox="0 0 120 40" xmlns="http://www.w3.org/2000/svg">
          <text x="10" y="25" font-family="Arial, sans-serif" font-size="18" font-weight="bold" fill="#000">
            EventBn
          </text>
        </svg>
      `).toString('base64');
      
      // Create HTML template for the ticket
      const html = await this.createTicketHTML({
        ...ticketData,
        qrCodeImage,
        eventbnLogo
      });

      // Launch puppeteer
      browser = await puppeteer.launch({
        headless: 'new',
        args: ['--no-sandbox', '--disable-setuid-sandbox']
      });

      const page = await browser.newPage();
      await page.setContent(html, { waitUntil: 'networkidle0' });

      // Generate PDF - compact single page
      const pdfBuffer = await page.pdf({
        format: 'A4',
        margin: {
          top: '10px',
          right: '15px',
          bottom: '10px',
          left: '15px'
        },
        printBackground: true
      });

      return pdfBuffer;
    } catch (error) {
      console.error('Error generating PDF:', error);
      throw error;
    } finally {
      if (browser) {
        await browser.close();
      }
    }
  }

  /**
   * Create HTML template for ticket - Black & White, Compact Design
   */
  async createTicketHTML(data) {
    const {
      user_name,
      user_email,
      event_title,
      event_venue,
      event_location,
      event_start_time,
      seat_label,
      price,
      qr_code,
      qrCodeImage,
      payment_id,
      purchase_date,
      eventbnLogo
    } = data;

    // Format date and time
    const eventDate = new Date(event_start_time);
    const purchaseDate = new Date(purchase_date);
    
    const formattedEventDate = eventDate.toLocaleString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });

    const formattedPurchaseDate = purchaseDate.toLocaleString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });

    return `
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>EventBn E-Ticket</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Arial', sans-serif;
            background: white;
            color: black;
            font-size: 12px;
            line-height: 1.4;
        }
        
        .ticket-container {
            max-width: 100%;
            margin: 0;
            background: white;
            border: 2px solid black;
        }
        
        .ticket-header {
            background: white;
            color: black;
            padding: 15px;
            text-align: center;
            border-bottom: 2px solid black;
        }
        
        .logo {
            font-size: 20px;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .ticket-title {
            font-size: 14px;
            font-weight: normal;
        }
        
        .ticket-body {
            padding: 20px 15px;
        }
        
        .event-info {
            text-align: center;
            margin-bottom: 20px;
        }
        
        .event-title {
            font-size: 18px;
            font-weight: bold;
            color: black;
            margin-bottom: 10px;
        }
        
        .event-details {
            background: white;
            border: 1px solid black;
            padding: 15px;
            margin-bottom: 20px;
        }
        
        .detail-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 8px;
            padding: 4px 0;
            border-bottom: 1px solid #ccc;
        }
        
        .detail-row:last-child {
            border-bottom: none;
            margin-bottom: 0;
        }
        
        .detail-label {
            font-weight: bold;
            color: black;
            flex: 1;
        }
        
        .detail-value {
            color: black;
            text-align: right;
            flex: 1;
        }
        
        .qr-section {
            text-align: center;
            background: white;
            border: 1px solid black;
            padding: 15px;
            margin-bottom: 15px;
        }
        
        .qr-title {
            font-size: 14px;
            font-weight: bold;
            color: black;
            margin-bottom: 10px;
        }
        
        .qr-code {
            margin: 0 auto 10px;
        }
        
        .qr-text {
            font-size: 10px;
            color: black;
            font-family: monospace;
            word-break: break-all;
        }
        
        .ticket-footer {
            background: white;
            border-top: 1px solid black;
            padding: 10px 15px;
            text-align: center;
            color: black;
            font-size: 10px;
        }
        
        .important-note {
            background: white;
            border: 2px solid black;
            padding: 10px;
            margin: 15px 0;
            color: black;
            font-size: 11px;
        }
        
        .price {
            font-size: 14px;
            font-weight: bold;
            color: black;
        }

        .logo-container {
            text-align: center;
            margin-bottom: 10px;
        }

        .logo-image {
            height: 30px;
        }
    </style>
</head>
<body>
    <div class="ticket-container">
        <div class="ticket-header">
            <div class="logo-container">
                <img src="${eventbnLogo}" alt="EventBn" class="logo-image">
            </div>
            <div class="ticket-title">Electronic Ticket</div>
        </div>
        
        <div class="ticket-body">
            <div class="event-info">
                <h1 class="event-title">${event_title}</h1>
            </div>
            
            <div class="event-details">
                <div class="detail-row">
                    <span class="detail-label">Date & Time:</span>
                    <span class="detail-value">${formattedEventDate}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Venue:</span>
                    <span class="detail-value">${event_venue}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Location:</span>
                    <span class="detail-value">${event_location}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Seat/Ticket:</span>
                    <span class="detail-value">${seat_label}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Price:</span>
                    <span class="detail-value price">Rs. ${(price / 100).toFixed(2)}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Ticket Holder:</span>
                    <span class="detail-value">${user_name}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Purchase Date:</span>
                    <span class="detail-value">${formattedPurchaseDate}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Payment ID:</span>
                    <span class="detail-value">${payment_id}</span>
                </div>
            </div>
            
            <div class="qr-section">
                <div class="qr-title">Entry QR Code</div>
                ${qrCodeImage ? `<img src="${qrCodeImage}" alt="QR Code" class="qr-code">` : ''}
                <div class="qr-text">${qr_code}</div>
            </div>
            
            <div class="important-note">
                <strong>Important:</strong> Present this QR code at venue entrance. Keep ticket safe and bring backup on mobile device.
            </div>
        </div>
        
        <div class="ticket-footer">
            <p>Electronic ticket generated by EventBn | support@eventbn.com</p>
            <p>Thank you for choosing EventBn!</p>
        </div>
    </div>
</body>
</html>`;
  }

  /**
   * Send ticket email with PDF attachment
   */
  async sendTicketEmail(ticketData, userEmail) {
    if (!this.transporter) {
      console.log('Email service not available, skipping email send');
      return false;
    }

    try {
      // Generate PDF
      const pdfBuffer = await this.generateTicketPDF(ticketData);
      
      // Email content
      const subject = `🎫 Your EventBn Ticket - ${ticketData.event_title}`;
      const htmlContent = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: #000; color: white; padding: 30px; text-align: center;">
            <h1 style="margin: 0; font-size: 28px;">EventBn</h1>
            <p style="margin: 10px 0 0; font-size: 16px;">Your E-Ticket is Ready!</p>
          </div>
          
          <div style="background: white; padding: 30px; border: 1px solid #ddd;">
            <h2 style="color: #333;">Hello ${ticketData.user_name}!</h2>
            
            <p>Thank you for booking with EventBn! Your ticket for <strong>${ticketData.event_title}</strong> has been confirmed.</p>
            
            <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
              <h3 style="color: #333; margin-top: 0;">Event Details:</h3>
              <p><strong>Event:</strong> ${ticketData.event_title}</p>
              <p><strong>Date & Time:</strong> ${new Date(ticketData.event_start_time).toLocaleString()}</p>
              <p><strong>Venue:</strong> ${ticketData.event_venue}</p>
              <p><strong>Location:</strong> ${ticketData.event_location}</p>
              <p><strong>Seat/Ticket:</strong> ${ticketData.seat_label}</p>
            </div>
            
            <div style="background: #d4edda; border: 1px solid #c3e6cb; border-radius: 8px; padding: 15px; margin: 20px 0;">
              <p style="margin: 0; color: #155724;"><strong>✅ Payment Confirmed</strong></p>
              <p style="margin: 5px 0 0; color: #155724;">Amount: Rs. ${(ticketData.price / 100).toFixed(2)}</p>
            </div>
            
            <p><strong>📎 Your e-ticket is attached as a PDF.</strong> Please:</p>
            <ul>
              <li>Save this email and the PDF attachment</li>
              <li>Present the QR code at the venue entrance</li>
              <li>Arrive at least 30 minutes before the event starts</li>
              <li>Bring a valid ID for verification</li>
            </ul>
            
            <p>If you have any questions, please contact our support team.</p>
            
            <p>See you at the event!</p>
            <p><strong>The EventBn Team</strong></p>
          </div>
          
          <div style="background: #f8f9fa; padding: 20px; text-align: center; font-size: 12px; color: #666;">
            <p>This is an automated email from EventBn</p>
            <p>For support: support@eventbn.com</p>
          </div>
        </div>
      `;

      // Send email
      const info = await this.transporter.sendMail({
        from: process.env.EMAIL_FROM || 'EventBn <no-reply@eventbn.com>',
        to: userEmail,
        subject: subject,
        html: htmlContent,
        attachments: [
          {
            filename: `eventbn-ticket-${ticketData.qr_code}.pdf`,
            content: pdfBuffer,
            contentType: 'application/pdf'
          }
        ]
      });

      console.log('✅ Ticket email sent successfully:', info.messageId);
      return true;
    } catch (error) {
      console.error('❌ Error sending ticket email:', error);
      return false;
    }
  }

  /**
   * Send multiple tickets email (for bulk purchases)
   */
  async sendMultipleTicketsEmail(ticketsData, userEmail) {
    if (!this.transporter || !ticketsData || ticketsData.length === 0) {
      console.log('Email service not available or no tickets data, skipping email send');
      return false;
    }

    try {
      const firstTicket = ticketsData[0];
      const subject = `🎫 Your EventBn Tickets - ${firstTicket.event_title} (${ticketsData.length} tickets)`;
      
      // Generate PDFs for all tickets
      const attachments = [];
      for (let i = 0; i < ticketsData.length; i++) {
        const ticketData = ticketsData[i];
        const pdfBuffer = await this.generateTicketPDF(ticketData);
        attachments.push({
          filename: `eventbn-ticket-${i + 1}-${ticketData.qr_code}.pdf`,
          content: pdfBuffer,
          contentType: 'application/pdf'
        });
      }

      // Create email content
      const ticketsList = ticketsData.map((ticket, index) => `
        <li><strong>Ticket ${index + 1}:</strong> ${ticket.seat_label} - Rs. ${(ticket.price / 100).toFixed(2)}</li>
      `).join('');

      const totalAmount = ticketsData.reduce((sum, ticket) => sum + ticket.price, 0);

      const htmlContent = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: #000; color: white; padding: 30px; text-align: center;">
            <h1 style="margin: 0; font-size: 28px;">EventBn</h1>
            <p style="margin: 10px 0 0; font-size: 16px;">Your E-Tickets are Ready!</p>
          </div>
          
          <div style="background: white; padding: 30px; border: 1px solid #ddd;">
            <h2 style="color: #333;">Hello ${firstTicket.user_name}!</h2>
            
            <p>Thank you for booking with EventBn! Your ${ticketsData.length} ticket(s) for <strong>${firstTicket.event_title}</strong> have been confirmed.</p>
            
            <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
              <h3 style="color: #333; margin-top: 0;">Event Details:</h3>
              <p><strong>Event:</strong> ${firstTicket.event_title}</p>
              <p><strong>Date & Time:</strong> ${new Date(firstTicket.event_start_time).toLocaleString()}</p>
              <p><strong>Venue:</strong> ${firstTicket.event_venue}</p>
              <p><strong>Location:</strong> ${firstTicket.event_location}</p>
            </div>
            
            <div style="background: #e7f3ff; padding: 20px; border-radius: 8px; margin: 20px 0;">
              <h3 style="color: #333; margin-top: 0;">Your Tickets:</h3>
              <ul style="margin: 0; padding-left: 20px;">
                ${ticketsList}
              </ul>
            </div>
            
            <div style="background: #d4edda; border: 1px solid #c3e6cb; border-radius: 8px; padding: 15px; margin: 20px 0;">
              <p style="margin: 0; color: #155724;"><strong>✅ Payment Confirmed</strong></p>
              <p style="margin: 5px 0 0; color: #155724;">Total Amount: Rs. ${(totalAmount / 100).toFixed(2)}</p>
            </div>
            
            <p><strong>📎 Your e-tickets are attached as individual PDF files.</strong> Please:</p>
            <ul>
              <li>Save this email and all PDF attachments</li>
              <li>Each person should have their own ticket/QR code</li>
              <li>Present the QR codes at the venue entrance</li>
              <li>Arrive at least 30 minutes before the event starts</li>
              <li>Bring valid IDs for verification</li>
            </ul>
            
            <p>If you have any questions, please contact our support team.</p>
            
            <p>See you at the event!</p>
            <p><strong>The EventBn Team</strong></p>
          </div>
          
          <div style="background: #f8f9fa; padding: 20px; text-align: center; font-size: 12px; color: #666;">
            <p>This is an automated email from EventBn</p>
            <p>For support: support@eventbn.com</p>
          </div>
        </div>
      `;

      // Send email with all ticket attachments
      const info = await this.transporter.sendMail({
        from: process.env.EMAIL_FROM || 'EventBn <no-reply@eventbn.com>',
        to: userEmail,
        subject: subject,
        html: htmlContent,
        attachments: attachments
      });

      console.log(`✅ Multiple tickets email sent successfully (${ticketsData.length} tickets):`, info.messageId);
      return true;
    } catch (error) {
      console.error('❌ Error sending multiple tickets email:', error);
      return false;
    }
  }
}

module.exports = new EmailService();