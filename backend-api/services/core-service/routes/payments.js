const express = require("express");
const router = express.Router();
const { authenticateToken } = require("../middleware/auth");
const prisma = require("../lib/database");
const { Status } = require("@prisma/client");

// Create a new payment
router.post("/", authenticateToken, async (req, res) => {
  try {
    const { event_id, amount, payment_method, selected_seats, payment_id, selectedSeatData } =
      req.body;
    const user_id = req.user.user_id;

    // Validate required fields
    if (
      !event_id ||
      !amount ||
      !selected_seats ||
      selected_seats.length === 0
    ) {
      return res.status(400).json({
        success: false,
        message: "Event ID, amount, and selected seats are required",
      });
    }

    // Verify event exists
    const event = await prisma.event.findUnique({
      where: { event_id: parseInt(event_id) },
    });

    if (!event) {
      return res.status(404).json({
        success: false,
        message: "Event not found",
      });
    }

    // Create payment record
    const payment = await prisma.payment.create({
      data: {
        user_id: user_id,
        event_id: parseInt(event_id),
        amount: parseFloat(amount),
        payment_method: payment_method || "card",
        status: Status.completed, // Mark as completed since PayHere payment was successful
        transaction_ref:
          payment_id ||
          `TXN_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`, // Use PayHere payment ID as transaction reference
      },
      include: {
        user: {
          select: {
            user_id: true,
            name: true,
            email: true,
          },
        },
        event: {
          select: {
            event_id: true,
            title: true,
            start_time: true,
            venue: true,
            seat_map: true,
          },
        },
      },
    });

    // Update seat availability in the event's seat_map JSON
    const currentSeatMap = payment.event.seat_map;

    if (currentSeatMap && Array.isArray(currentSeatMap)) {
      // Handle events with seat maps
      // Convert selected_seats (which are seat IDs as strings) to integers
      const selectedSeatIds = selected_seats.map((seatId) =>
        parseInt(seatId, 10)
      );

      // Update the seat_map to mark selected seats as unavailable
      const updatedSeatMap = currentSeatMap.map((seat) => {
        if (selectedSeatIds.includes(seat.id)) {
          return { ...seat, available: false };
        }
        return seat;
      });

      // Update the event with the new seat_map
      await prisma.event.update({
        where: { event_id: parseInt(event_id) },
        data: { seat_map: updatedSeatMap },
      });

      // Create individual ticket purchase records for each seat
      const ticketPurchases = [];
      for (const seatId of selectedSeatIds) {
        const seat = currentSeatMap.find((s) => s.id === seatId);
        if (seat) {
          // Generate unique QR code for each ticket
          const qrCode = `TICKET_${payment.payment_id}_${seatId}_${Date.now()}`;

          ticketPurchases.push({
            event_id: parseInt(event_id),
            user_id: user_id,
            payment_id: payment.payment_id,
            seat_id: seatId,
            seat_label: seat.label,
            purchase_date: new Date(),
            price: BigInt(Math.round(seat.price * 100)), // Convert to cents/paise for BigInt
            attended: false,
            qr_code: qrCode,
          });
        }
      }

      // Create all ticket purchase records using raw SQL temporarily
      if (ticketPurchases.length > 0) {
        try {
          for (const ticket of ticketPurchases) {
            await prisma.$executeRaw`
              INSERT INTO ticket_purchase (event_id, user_id, payment_id, seat_id, seat_label, purchase_date, price, attended, qr_code)
              VALUES (${ticket.event_id}, ${ticket.user_id}, ${
              ticket.payment_id
            }::uuid, ${ticket.seat_id}, ${ticket.seat_label}, ${
              ticket.purchase_date
            }, ${ticket.price.toString()}::bigint, ${ticket.attended}, ${
              ticket.qr_code
            })
            `;
          }
          console.log(
            `Created ${ticketPurchases.length} ticket purchase records`
          );
        } catch (ticketError) {
          console.error("Error creating tickets:", ticketError);
          // Continue with payment success even if ticket creation fails
        }
      }
    } else {
      // Handle events without seat maps (ticket type selection)
      const ticketPurchases = [];
      
      if (selectedSeatData && Array.isArray(selectedSeatData)) {
        // Use selectedSeatData if available (contains pricing info)
        for (let i = 0; i < selectedSeatData.length; i++) {
          const seatData = selectedSeatData[i];
          
          // Generate unique QR code for each ticket
          const qrCode = `TICKET_${payment.payment_id}_${i + 1}_${Date.now()}`;

          ticketPurchases.push({
            event_id: parseInt(event_id),
            user_id: user_id,
            payment_id: payment.payment_id,
            seat_id: null, // No seat ID for general admission
            seat_label: seatData.label || selected_seats[i] || `Ticket ${i + 1}`,
            purchase_date: new Date(),
            price: BigInt(Math.round(parseFloat(seatData.price || 0) * 100)), // Convert to cents/paise for BigInt
            attended: false,
            qr_code: qrCode,
          });
        }
      } else {
        // Fallback: use selected_seats array (calculate price per ticket)
        for (let i = 0; i < selected_seats.length; i++) {
          const seatLabel = selected_seats[i];
          
          // Calculate price per ticket (total amount divided by number of tickets)
          const pricePerTicket = parseFloat(amount) / selected_seats.length;
          
          // Generate unique QR code for each ticket
          const qrCode = `TICKET_${payment.payment_id}_${i + 1}_${Date.now()}`;

          ticketPurchases.push({
            event_id: parseInt(event_id),
            user_id: user_id,
            payment_id: payment.payment_id,
            seat_id: null, // No seat ID for general admission
            seat_label: seatLabel,
            purchase_date: new Date(),
            price: BigInt(Math.round(pricePerTicket * 100)), // Convert to cents/paise for BigInt
            attended: false,
            qr_code: qrCode,
          });
        }
      }

      // Create all ticket purchase records
      if (ticketPurchases.length > 0) {
        try {
          for (const ticket of ticketPurchases) {
            await prisma.$executeRaw`
              INSERT INTO ticket_purchase (event_id, user_id, payment_id, seat_id, seat_label, purchase_date, price, attended, qr_code)
              VALUES (${ticket.event_id}, ${ticket.user_id}, ${
              ticket.payment_id
            }::uuid, ${ticket.seat_id}, ${ticket.seat_label}, ${
              ticket.purchase_date
            }, ${ticket.price.toString()}::bigint, ${ticket.attended}, ${
              ticket.qr_code
            })
            `;
          }
          console.log(
            `Created ${ticketPurchases.length} ticket purchase records for event without seat map`
          );
        } catch (ticketError) {
          console.error("Error creating tickets for event without seat map:", ticketError);
          // Continue with payment success even if ticket creation fails
        }
      }
    }

    res.status(201).json({
      success: true,
      message: "Payment record created successfully",
      payment: payment,
    });
  } catch (error) {
    console.error("Error creating payment:", error);
    res.status(500).json({
      success: false,
      message: "Failed to create payment record",
      error: error.message,
    });
  }
});

// Get user's payments
router.get("/my-payments", authenticateToken, async (req, res) => {
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
            cover_image_url: true,
          },
        },
      },
      orderBy: {
        payment_date: "desc",
      },
    });

    res.json({
      success: true,
      payments: payments,
    });
  } catch (error) {
    console.error("Error fetching payments:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch payments",
      error: error.message,
    });
  }
});

// Get payment by ID
router.get("/:payment_id", authenticateToken, async (req, res) => {
  try {
    const { payment_id } = req.params;
    const user_id = req.user.user_id;

    const payment = await prisma.payment.findFirst({
      where: {
        payment_id: payment_id,
        user_id: user_id, // Ensure user can only access their own payments
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
            start_time: true,
            venue: true,
            location: true,
          },
        },
      },
    });

    if (!payment) {
      return res.status(404).json({
        success: false,
        message: "Payment not found",
      });
    }

    res.json({
      success: true,
      payment: payment,
    });
  } catch (error) {
    console.error("Error fetching payment:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch payment",
      error: error.message,
    });
  }
});

// Update payment status (for payment gateway callbacks)
router.put("/:payment_id/status", authenticateToken, async (req, res) => {
  try {
    const { payment_id } = req.params;
    const { status, transaction_ref } = req.body;

    // Validate status
    const validStatuses = ["pending", "completed", "failed", "refunded"];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: "Invalid payment status",
      });
    }

    const payment = await prisma.payment.update({
      where: { payment_id: payment_id },
      data: {
        status: Status[status],
        ...(transaction_ref && { transaction_ref: transaction_ref }),
      },
    });

    res.json({
      success: true,
      message: "Payment status updated successfully",
      payment: payment,
    });
  } catch (error) {
    console.error("Error updating payment status:", error);
    res.status(500).json({
      success: false,
      message: "Failed to update payment status",
      error: error.message,
    });
  }
});

module.exports = router;
