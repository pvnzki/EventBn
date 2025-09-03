const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const prisma = require('../lib/database');

// Get user's tickets
router.get('/my-tickets', authenticateToken, async (req, res) => {
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
            cover_image_url: true
          }
        },
        payment: {
          select: {
            payment_id: true,
            status: true,
            payment_method: true
          }
        }
      },
      orderBy: {
        purchase_date: 'desc'
      }
    });

    // Convert BigInt to number for JSON serialization
    const serializedTickets = tickets.map(ticket => ({
      ...ticket,
      price: Number(ticket.price) / 100 // Convert from cents back to dollars/LKR
    }));

    res.json({
      success: true,
      tickets: serializedTickets
    });

  } catch (error) {
    console.error('Error fetching tickets:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch tickets',
      error: error.message
    });
  }
});

// Get ticket by QR code (for event organizers to scan)
router.get('/qr/:qrCode', authenticateToken, async (req, res) => {
  try {
    const { qrCode } = req.params;

    const ticket = await prisma.ticketPurchase.findFirst({
      where: { qr_code: qrCode },
      include: {
        user: {
          select: {
            name: true,
            email: true
          }
        },
        event: {
          select: {
            title: true,
            start_time: true,
            venue: true
          }
        },
        payment: {
          select: {
            status: true
          }
        }
      }
    });

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Ticket not found'
      });
    }

    // Convert BigInt to number for JSON serialization
    const serializedTicket = {
      ...ticket,
      price: Number(ticket.price) / 100 // Convert from cents back to dollars/LKR
    };

    res.json({
      success: true,
      ticket: serializedTicket
    });

  } catch (error) {
    console.error('Error fetching ticket by QR code:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch ticket',
      error: error.message
    });
  }
});

// Mark ticket as attended (for event organizers)
router.put('/:ticketId/attend', authenticateToken, async (req, res) => {
  try {
    const { ticketId } = req.params;

    const ticket = await prisma.ticketPurchase.update({
      where: { ticket_id: ticketId },
      data: { attended: true },
      include: {
        user: {
          select: {
            name: true,
            email: true
          }
        },
        event: {
          select: {
            title: true
          }
        }
      }
    });

    // Convert BigInt to number for JSON serialization
    const serializedTicket = {
      ...ticket,
      price: Number(ticket.price) / 100 // Convert from cents back to dollars/LKR
    };

    res.json({
      success: true,
      message: 'Ticket marked as attended',
      ticket: serializedTicket
    });

  } catch (error) {
    console.error('Error updating ticket attendance:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update ticket attendance',
      error: error.message
    });
  }
});

// Get tickets for an event (for event organizers)
router.get('/event/:eventId', authenticateToken, async (req, res) => {
  try {
    const { eventId } = req.params;

    const tickets = await prisma.ticketPurchase.findMany({
      where: { event_id: parseInt(eventId) },
      include: {
        user: {
          select: {
            name: true,
            email: true
          }
        },
        payment: {
          select: {
            status: true,
            payment_method: true
          }
        }
      },
      orderBy: {
        purchase_date: 'desc'
      }
    });

    // Convert BigInt to number for JSON serialization
    const serializedTickets = tickets.map(ticket => ({
      ...ticket,
      price: Number(ticket.price) / 100 // Convert from cents back to dollars/LKR
    }));

    res.json({
      success: true,
      tickets: serializedTickets
    });

  } catch (error) {
    console.error('Error fetching event tickets:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch event tickets',
      error: error.message
    });
  }
});

// Get tickets for current user's events (for event organizers)
router.get('/my-events-tickets', authenticateToken, async (req, res) => {
  try {
    const user_id = req.user.user_id;

    // First get the user's organization
    const organization = await prisma.organization.findFirst({
      where: { user_id: user_id }
    });

    if (!organization) {
      return res.json({
        success: true,
        tickets: [],
        message: 'No organization found for user'
      });
    }

    // Get all events for this organization
    const events = await prisma.event.findMany({
      where: { 
        organization_id: organization.organization_id,
        status: 'ACTIVE'
      },
      select: {
        event_id: true,
        title: true,
        start_time: true,
        end_time: true,
        venue: true,
        location: true,
        capacity: true,
        cover_image_url: true
      }
    });

    if (events.length === 0) {
      return res.json({
        success: true,
        tickets: [],
        events: [],
        message: 'No events found for organization'
      });
    }

    const eventIds = events.map(event => event.event_id);

    // Get all tickets for these events
    const tickets = await prisma.ticketPurchase.findMany({
      where: { 
        event_id: { in: eventIds }
      },
      include: {
        user: {
          select: {
            name: true,
            email: true,
            phone_number: true
          }
        },
        event: {
          select: {
            title: true,
            start_time: true,
            venue: true,
            location: true,
            cover_image_url: true
          }
        },
        payment: {
          select: {
            payment_id: true,
            status: true,
            payment_method: true,
            payment_date: true
          }
        }
      },
      orderBy: [
        { event_id: 'asc' },
        { purchase_date: 'desc' }
      ]
    });

    // Convert BigInt to number for JSON serialization and group by event
    const serializedTickets = tickets.map(ticket => ({
      ...ticket,
      price: Number(ticket.price) / 100 // Convert from cents back to dollars/LKR
    }));

    // Calculate statistics
    const statistics = {
      totalTicketsSold: serializedTickets.length,
      totalRevenue: serializedTickets.reduce((sum, ticket) => sum + ticket.price, 0),
      totalEvents: events.length,
      averageTicketPrice: serializedTickets.length > 0 
        ? serializedTickets.reduce((sum, ticket) => sum + ticket.price, 0) / serializedTickets.length 
        : 0
    };

    // Group tickets by event for easier frontend handling
    const ticketsByEvent = events.map(event => {
      const eventTickets = serializedTickets.filter(ticket => ticket.event_id === event.event_id);
      return {
        event,
        tickets: eventTickets,
        ticketCount: eventTickets.length,
        eventRevenue: eventTickets.reduce((sum, ticket) => sum + ticket.price, 0),
        attendedCount: eventTickets.filter(ticket => ticket.attended).length
      };
    });

    res.json({
      success: true,
      tickets: serializedTickets,
      events: events,
      ticketsByEvent: ticketsByEvent,
      statistics: statistics
    });

  } catch (error) {
    console.error('Error fetching organizer tickets:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch tickets for your events',
      error: error.message
    });
  }
});

module.exports = router;
