// Organizations module
const prisma = require('../../../lib/database');

module.exports = {
  async getOrganizationById(id) {
    return await prisma.organization.findUnique({ where: { id } });
  },
  // Add more organization-related functions here
};
