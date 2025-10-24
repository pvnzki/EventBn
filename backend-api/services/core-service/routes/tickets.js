const express = require("express");
const router = express.Router();
const { authenticateToken } = require("../auth/index.js");
const prisma = require("../lib/database");
const { validateUUID, ValidationError } = require("../lib/validation");

// UUID validation helper
function validateUUID(value, fieldName) {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!value || !uuidRegex.test(value)) {
    throw new Error(`Invalid ${fieldName}: must be a valid UUID`);
  }
}

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

    const tickets = await prisma.ticket_purchase.findMany({
      where: { user_id: user_id },
      include: {
        Event: {
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

    // Categorize tickets based on event date AND payment status
    const now = new Date();
    const upcomingTickets = [];
    const completedTickets = [];
    const cancelledTickets = [];

    serializedTickets.forEach(ticket => {
      const eventStartTime = new Date(ticket.Event.start_time);

      // If the payment for this ticket has been refunded, treat as cancelled
      const paymentStatus = ticket.payment?.status || null;
      if (paymentStatus === 'refunded') {
        cancelledTickets.push(ticket);
        return;
      }

      // Future event - goes to upcoming
      if (eventStartTime > now) {
        upcomingTickets.push(ticket);
      } else {
        // Past event - goes to completed
        completedTickets.push(ticket);
      }
    });

    // Group upcoming tickets by payment_id for cancel functionality
    const upcomingGroupedByPayment = {};
    upcomingTickets.forEach(ticket => {
      const paymentId = ticket.payment?.payment_id;
      if (paymentId) {
        if (!upcomingGroupedByPayment[paymentId]) {
          // Calculate if cancellation is allowed (2+ hours before event)
          const eventStartTime = new Date(ticket.Event.start_time);
          const hoursUntilEvent = (eventStartTime - now) / (1000 * 60 * 60);
          const canCancel = ticket.payment.status === 'completed' && hoursUntilEvent >= 2;
          
          upcomingGroupedByPayment[paymentId] = {
            payment_id: paymentId,
            payment_status: ticket.payment.status,
            payment_method: ticket.payment.payment_method,
            event_title: ticket.Event.title,
            event_start_time: ticket.Event.start_time,
            event_venue: ticket.Event.venue,
            event_location: ticket.Event.location,
            cover_image_url: ticket.Event.cover_image_url,
            tickets: [],
            total_amount: 0,
            ticket_count: 0,
            can_cancel: canCancel,
            hours_until_event: Math.round(hoursUntilEvent * 10) / 10, // Round to 1 decimal
          };
        }
        upcomingGroupedByPayment[paymentId].tickets.push(ticket);
        upcomingGroupedByPayment[paymentId].total_amount += ticket.price;
        upcomingGroupedByPayment[paymentId].ticket_count += 1;
      }
    });

    const upcomingPaymentGroups = Object.values(upcomingGroupedByPayment);

    res.json({
      success: true,
      tickets: serializedTickets, // All tickets (backward compatibility)
      upcoming: {
        tickets: upcomingTickets,
        payment_groups: upcomingPaymentGroups, // Grouped by payment for cancel functionality
        count: upcomingTickets.length
      },
      completed: {
        tickets: completedTickets,
        count: completedTickets.length
      },
      cancelled: {
        tickets: cancelledTickets,
        count: cancelledTickets.length
      }
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

// Get ticket by QR code (for Event organizers to scan)
router.get("/qr/:qrCode", authenticateToken, async (req, res) => {
  try {
    const { qrCode } = req.params;

    const ticket = await prisma.ticket_purchase.findFirst({
      where: { qr_code: qrCode },
      include: {
        User: {
          select: {
            name: true,
            email: true,
          },
        },
        Event: {
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

    const ticket = await prisma.ticket_purchase.findFirst({
      where: {
        ticket_id: ticketId,
        user_id: user_id, // Ensure user can only access their own tickets
      },
      include: {
        User: {
          select: {
            name: true,
            email: true,
            phone_number: true,
          },
        },
        Event: {
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
      await prisma.ticket_purchase.update({
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
        ...ticket.Event,
        ticket_price: ticket.Event.ticket_price
          ? Number(ticket.Event.ticket_price)
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

// Mark ticket as attended (for Event organizers)
router.put("/:ticketId/attend", authenticateToken, async (req, res) => {
  try {
    const { ticketId } = req.params;

    const ticket = await prisma.ticket_purchase.update({
      where: { ticket_id: ticketId },
      data: { attended: true },
      include: {
        User: {
          select: {
            name: true,
            email: true,
          },
        },
        Event: {
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

    const tickets = await prisma.ticket_purchase.findMany({
      where: { event_id: parseInt(eventId) },
      include: {
        User: {
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
    console.error("Error fetching Event tickets:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch Event tickets",
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

    const ticket = await prisma.ticket_purchase.findFirst({
      where: {
        payment_id: paymentId,
        user_id: user_id, // Ensure user can only access their own tickets
      },
      include: {
        User: {
          select: {
            name: true,
            email: true,
            phone_number: true,
          },
        },
        Event: {
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
      qrCode = `TICKET:${ticket.ticket_id}:${ticket.Event_id}:${
        ticket.User_id
      }:${Date.now()}`;

      await prisma.ticket_purchase.update({
        where: { ticket_id: ticket.ticket_id },
        data: { qr_code: qrCode },
      });
    }

    // Serialize BigInt values
    const serializedTicket = {
      ...ticket,
      price: Number(ticket.price),
      User_id: Number(ticket.User_id),
      Event_id: Number(ticket.Event_id),  
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
          Event: {
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

      // Check if payment is already refunded
      if (payment.status === 'refunded') {
        throw new Error("Payment is already refunded");
      }

      // Check if the event has already started or is too close to starting
      const now = new Date();
      const eventStartTime = new Date(payment.Event.start_time);
      const hoursUntilEvent = (eventStartTime - now) / (1000 * 60 * 60);
      
      if (eventStartTime <= now) {
        throw new Error("Cannot cancel tickets for events that have already started");
      }
      
      // Require at least 2 hours notice for cancellation
      if (hoursUntilEvent < 2) {
        throw new Error("Cannot cancel tickets less than 2 hours before the event starts");
      }

      // Get all tickets for this payment
      const tickets = await tx.ticket_purchase.findMany({
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

      // Update payment status to 'refunded'
      await tx.payment.update({
        where: { payment_id: paymentId },
        data: {
          status: 'refunded',
          updated_at: new Date(),
        },
      });

      // Note: ticket_purchase model doesn't have status or updated_at fields.
      // The refund status is tracked on the payment record only.
      // We just need to count the tickets for the response.
      const ticketsCount = tickets.length;

      return {
        payment,
        ticketsCount: ticketsCount,
        EventTitle: payment.Event.title,
      };
    });

    console.log(`✅ [CANCEL] Successfully refunded ${result.ticketsCount} tickets for payment: ${paymentId}`);

    res.json({
      success: true,
      message: `Successfully refunded ${result.ticketsCount} ticket(s) for ${result.EventTitle}`,
      data: {
        payment_id: paymentId,
        tickets_refunded: result.ticketsCount,
        Event_title: result.EventTitle,
      },
    });

  } catch (error) {
  const pid = req && req.params ? req.params.paymentId : 'unknown';
  console.error(`❌ [CANCEL] Error cancelling tickets by payment ${pid}:`, error);
    
    // Handle specific error messages
    let statusCode = 500;
    let message = "Failed to cancel tickets";

    if (error.message === "Payment not found or access denied") {
      statusCode = 404;
      message = error.message;
    } else if (error.message === "Payment is already refunded") {
      statusCode = 400;
      message = error.message;
    } else if (error.message === "Cannot cancel tickets for past Events") {
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
