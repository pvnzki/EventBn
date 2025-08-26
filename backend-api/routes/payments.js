const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const prisma = require('../lib/database');
const { Status } = require('@prisma/client');

// Create a new payment
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { event_id, amount, payment_method, selected_seats } = req.body;
    const user_id = req.user.user_id;

    // Validate required fields
    if (!event_id || !amount || !selected_seats || selected_seats.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Event ID, amount, and selected seats are required'
      });
    }

    // Verify event exists
    const event = await prisma.event.findUnique({
      where: { event_id: parseInt(event_id) }
    });

    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found'
      });
    }

    // Create payment record
    const payment = await prisma.payment.create({
      data: {
        user_id: user_id,
        event_id: parseInt(event_id),
        amount: parseFloat(amount),
        payment_method: payment_method || 'card',
        status: Status.pending,
        transaction_ref: `TXN_${Date.now()}_${Math.random().toString(36).substr(2, 9)}` // Generate unique transaction reference
      },
      include: {
        user: {
          select: {
            user_id: true,
            name: true,
            email: true
          }
        },
        event: {
          select: {
            event_id: true,
            title: true,
            start_time: true,
            venue: true
          }
        }
      }
    });

    // Create booked seat records for each selected seat
    const bookedSeatsData = selected_seats.map((seatLabel, index) => ({
      payment_id: payment.payment_id,
      event_id: parseInt(event_id),
      seat_id: index + 1, // You might want to get the actual seat ID from selected_seats
      seat_label: seatLabel
    }));

    await prisma.bookedSeats.createMany({
      data: bookedSeatsData
    });

    res.status(201).json({
      success: true,
      message: 'Payment record created successfully',
      payment: payment
    });

  } catch (error) {
    console.error('Error creating payment:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create payment record',
      error: error.message
    });
  }
});

// Get user's payments
router.get('/my-payments', authenticateToken, async (req, res) => {
  try {
    const user_id = req.user.user_id;

    const payments = await prisma.payment.findMany({
      where: { user_id: user_id },
      include: {
        event: {
          select: {
            title: true,
            start_time: true,
            venue: true,
            cover_image_url: true
          }
        }
      },
      orderBy: {
        payment_date: 'desc'
      }
    });

    res.json({
      success: true,
      payments: payments
    });

  } catch (error) {
    console.error('Error fetching payments:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch payments',
      error: error.message
    });
  }
});

// Get payment by ID
router.get('/:payment_id', authenticateToken, async (req, res) => {
  try {
    const { payment_id } = req.params;
    const user_id = req.user.user_id;

    const payment = await prisma.payment.findFirst({
      where: { 
        payment_id: payment_id,
        user_id: user_id // Ensure user can only access their own payments
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
            location: true
          }
        }
      }
    });

    if (!payment) {
      return res.status(404).json({
        success: false,
        message: 'Payment not found'
      });
    }

    res.json({
      success: true,
      payment: payment
    });

  } catch (error) {
    console.error('Error fetching payment:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch payment',
      error: error.message
    });
  }
});

// Update payment status (for payment gateway callbacks)
router.put('/:payment_id/status', authenticateToken, async (req, res) => {
  try {
    const { payment_id } = req.params;
    const { status, transaction_ref } = req.body;

    // Validate status
    const validStatuses = ['pending', 'completed', 'failed', 'refunded'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid payment status'
      });
    }

    const payment = await prisma.payment.update({
      where: { payment_id: payment_id },
      data: {
        status: Status[status],
        ...(transaction_ref && { transaction_ref: transaction_ref })
      }
    });

    res.json({
      success: true,
      message: 'Payment status updated successfully',
      payment: payment
    });

  } catch (error) {
    console.error('Error updating payment status:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update payment status',
      error: error.message
    });
  }
});

module.exports = router;
