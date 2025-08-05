// Tickets module
const prisma = require('../../../lib/database');

module.exports = {
  async getTicketById(id) {
    return await prisma.ticket.findUnique({ where: { id } });
  },
  // Add more ticket-related functions here
};
