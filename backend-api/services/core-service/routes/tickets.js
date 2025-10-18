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
    });
  }
});

// TEST ENDPOINT - Remove after debugging
router.get("/test-events-tickets/:userId", async (req, res) => {
  try {
    const user_id = parseInt(req.params.userId);
    console.log('DEBUG: Testing with user_id:', user_id);

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
            category: true,
            ticket_types: true,
          },
        },
        payment: {
          select: {
            payment_id: true,
            status: true,
            payment_method: true,
            transaction_ref: true,
            payment_date: true,
          },
        },
      },
      orderBy: {
        purchase_date: 'desc'
      }
    });

    // Get unique events from the tickets with ticket types
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
        category: true,
        ticket_types: true,
      }
    });

    console.log('DEBUG: Found events for user', user_id, ':', events.length);
    events.forEach(event => {
      console.log('DEBUG: Event', event.event_id, 'title:', event.title);
    });

    res.json({
      success: true,
      message: 'Test endpoint',
      user_id: user_id,
      events: events,
      ticketsData: ticketsData,
      eventsCount: events.length,
      ticketsCount: ticketsData.length
    });
  } catch (error) {
    console.error("Error in test endpoint:", error);
    res.status(500).json({
      success: false,
      message: "Test endpoint error",
      error: error.message,
    });
  }
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
            category: true,
            ticket_types: true,
          },
        },
        payment: {
          select: {
            payment_id: true,
            status: true,
            payment_method: true,
            transaction_ref: true,
            payment_date: true,
          },
        },
      },
      orderBy: {
        purchase_date: 'desc'
      }
    });

    // Get unique events from the tickets with ticket types
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
        category: true,
        ticket_types: true,
      }
    });

    console.log('DEBUG: Found events for user', user_id, ':', events.length);
    events.forEach(event => {
      console.log('DEBUG: Event', event.event_id, 'title:', event.title);
    });

    console.log(`[DEBUG] Found ${events.length} events for user ${user_id}:`);
    events.forEach(event => {
      console.log(`[DEBUG] Event ${event.event_id}: "${event.title}"`);
    });

    // Group tickets by event with enhanced analytics
    const ticketsByEvent = [];
    const eventMap = new Map();

    for (const event of events) {
      const eventTickets = ticketsData.filter(ticket => ticket.event.event_id === event.event_id);
      
      // Parse ticket types to get categories
      let ticketTypes = [];
      try {
        if (event.ticket_types && typeof event.ticket_types === 'string') {
          ticketTypes = JSON.parse(event.ticket_types);
        } else if (Array.isArray(event.ticket_types)) {
          ticketTypes = event.ticket_types;
        }
      } catch (e) {
        console.error('Error parsing ticket types for event', event.event_id, e);
      }

      // Calculate revenue breakdown by ticket type/category
      const ticketCategoryBreakdown = [];
      const totalEventRevenue = eventTickets.reduce((sum, ticket) => sum + Number(ticket.price), 0);
      
      // Group tickets by price to match with ticket types
      const ticketsByPrice = {};
      eventTickets.forEach(ticket => {
        const price = Number(ticket.price);
        if (!ticketsByPrice[price]) {
          ticketsByPrice[price] = [];
        }
        ticketsByPrice[price].push(ticket);
      });

      // Match tickets with their categories
      ticketTypes.forEach(ticketType => {
        const matchingTickets = ticketsByPrice[ticketType.price] || [];
        const categoryRevenue = matchingTickets.reduce((sum, ticket) => sum + Number(ticket.price), 0);
        
        ticketCategoryBreakdown.push({
          name: ticketType.name,
          price: ticketType.price,
          description: ticketType.description || '',
          ticketsSold: matchingTickets.length,
          revenue: categoryRevenue,
          attendedCount: matchingTickets.filter(ticket => ticket.attended).length
        });
      });

      // Handle tickets that don't match any defined category
      const categorizedPrices = new Set(ticketTypes.map(tt => tt.price));
      Object.entries(ticketsByPrice).forEach(([price, tickets]) => {
        const priceNum = parseFloat(price);
        if (!categorizedPrices.has(priceNum)) {
          const categoryRevenue = tickets.reduce((sum, ticket) => sum + Number(ticket.price), 0);
          ticketCategoryBreakdown.push({
            name: `Uncategorized ($${priceNum})`,
            price: priceNum,
            description: 'Tickets not matching defined categories',
            ticketsSold: tickets.length,
            revenue: categoryRevenue,
            attendedCount: tickets.filter(ticket => ticket.attended).length
          });
        }
      });

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
        category: event.category,
        ticket_types: ticketTypes,
        tickets: eventTickets.map(ticket => ({
          ...ticket,
          price: Number(ticket.price)
        })),
        ticketCount: eventTickets.length,
        attendedCount: eventTickets.filter(ticket => ticket.attended).length,
        eventRevenue: totalEventRevenue,
        ticketCategoryBreakdown: ticketCategoryBreakdown,
        averageTicketPrice: eventTickets.length > 0 ? (totalEventRevenue / eventTickets.length) : 0,
        attendanceRate: eventTickets.length > 0 ? (eventTickets.filter(ticket => ticket.attended).length / eventTickets.length * 100) : 0
      };

      console.log('DEBUG: Event with tickets for', event.event_id, '- title:', eventWithTickets.title);

      console.log(`[DEBUG] Created eventWithTickets for event ${event.event_id}:`, {
        event_id: eventWithTickets.event_id,
        title: eventWithTickets.title,
        hasTitle: !!eventWithTickets.title,
        titleType: typeof eventWithTickets.title
      });

      ticketsByEvent.push(eventWithTickets);
      eventMap.set(event.event_id, eventWithTickets);
    }

    // Calculate overall statistics
    const totalTickets = ticketsData.length;
    const totalAttended = ticketsData.filter(ticket => ticket.attended).length;
    const totalRevenue = ticketsData.reduce((sum, ticket) => sum + Number(ticket.price), 0);
    const averageTicketPrice = totalTickets > 0 ? (totalRevenue / totalTickets) : 0;

    // Calculate revenue by event category
    const revenueByCategoryMap = {};
    ticketsByEvent.forEach(eventData => {
      const category = eventData.category || 'Uncategorized';
      if (!revenueByCategoryMap[category]) {
        revenueByCategoryMap[category] = {
          category,
          revenue: 0,
          ticketsSold: 0,
          eventsCount: 0
        };
      }
      revenueByCategoryMap[category].revenue += eventData.eventRevenue;
      revenueByCategoryMap[category].ticketsSold += eventData.ticketCount;
      revenueByCategoryMap[category].eventsCount += 1;
    });

    const revenueByCategory = Object.values(revenueByCategoryMap);

    // Calculate recent sales (last 30 days)
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const recentTickets = ticketsData.filter(ticket => 
      new Date(ticket.purchase_date) >= thirtyDaysAgo
    );
    const recentRevenue = recentTickets.reduce((sum, ticket) => sum + Number(ticket.price), 0);

    const statistics = {
      totalTicketsSold: totalTickets,
      totalRevenue,
      totalEvents: events.length,
      averageTicketPrice,
      totalAttended,
      attendanceRate: totalTickets > 0 ? (totalAttended / totalTickets * 100) : 0,
      recentSales: {
        ticketsSold: recentTickets.length,
        revenue: recentRevenue,
        period: '30 days'
      },
      revenueByCategory,
      topSellingEvents: ticketsByEvent
        .sort((a, b) => b.ticketCount - a.ticketCount)
        .slice(0, 5)
        .map(event => ({
          event_id: event.event_id,
          title: event.title,
          ticketsSold: event.ticketCount,
          revenue: event.eventRevenue
        }))
    };

    // Serialize tickets for response
    const serializedTickets = ticketsData.map(ticket => ({
      ...ticket,
      price: Number(ticket.price)
    }));

    console.log(`[DEBUG] Final response summary:`);
    console.log(`[DEBUG] - Found ${ticketsByEvent.length} events`);
    console.log(`[DEBUG] - Event titles:`, ticketsByEvent.map(e => `${e.event_id}: "${e.title}"`));

    res.json({
      success: true,
      tickets: serializedTickets,
      events: events,
      ticketsByEvent: ticketsByEvent,
      statistics: statistics,
    });
    
    console.log('DEBUG: API Response - ticketsByEvent count:', ticketsByEvent.length);
    console.log('DEBUG: First event in response:', ticketsByEvent[0] ? {
      event_id: ticketsByEvent[0].event_id,
      title: ticketsByEvent[0].title
    } : 'No events');
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
