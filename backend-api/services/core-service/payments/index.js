// Payments service (ported core logic from monolith routes/payments.js)
const prisma = require("../lib/database");
const { Status } = require("@prisma/client");

function generateTransactionRef(payment_id) {
  return (
    payment_id || `TXN_${Date.now()}_${Math.random().toString(36).slice(2, 11)}`
  );
}

async function createTicketPurchaseRecords(
  payment,
  event_id,
  user_id,
  seatContext
) {
  const {
    seatMap,
    selectedSeatIds,
    selectedSeatData,
    selectedSeatsRaw,
    amount,
  } = seatContext;
  const ticketRecords = [];

  if (seatMap && Array.isArray(seatMap)) {
    // Seat map (reserved seating) flow
    for (const seatId of selectedSeatIds) {
      const seat = seatMap.find((s) => s.id === seatId);
      if (!seat) continue;
      const qrCode = `TICKET_${payment.payment_id}_${seatId}_${Date.now()}`;
      ticketRecords.push({
        event_id: parseInt(event_id),
        user_id,
        payment_id: payment.payment_id,
        seat_id: seatId,
        seat_label: seat.label,
        purchase_date: new Date(),
        price: BigInt(Math.round(seat.price * 100)),
        attended: false,
        qr_code: qrCode,
      });
    }
  } else {
    // General admission / ticket types
    if (selectedSeatData && Array.isArray(selectedSeatData)) {
      selectedSeatData.forEach((seatData, idx) => {
        const qrCode = `TICKET_${payment.payment_id}_${idx + 1}_${Date.now()}`;
        ticketRecords.push({
          event_id: parseInt(event_id),
          user_id,
          payment_id: payment.payment_id,
          seat_id: null,
          seat_label:
            seatData.label || selectedSeatsRaw[idx] || `Ticket ${idx + 1}`,
          purchase_date: new Date(),
          price: BigInt(Math.round(parseFloat(seatData.price || 0) * 100)),
          attended: false,
          qr_code: qrCode,
        });
      });
    } else if (selectedSeatsRaw && Array.isArray(selectedSeatsRaw)) {
      const pricePerTicket = parseFloat(amount) / selectedSeatsRaw.length;
      selectedSeatsRaw.forEach((label, idx) => {
        const qrCode = `TICKET_${payment.payment_id}_${idx + 1}_${Date.now()}`;
        ticketRecords.push({
          event_id: parseInt(event_id),
          user_id,
          payment_id: payment.payment_id,
          seat_id: null,
          seat_label: label,
          purchase_date: new Date(),
          price: BigInt(Math.round(pricePerTicket * 100)),
          attended: false,
          qr_code: qrCode,
        });
      });
    }
  }

  // Persist tickets
  for (const ticket of ticketRecords) {
    try {
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
    } catch (err) {
      console.error("Error inserting ticket record", { err, ticket });
    }
  }

  return ticketRecords.length;
}

module.exports = {
  async createPayment(
    {
      event_id,
      amount,
      payment_method,
      selected_seats,
      payment_id,
      selectedSeatData,
    },
    user
  ) {
    if (
      !event_id ||
      !amount ||
      !selected_seats ||
      selected_seats.length === 0
    ) {
      throw new Error("Event ID, amount, and selected seats are required");
    }

    const event = await prisma.event.findUnique({
      where: { event_id: parseInt(event_id) },
    });
    if (!event) throw new Error("Event not found");

    const payment = await prisma.payment.create({
      data: {
        user_id: user.user_id,
        event_id: parseInt(event_id),
        amount: parseFloat(amount),
        payment_method: payment_method || "card",
        status: Status.completed,
        transaction_ref: generateTransactionRef(payment_id),
      },
      include: {
        user: { select: { user_id: true, name: true, email: true } },
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

    // Seat updates & ticket creation
    const seatMap = payment.event.seat_map;
    let selectedSeatIds = [];
    if (seatMap && Array.isArray(seatMap)) {
      selectedSeatIds = selected_seats.map((id) => parseInt(id, 10));
      const updatedSeatMap = seatMap.map((seat) =>
        selectedSeatIds.includes(seat.id) ? { ...seat, available: false } : seat
      );
      await prisma.event.update({
        where: { event_id: parseInt(event_id) },
        data: { seat_map: updatedSeatMap },
      });
    }

    await createTicketPurchaseRecords(payment, event_id, user.user_id, {
      seatMap,
      selectedSeatIds,
      selectedSeatData,
      selectedSeatsRaw: selected_seats,
      amount,
    });

    return payment;
  },

  async getUserPayments(userId) {
    return prisma.payment.findMany({
      where: { user_id: userId },
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
      orderBy: { payment_date: "desc" },
    });
  },

  async getPayment(payment_id, userId) {
    return prisma.payment.findFirst({
      where: { payment_id, user_id: userId },
      include: {
        user: { select: { name: true, email: true, phone_number: true } },
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
  },

  async updateStatus(payment_id, status, transaction_ref) {
    const validStatuses = ["pending", "completed", "failed", "refunded"];
    if (!validStatuses.includes(status))
      throw new Error("Invalid payment status");
    return prisma.payment.update({
      where: { payment_id },
      data: {
        status: Status[status],
        ...(transaction_ref && { transaction_ref }),
      },
    });
  },
};
