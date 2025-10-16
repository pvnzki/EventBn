const nodemailer = require("nodemailer")
const QRCode = require("qrcode")
const puppeteer = require("puppeteer")
const path = require("path")
const fs = require("fs").promises

class EmailService {
  constructor() {
    this.transporter = null
    this.init()
  }

  async init() {
    try {
      // Check if email credentials are available
      if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
        console.log("⚠️ Email credentials not found in environment variables")
        console.log("📧 Email notifications will be disabled")
        console.log("💡 Add EMAIL_USER and EMAIL_PASS to your .env file")
        return
      }

      // Create transporter
      this.transporter = nodemailer.createTransport({
        host: process.env.EMAIL_HOST || "smtp.gmail.com",
        port: Number.parseInt(process.env.EMAIL_PORT || "587"),
        secure: false, // true for 465, false for other ports
        auth: {
          user: process.env.EMAIL_USER,
          pass: process.env.EMAIL_PASS,
        },
        tls: {
          rejectUnauthorized: false,
        },
      })

      // Verify connection
      await this.transporter.verify()
      console.log("✅ Email service initialized successfully")
      console.log(`📧 Using email: ${process.env.EMAIL_USER}`)
    } catch (error) {
      console.error("❌ Email service initialization failed:", error.message)
      console.log("📧 Email notifications will be disabled")
      this.transporter = null
    }
  }

  /**
   * Send a generic email
   */
  async sendEmail({ to, subject, text, html }) {
    if (!this.transporter) {
      console.log("Email service not available, skipping email send")
      return false
    }

    try {
      const info = await this.transporter.sendMail({
        from: `"EventBn" <${process.env.EMAIL_USER}>`,
        to: to,
        subject: subject,
        text: text,
        html: html
      })

      console.log(`✅ Email sent successfully to ${to}`)
      console.log(`📧 Message ID: ${info.messageId}`)
      return true
    } catch (error) {
      console.error(`❌ Error sending email to ${to}:`, error)
      throw error
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
          dark: "#000000",
          light: "#FFFFFF",
        },
      })
      return qrCodeDataURL
    } catch (error) {
      console.error("Error generating QR code:", error)
      return null
    }
  }

  /**
   * Convert logo image to base64
   */
  async getLogoBase64() {
    try {
      const logoPath = path.join(__dirname, "../assets/images/White icon logo transparent.png")
      const logoBuffer = await fs.readFile(logoPath)
      const logoBase64 = `data:image/png;base64,${logoBuffer.toString("base64")}`
      return logoBase64
    } catch (error) {
      console.error("Error loading logo:", error)
      console.log("Logo not found, continuing without logo")
      return null
    }
  }

  /**
   * Generate PDF ticket using Puppeteer
   */
  async generateTicketPDF(ticketData) {
    let browser = null
    try {
      // Generate QR code
      const qrCodeImage = await this.generateQRCode(ticketData.qr_code)

      // Get logo base64
      const logoImage = await this.getLogoBase64()

      // Create HTML template for the ticket
      const html = await this.createTicketHTML({
        ...ticketData,
        qrCodeImage,
        logoImage,
      })

      // Launch puppeteer
      browser = await puppeteer.launch({
        headless: "new",
        args: ["--no-sandbox", "--disable-setuid-sandbox"],
      })

      const page = await browser.newPage()
      await page.setContent(html, { waitUntil: "networkidle0" })

      // Generate PDF
      const pdfBuffer = await page.pdf({
        format: "A4",
        margin: {
          top: "10px",
          right: "10px",
          bottom: "10px",
          left: "10px",
        },
        printBackground: true,
      })

      return pdfBuffer
    } catch (error) {
      console.error("Error generating PDF:", error)
      throw error
    } finally {
      if (browser) {
        await browser.close()
      }
    }
  }

  /**
   * Create HTML template for ticket
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
      logoImage,
      payment_id,
      purchase_date,
    } = data

    // Format date and time
    const eventDate = new Date(event_start_time)
    const purchaseDate = new Date(purchase_date)

    const formattedEventDate = eventDate.toLocaleString("en-US", {
      weekday: "long",
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    })

    const formattedPurchaseDate = purchaseDate.toLocaleString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    })

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
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Helvetica Neue', Arial, sans-serif;
            background: #fafafa;
            padding: 15px;
            color: #1a1a1a;
            line-height: 1.4;
        }
        
        .ticket-container {
            max-width: 600px;
            margin: 0 auto;
            background: white;
            border: 1px solid #e5e5e5;
            overflow: hidden;
        }
        
        .ticket-header {
            background: #1a1a1a;
            color: white;
            text-align: center;
            padding: 20px;
        }
        
        .logo-container {
            display: flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 8px;
        }
        
        .logo-image {
            width: 32px;
            height: 32px;
            margin-right: 10px;
            filter: brightness(0) invert(1);
        }
        
        .logo-text {
            font-size: 24px;
            font-weight: 300;
            color: white;
            letter-spacing: 2px;
        }
        
        .ticket-title {
            font-size: 10px;
            color: rgba(255,255,255,0.6);
            text-transform: uppercase;
            letter-spacing: 2px;
            font-weight: 400;
        }
        
        .ticket-body {
            padding: 25px;
            background: white;
        }
        
        .event-title {
            font-size: 22px;
            font-weight: 300;
            color: #1a1a1a;
            text-align: center;
            margin-bottom: 20px;
            letter-spacing: 0.5px;
            line-height: 1.3;
        }
        
        .ticket-details {
            margin-bottom: 20px;
            border-top: 1px solid #e5e5e5;
            border-bottom: 1px solid #e5e5e5;
            padding: 15px 0;
        }
        
        .detail-row {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            align-items: baseline;
        }
        
        .detail-label {
            font-weight: 400;
            color: #666;
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .detail-value {
            color: #1a1a1a;
            text-align: right;
            font-size: 13px;
            font-weight: 400;
        }
        
        .qr-section {
            text-align: center;
            padding: 20px;
            border: 1px solid #e5e5e5;
            margin: 0 0 20px 0;
        }
        
        .qr-title {
            font-size: 10px;
            font-weight: 400;
            color: #666;
            margin-bottom: 12px;
            text-transform: uppercase;
            letter-spacing: 2px;
        }
        
        .qr-code {
            margin: 0 auto 12px;
            display: block;
            border: 1px solid #e5e5e5;
            padding: 10px;
            background: white;
        }
        
        .qr-text {
            font-size: 9px;
            color: #999;
            font-family: 'Courier New', monospace;
            word-break: break-all;
            margin-top: 10px;
            letter-spacing: 0.5px;
        }
        
        .ticket-footer {
            text-align: center;
            padding: 15px 25px;
            background: #fafafa;
            font-size: 10px;
            color: #999;
            line-height: 1.6;
            border-top: 1px solid #e5e5e5;
        }
        
        .ticket-footer p {
            margin: 4px 0;
        }
        
        .important-note {
            background: #fafafa;
            color: #1a1a1a;
            padding: 12px;
            margin: 0 0 20px 0;
            font-size: 11px;
            text-align: center;
            border: 1px solid #e5e5e5;
            font-weight: 400;
            letter-spacing: 0.5px;
        }
        
        .price {
            font-size: 13px;
            font-weight: 400;
            color: #1a1a1a;
        }
        
        .ticket-id {
            text-align: center;
            font-size: 10px;
            color: #999;
            margin-top: 10px;
            font-family: 'Courier New', monospace;
            letter-spacing: 1px;
        }
    </style>
</head>
<body>
    <div class="ticket-container">
        <div class="ticket-header">
            <div class="logo-container">
                ${logoImage ? `<img src="${logoImage}" alt="EventBn Logo" class="logo-image">` : ""}
                <div class="logo-text">EVENTBN</div>
            </div>
            <div class="ticket-title">Electronic Ticket</div>
        </div>
        
        <div class="ticket-body">
            <div class="event-title">${event_title}</div>
            
            <div class="important-note">
                Present this QR code at the entrance for entry
            </div>
            
            <div class="ticket-details">
                <div class="detail-row">
                    <span class="detail-label">Attendee</span>
                    <span class="detail-value">${user_name}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Ticket Type</span>
                    <span class="detail-value">${seat_label}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Amount Paid</span>
                    <span class="detail-value price">LKR ${(price / 100).toFixed(2)}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Reference</span>
                    <span class="detail-value">${payment_id.substring(0, 12)}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Venue</span>
                    <span class="detail-value">${event_venue}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Date</span>
                    <span class="detail-value">${eventDate.toLocaleDateString("en-GB", { weekday: "long", year: "numeric", month: "long", day: "numeric" })}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Time</span>
                    <span class="detail-value">${eventDate.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" })}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-label">Purchased</span>
                    <span class="detail-value">${purchaseDate.toLocaleDateString("en-GB")}</span>
                </div>
            </div>
            
            <div class="qr-section">
                <div class="qr-title">Scan for Entry</div>
                ${qrCodeImage ? `<img src="${qrCodeImage}" alt="QR Code" class="qr-code" width="160" height="160">` : ""}
                <div class="ticket-id">Ticket ID: ${qr_code.substring(qr_code.lastIndexOf("_") + 1)}</div>
            </div>
            
            <div class="ticket-footer">
                <p>EventBn — Your Gateway to Amazing Events</p>
                <p>support@eventbn.com</p>
                <p>This is a valid electronic ticket. No physical ticket required.</p>
            </div>
        </div>
    </div>
</body>
</html>`
  }

  /**
   * Send ticket email with PDF attachment
   */
  async sendTicketEmail(ticketData, userEmail) {
    if (!this.transporter) {
      console.log("Email service not available, skipping email send")
      return false
    }

    try {
      // Generate PDF
      const pdfBuffer = await this.generateTicketPDF(ticketData)

      // Email content
      const subject = `🎫 Your EventBn Ticket - ${ticketData.event_title}`
      const htmlContent = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
            <h1 style="margin: 0; font-size: 28px;">EventBn</h1>
            <p style="margin: 10px 0 0; font-size: 16px;">Your E-Ticket is Ready!</p>
          </div>
          
          <div style="background: white; padding: 30px; border: 1px solid #ddd; border-top: none;">
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
          
          <div style="background: #f8f9fa; padding: 20px; text-align: center; border-radius: 0 0 10px 10px; font-size: 12px; color: #666;">
            <p>This is an automated email from EventBn</p>
            <p>For support: support@eventbn.com</p>
          </div>
        </div>
      `

      // Send email
      const info = await this.transporter.sendMail({
        from: process.env.EMAIL_FROM || "EventBn <no-reply@eventbn.com>",
        to: userEmail,
        subject: subject,
        html: htmlContent,
        attachments: [
          {
            filename: `eventbn-ticket-${ticketData.qr_code}.pdf`,
            content: pdfBuffer,
            contentType: "application/pdf",
          },
        ],
      })

      console.log("✅ Ticket email sent successfully:", info.messageId)
      return true
    } catch (error) {
      console.error("❌ Error sending ticket email:", error)
      return false
    }
  }

  /**
   * Send multiple tickets email (for bulk purchases)
   */
  async sendMultipleTicketsEmail(ticketsData, userEmail) {
    if (!this.transporter || !ticketsData || ticketsData.length === 0) {
      console.log("Email service not available or no tickets data, skipping email send")
      return false
    }

    try {
      const firstTicket = ticketsData[0]
      const subject = `🎫 Your EventBn Tickets - ${firstTicket.event_title} (${ticketsData.length} tickets)`

      // Generate PDFs for all tickets
      const attachments = []
      for (let i = 0; i < ticketsData.length; i++) {
        const ticketData = ticketsData[i]
        const pdfBuffer = await this.generateTicketPDF(ticketData)
        attachments.push({
          filename: `eventbn-ticket-${i + 1}-${ticketData.qr_code}.pdf`,
          content: pdfBuffer,
          contentType: "application/pdf",
        })
      }

      // Create email content
      const ticketsList = ticketsData
        .map(
          (ticket, index) => `
        <li><strong>Ticket ${index + 1}:</strong> ${ticket.seat_label} - Rs. ${(ticket.price / 100).toFixed(2)}</li>
      `,
        )
        .join("")

      const totalAmount = ticketsData.reduce((sum, ticket) => sum + ticket.price, 0)

      const htmlContent = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
            <h1 style="margin: 0; font-size: 28px;">EventBn</h1>
            <p style="margin: 10px 0 0; font-size: 16px;">Your E-Tickets are Ready!</p>
          </div>
          
          <div style="background: white; padding: 30px; border: 1px solid #ddd; border-top: none;">
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
          
          <div style="background: #f8f9fa; padding: 20px; text-align: center; border-radius: 0 0 10px 10px; font-size: 12px; color: #666;">
            <p>This is an automated email from EventBn</p>
            <p>For support: support@eventbn.com</p>
          </div>
        </div>
      `

      // Send email with all ticket attachments
      const info = await this.transporter.sendMail({
        from: process.env.EMAIL_FROM || "EventBn <no-reply@eventbn.com>",
        to: userEmail,
        subject: subject,
        html: htmlContent,
        attachments: attachments,
      })

      console.log(`✅ Multiple tickets email sent successfully (${ticketsData.length} tickets):`, info.messageId)
      return true
    } catch (error) {
      console.error("❌ Error sending multiple tickets email:", error)
      return false
    }
  }
}

module.exports = new EmailService()