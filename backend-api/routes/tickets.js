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

    res.json({
      success: true,
      tickets: tickets
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

    res.json({
      success: true,
      ticket: ticket
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

    res.json({
      success: true,
      message: 'Ticket marked as attended',
      ticket: ticket
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

    res.json({
      success: true,
      tickets: tickets
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

module.exports = router;
