const express = require("express");
const router = express.Router();
const { authenticateToken } = require("../middleware/auth");
const prisma = require("../lib/database");
const { validateUUID, ValidationError } = require("../lib/validation");

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

// Get tickets for events created by the organizer (my organizations' events)
router.get("/my-events-tickets", authenticateToken, async (req, res) => {
  try {
    const user_id = req.user.user_id;

    // Get all tickets for events owned by user's organizations
    const ticketsData = await prisma.ticketPurchase.findMany({
      where: {
        event: {
          organization: {
            user_id: user_id // Events from organizations owned by this user
          }
        }
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
            event_id: true,
            title: true,
            description: true,
            start_time: true,
            end_time: true,
            venue: true,
            location: true,
            cover_image_url: true,
            capacity: true,
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
      orderBy: {
        purchase_date: 'desc'
      }
    });

    // Get unique events from the tickets
    const events = await prisma.event.findMany({
      where: {
        organization: {
          user_id: user_id
        }
      },
      select: {
        event_id: true,
        title: true,
        description: true,
        start_time: true,
        end_time: true,
        venue: true,
        location: true,
        cover_image_url: true,
        capacity: true,
      }
    });

    // Group tickets by event
    const ticketsByEvent = [];
    const eventMap = new Map();

    for (const event of events) {
      const eventTickets = ticketsData.filter(ticket => ticket.event.event_id === event.event_id);
      
      const eventWithTickets = {
        event_id: event.event_id,
        title: event.title,
        description: event.description,
        start_time: event.start_time,
        end_time: event.end_time,
        venue: event.venue,
        location: event.location,
        cover_image_url: event.cover_image_url,
        capacity: event.capacity,
        tickets: eventTickets.map(ticket => ({
          ...ticket,
          price: Number(ticket.price)
        })),
        ticketCount: eventTickets.length,
        attendedCount: eventTickets.filter(ticket => ticket.attended).length
      };

      ticketsByEvent.push(eventWithTickets);
      eventMap.set(event.event_id, eventWithTickets);
    }

    // Calculate statistics
    const totalTickets = ticketsData.length;
    const totalAttended = ticketsData.filter(ticket => ticket.attended).length;
    const totalRevenue = ticketsData.reduce((sum, ticket) => sum + Number(ticket.price), 0);
    const averageTicketPrice = totalTickets > 0 ? (totalRevenue / totalTickets) : 0;

    const statistics = {
      totalTickets,
      totalAttended,
      attendanceRate: totalTickets > 0 ? (totalAttended / totalTickets * 100) : 0,
      totalRevenue,
      totalEvents: events.length,
      averageTicketPrice
    };

    // Serialize tickets for response
    const serializedTickets = ticketsData.map(ticket => ({
      ...ticket,
      price: Number(ticket.price)
    }));

    res.json({
      success: true,
      tickets: serializedTickets,
      events: events,
      ticketsByEvent: ticketsByEvent,
      statistics: statistics,
    });
  } catch (error) {
    console.error("Error fetching organizer tickets:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch organizer tickets",
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

    // Validate that ticketId is a proper UUID
    try {
      validateUUID(ticketId, 'Ticket ID');
    } catch (validationError) {
      return res.status(400).json({
        success: false,
        message: validationError.message,
        error: "INVALID_TICKET_ID"
      });
    }

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

    // Validate that paymentId is a proper UUID
    try {
      validateUUID(paymentId, 'Payment ID');
    } catch (validationError) {
      return res.status(400).json({
        success: false,
        message: validationError.message,
        error: "INVALID_PAYMENT_ID"
      });
    }

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

module.exports = router;
