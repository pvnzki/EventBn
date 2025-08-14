// Organizations module
const prisma = require('../../../lib/database');

module.exports = {
  // Get single organization by ID
  async getOrganizationById(id) {
    try {
      return await prisma.organization.findUnique({ 
        where: { organization_id: parseInt(id) },
        include: {
          user: {
            select: {
              user_id: true,
              name: true,
              email: true
            }
          },
          events: {
            select: {
              event_id: true,
              title: true,
              start_time: true,
              end_time: true,
              status: true,
              capacity: true
            },
            orderBy: { start_time: 'asc' }
          },
          _count: {
            select: { events: true }
          }
        }
      });
    } catch (error) {
      throw new Error(`Failed to fetch organization: ${error.message}`);
    }
  },

  // Get all organizations with optional filtering
  async getAllOrganizations(filters = {}) {
    try {
      const where = {};
      
      if (filters.name) {
        where.name = { contains: filters.name, mode: 'insensitive' };
      }
      
      if (filters.user_id) {
        where.user_id = parseInt(filters.user_id);
      }

      return await prisma.organization.findMany({
        where,
        include: {
          user: {
            select: {
              user_id: true,
              name: true,
              email: true
            }
          },
          _count: {
            select: { events: true }
          }
        },
        orderBy: { created_at: 'desc' }
      });
    } catch (error) {
      throw new Error(`Failed to fetch organizations: ${error.message}`);
    }
  },

  // Create new organization
  async createOrganization(data) {
    try {
      return await prisma.organization.create({
        data: {
          user_id: parseInt(data.user_id),
          name: data.name,
          description: data.description || null,
          logo_url: data.logo_url || null,
          contact_email: data.contact_email || null,
          contact_number: data.contact_number || null,
          website_url: data.website_url || null
        },
        include: {
          user: {
            select: {
              user_id: true,
              name: true,
              email: true
            }
          }
        }
      });
    } catch (error) {
      throw new Error(`Failed to create organization: ${error.message}`);
    }
  },

  // Update organization
  async updateOrganization(id, data) {
    try {
      const updateData = { ...data };
      delete updateData.organization_id; // Remove ID from update data
      delete updateData.created_at; // Remove created_at from update data

      return await prisma.organization.update({
        where: { organization_id: parseInt(id) },
        data: updateData,
        include: {
          user: {
            select: {
              user_id: true,
              name: true,
              email: true
            }
          },
          _count: {
            select: { events: true }
          }
        }
      });
    } catch (error) {
      throw new Error(`Failed to update organization: ${error.message}`);
    }
  },

  // Delete organization
  async deleteOrganization(id) {
    try {
      return await prisma.organization.delete({
        where: { organization_id: parseInt(id) }
      });
    } catch (error) {
      throw new Error(`Failed to delete organization: ${error.message}`);
    }
  },

  // Get organization events
  async getOrganizationEvents(organizationId, status = null) {
    try {
      const where = { organization_id: parseInt(organizationId) };
      if (status) where.status = status;

      return await prisma.event.findMany({
        where,
        include: {
          organization: {
            select: {
              organization_id: true,
              name: true
            }
          }
        },
        orderBy: { start_time: 'asc' }
      });
    } catch (error) {
      throw new Error(`Failed to fetch organization events: ${error.message}`);
    }
  },

  // Search organizations
  async searchOrganizations(query) {
    try {
      return await prisma.organization.findMany({
        where: {
          OR: [
            { name: { contains: query, mode: 'insensitive' } },
            { description: { contains: query, mode: 'insensitive' } }
          ]
        },
        include: {
          user: {
            select: {
              user_id: true,
              name: true
            }
          },
          _count: {
            select: { events: true }
          }
        },
        orderBy: { created_at: 'desc' }
      });
    } catch (error) {
      throw new Error(`Failed to search organizations: ${error.message}`);
    }
  },

  // Get organizations by user
  async getOrganizationsByUser(userId) {
    try {
      return await prisma.organization.findMany({
        where: { user_id: parseInt(userId) },
        include: {
          _count: {
            select: { events: true }
          }
        },
        orderBy: { created_at: 'desc' }
      });
    } catch (error) {
      throw new Error(`Failed to fetch user organizations: ${error.message}`);
    }
  }
};
