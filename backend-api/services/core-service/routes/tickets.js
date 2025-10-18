const express = require("express");
const router = express.Router();
const { authenticateToken } = require("../middleware/auth");
const prisma = require("../lib/database");

console.log("✅ Tickets router loaded successfully");

// Test route to verify routing is working
router.get("/test", (req, res) => {
  res.json({
    success: true,
    message: "Tickets router is working!",
    timestamp: new Date().toISOString(),
  });
});

// Get user's tickets
router.get("/my-tickets", authenticateToken, async (req, res) => {
  try {
    const user_id = req.user.user_id;

    const tickets = await prisma.ticketPurchase.findMany({
      where: { user_id: user_id },
      include: {
        event: {
          select: {
            title: true,
            start_time: true,
            venue: true,
            location: true,
            cover_image_url: true,
          },
        },
        payment: {
          select: {
            payment_id: true,
            status: true,
            payment_method: true,
          },
        },
      },
      orderBy: {
        purchase_date: "desc",
      },
    });

    // Convert BigInt values to numbers for JSON serialization
    const serializedTickets = tickets.map((ticket) => ({
      ...ticket,
      price: Number(ticket.price), // Convert BigInt to Number
      user_id: Number(ticket.user_id),
      event_id: Number(ticket.event_id),
    }));

    res.json({
      success: true,
      tickets: serializedTickets,
    });
  } catch (error) {
    console.error("Error fetching tickets:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch tickets",
      error: error.message,
    });
  }
});

// Get ticket by QR code (for event organizers to scan)
router.get("/qr/:qrCode", authenticateToken, async (req, res) => {
  try {
    const { qrCode } = req.params;

    const ticket = await prisma.ticketPurchase.findFirst({
      where: { qr_code: qrCode },
      include: {
        user: {
          select: {
            name: true,
            email: true,
          },
        },
        event: {
          select: {
            title: true,
            start_time: true,
            venue: true,
          },
        },
        payment: {
          select: {
            status: true,
          },
        },
      },
    });

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: "Ticket not found",
      });
    }

    // Convert BigInt values to numbers for JSON serialization
    const serializedTicket = {
      ...ticket,
      price: Number(ticket.price),
      user_id: Number(ticket.user_id),
      event_id: Number(ticket.event_id),
    };

    res.json({
      success: true,
      ticket: serializedTicket,
    });
  } catch (error) {
    console.error("Error fetching ticket by QR code:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch ticket",
      error: error.message,
    });
  }
});

// Get individual ticket details by ticket ID
router.get("/:ticketId", authenticateToken, async (req, res) => {
  try {
    const { ticketId } = req.params;
    const user_id = req.user.user_id;

    const ticket = await prisma.ticketPurchase.findFirst({
      where: {
        ticket_id: ticketId,
        user_id: user_id, // Ensure user can only access their own tickets
      },
      include: {
        user: {
          select: {
            name: true,
            email: true,
            phone_number: true,
          },
        },
        event: {
          select: {
            title: true,
            description: true,
            start_time: true,
            end_time: true,
            venue: true,
            location: true,
            cover_image_url: true,
          },
        },
        payment: {
          select: {
            payment_id: true,
            status: true,
            payment_method: true,
            transaction_ref: true,
          },
        },
      },
    });

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: "Ticket not found or access denied",
      });
    }

    // Generate fresh QR code if it doesn't exist
    let qrCode = ticket.qr_code;
    if (!qrCode) {
      qrCode = `TICKET:${ticket.ticket_id}:${ticket.event_id}:${
        ticket.user_id
      }:${Date.now()}`;

      // Update the ticket with the new QR code
      await prisma.ticketPurchase.update({
        where: { ticket_id: ticketId },
        data: { qr_code: qrCode },
      });
    }

    // Convert BigInt values to numbers for JSON serialization
    const serializedTicket = {
      ...ticket,
      price: Number(ticket.price),
      user_id: Number(ticket.user_id),
      event_id: Number(ticket.event_id),
      qr_code: qrCode,
      event: {
        ...ticket.event,
        ticket_price: ticket.event.ticket_price
          ? Number(ticket.event.ticket_price)
          : null,
      },
    };

    res.json({
      success: true,
      ticket: serializedTicket,
    });
  } catch (error) {
    console.error("Error fetching ticket details:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch ticket details",
      error: error.message,
    });
  }
});

// Mark ticket as attended (for event organizers)
router.put("/:ticketId/attend", authenticateToken, async (req, res) => {
  try {
    const { ticketId } = req.params;

    const ticket = await prisma.ticketPurchase.update({
      where: { ticket_id: ticketId },
      data: { attended: true },
      include: {
        user: {
          select: {
            name: true,
            email: true,
          },
        },
        event: {
          select: {
            title: true,
          },
        },
      },
    });

    // Convert BigInt values to numbers for JSON serialization
    const serializedTicket = {
      ...ticket,
      price: Number(ticket.price),
      user_id: Number(ticket.user_id),
      event_id: Number(ticket.event_id),
    };

    res.json({
      success: true,
      message: "Ticket marked as attended",
      ticket: serializedTicket,
    });
  } catch (error) {
    console.error("Error updating ticket attendance:", error);
    res.status(500).json({
      success: false,
      message: "Failed to update ticket attendance",
      error: error.message,
    });
  }
});

// Get tickets for an event (for event organizers)
router.get("/event/:eventId", authenticateToken, async (req, res) => {
  try {
    const { eventId } = req.params;

    const tickets = await prisma.ticketPurchase.findMany({
      where: { event_id: parseInt(eventId) },
      include: {
        user: {
          select: {
            name: true,
            email: true,
          },
        },
        payment: {
          select: {
            status: true,
            payment_method: true,
          },
        },
      },
      orderBy: {
        purchase_date: "desc",
      },
    });

    // Convert BigInt values to numbers for JSON serialization
    const serializedTickets = tickets.map((ticket) => ({
      ...ticket,
      price: Number(ticket.price),
      user_id: Number(ticket.user_id),
      event_id: Number(ticket.event_id),
    }));

    res.json({
      success: true,
      tickets: serializedTickets,
    });
  } catch (error) {
    console.error("Error fetching event tickets:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch event tickets",
      error: error.message,
    });
  }
});

// GET /api/tickets/by-payment/:paymentId - Get first ticket details by payment ID
router.get("/by-payment/:paymentId", authenticateToken, async (req, res) => {
  try {
    const { paymentId } = req.params;
    const user_id = req.user.user_id;

    const ticket = await prisma.ticketPurchase.findFirst({
      where: {
        payment_id: paymentId,
        user_id: user_id, // Ensure user can only access their own tickets
      },
      include: {
        user: {
          select: {
            name: true,
            email: true,
            phone_number: true,
          },
        },
        event: {
          select: {
            title: true,
            description: true,
            start_time: true,
            end_time: true,
            venue: true,
            location: true,
            cover_image_url: true,
          },
        },
        payment: {
          select: {
            payment_id: true,
            status: true,
            payment_method: true,
            transaction_ref: true,
          },
        },
      },
    });

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: "Ticket not found or access denied",
      });
    }

    // Generate fresh QR code if it doesn't exist
    let qrCode = ticket.qr_code;
    if (!qrCode) {
      qrCode = `TICKET:${ticket.ticket_id}:${ticket.event_id}:${
        ticket.user_id
      }:${Date.now()}`;

      await prisma.ticketPurchase.update({
        where: { ticket_id: ticket.ticket_id },
        data: { qr_code: qrCode },
      });
    }

    // Serialize BigInt values
    const serializedTicket = {
      ...ticket,
      price: Number(ticket.price),
      user_id: Number(ticket.user_id),
      event_id: Number(ticket.event_id),  
      qr_code: qrCode,
    };

    res.json({
      success: true,
      ticket: serializedTicket,
    });
  } catch (error) {
    console.error("Error fetching ticket details by payment ID:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch ticket details",
      error: error.message,
    });
  }
});

console.log("🔧 Registering cancellation route: PUT /payment/:paymentId/cancel");

// PUT /api/tickets/payment/:paymentId/cancel - Cancel all tickets for a payment
router.put("/payment/:paymentId/cancel", authenticateToken, async (req, res) => {
  try {
    const { paymentId } = req.params;
    const user_id = req.user.user_id;

    console.log(`🎫 [CANCEL] Starting cancellation for payment: ${paymentId} by user: ${user_id}`);

    // Start a transaction to ensure atomicity
    const result = await prisma.$transaction(async (tx) => {
      // First, verify the payment belongs to the user
      const payment = await tx.payment.findFirst({
        where: {
          payment_id: paymentId,
          user_id: user_id,
        },
        include: {
          event: {
            select: {
              title: true,
              start_time: true,
            },
          },
        },
      });

      if (!payment) {
        throw new Error("Payment not found or access denied");
      }

      // Check if payment is already cancelled
      if (payment.status === 'cancelled') {
        throw new Error("Payment is already cancelled");
      }

      // Check if the event has already started (cannot cancel tickets for past events)
      const now = new Date();
      if (payment.event.start_time <= now) {
        throw new Error("Cannot cancel tickets for past events");
      }

      // Get all tickets for this payment
      const tickets = await tx.ticketPurchase.findMany({
        where: {
          payment_id: paymentId,
          user_id: user_id,
        },
      });

      if (tickets.length === 0) {
        throw new Error("No tickets found for this payment");
      }

      // Check if any tickets are already used/attended
      const usedTickets = tickets.filter(ticket => ticket.attended === true);
      if (usedTickets.length > 0) {
        throw new Error("Cannot cancel tickets that have already been used");
      }

      // Update payment status to 'cancelled'
      await tx.payment.update({
        where: { payment_id: paymentId },
        data: {
          status: 'cancelled',
          updated_at: new Date(),
        },
      });

      // Update all tickets status to 'cancelled'
      const updatedTickets = await tx.ticketPurchase.updateMany({
        where: {
          payment_id: paymentId,
          user_id: user_id,
        },
        data: {
          status: 'cancelled',
          updated_at: new Date(),
        },
      });

      return {
        payment,
        ticketsCount: updatedTickets.count,
        eventTitle: payment.event.title,
      };
    });

    console.log(`✅ [CANCEL] Successfully cancelled ${result.ticketsCount} tickets for payment: ${paymentId}`);

    res.json({
      success: true,
      message: `Successfully cancelled ${result.ticketsCount} ticket(s) for ${result.eventTitle}`,
      data: {
        payment_id: paymentId,
        tickets_cancelled: result.ticketsCount,
        event_title: result.eventTitle,
      },
    });

  } catch (error) {
    console.error(`❌ [CANCEL] Error cancelling tickets by payment ${paymentId}:`, error);
    
    // Handle specific error messages
    let statusCode = 500;
    let message = "Failed to cancel tickets";

    if (error.message === "Payment not found or access denied") {
      statusCode = 404;
      message = error.message;
    } else if (error.message === "Payment is already cancelled") {
      statusCode = 400;
      message = error.message;
    } else if (error.message === "Cannot cancel tickets for past events") {
      statusCode = 400;
      message = error.message;
    } else if (error.message === "Cannot cancel tickets that have already been used") {
      statusCode = 400;
      message = error.message;
    } else if (error.message === "No tickets found for this payment") {
      statusCode = 404;
      message = error.message;
    }

    res.status(statusCode).json({
      success: false,
      message: message,
      error: error.message,
    });
  }
});

module.exports = router;
