// Tickets service (ported from monolith routes/tickets.js)
const prisma = require("../lib/database");

function serializeTicket(ticket) {
  if (!ticket) return null;
  return {
    ...ticket,
    price: ticket.price != null ? Number(ticket.price) : null,
    user_id: ticket.user_id != null ? Number(ticket.user_id) : null,
    event_id: ticket.event_id != null ? Number(ticket.event_id) : null,
  };
}

module.exports = {
  async getUserTickets(userId) {
    const tickets = await prisma.ticketPurchase.findMany({
      where: { user_id: userId },
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
      orderBy: { purchase_date: "desc" },
    });
    return tickets.map(serializeTicket);
  },

  async getTicketByQr(qrCode) {
    const ticket = await prisma.ticketPurchase.findFirst({
      where: { qr_code: qrCode },
      include: {
        user: { select: { name: true, email: true } },
        event: { select: { title: true, start_time: true, venue: true } },
        payment: { select: { status: true } },
      },
    });
    return serializeTicket(ticket);
  },

  async getTicketDetails(ticketId, userId) {
    const ticket = await prisma.ticketPurchase.findFirst({
      where: { ticket_id: ticketId, user_id: userId },
      include: {
        user: { select: { name: true, email: true, phone_number: true } },
        event: {
          select: {
            title: true,
            description: true,
            start_time: true,
            end_time: true,
            venue: true,
            location: true,
            cover_image_url: true,
            ticket_price: true,
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
    if (!ticket) return null;

    // Ensure QR code exists
    if (!ticket.qr_code) {
      const qrCode = `TICKET:${ticket.ticket_id}:${ticket.event_id}:${
        ticket.user_id
      }:${Date.now()}`;
      await prisma.ticketPurchase.update({
        where: { ticket_id: ticket.ticket_id },
        data: { qr_code: qrCode },
      });
      ticket.qr_code = qrCode;
    }

    const serialized = serializeTicket(ticket);
    serialized.qr_code = ticket.qr_code;
    serialized.event = {
      ...ticket.event,
      ticket_price: ticket.event?.ticket_price
        ? Number(ticket.event.ticket_price)
        : null,
    };
    return serialized;
  },

  async markTicketAttended(ticketId) {
    const ticket = await prisma.ticketPurchase.update({
      where: { ticket_id: ticketId },
      data: { attended: true },
      include: {
        user: { select: { name: true, email: true } },
        event: { select: { title: true } },
      },
    });
    return serializeTicket(ticket);
  },

  async getEventTickets(eventId) {
    const tickets = await prisma.ticketPurchase.findMany({
      where: { event_id: parseInt(eventId) },
      include: {
        user: { select: { name: true, email: true } },
        payment: { select: { status: true, payment_method: true } },
      },
      orderBy: { purchase_date: "desc" },
    });
    return tickets.map(serializeTicket);
  },

  async getTicketByPayment(paymentId, userId) {
    const ticket = await prisma.ticketPurchase.findFirst({
      where: { payment_id: paymentId, user_id: userId },
      include: {
        user: { select: { name: true, email: true, phone_number: true } },
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
    if (!ticket) return null;
    if (!ticket.qr_code) {
      const qrCode = `TICKET:${ticket.ticket_id}:${ticket.event_id}:${
        ticket.user_id
      }:${Date.now()}`;
      await prisma.ticketPurchase.update({
        where: { ticket_id: ticket.ticket_id },
        data: { qr_code: qrCode },
      });
      ticket.qr_code = qrCode;
    }
    const serialized = serializeTicket(ticket);
    serialized.qr_code = ticket.qr_code;
    return serialized;
  },
};
