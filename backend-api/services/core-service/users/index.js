// Users module
const prisma = require('../../../lib/database');

module.exports = {
  async getUserById(id) {
    return await prisma.user.findUnique({ where: { id } });
  },
  // Add more user-related functions here
};
