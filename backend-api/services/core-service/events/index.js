// Events module
const prisma = require('../../../lib/database');

module.exports = {
  async getEventById(id) {
    return await prisma.event.findUnique({ where: { id } });
  },
  // Add more event-related functions here
};
