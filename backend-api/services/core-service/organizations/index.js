// Organizations service module within core-service
const prisma = require('../../../lib/database');

class OrganizationService {
  // Get organization by ID
  async getOrganizationById(id) {
    try {
      return await prisma.organization.findUnique({ 
        where: { id },
        include: {
          members: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              email: true,
              avatar: true,
            }
          },
          events: {
            select: {
              id: true,
              title: true,
              startDate: true,
              endDate: true,
              status: true,
            }
          }
        }
      });
    } catch (error) {
      throw new Error(`Failed to get organization: ${error.message}`);
    }
  }

  // Create new organization
  async createOrganization(orgData, ownerId) {
    try {
      const { name, description, website, logo, contactEmail } = orgData;
      
      return await prisma.organization.create({
        data: {
          name,
          description,
          website,
          logo,
          contactEmail,
          ownerId,
        },
        include: {
          owner: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              email: true,
            }
          }
        }
      });
    } catch (error) {
      throw new Error(`Failed to create organization: ${error.message}`);
    }
  }

  // Update organization
  async updateOrganization(id, updateData) {
    try {
      return await prisma.organization.update({
        where: { id },
        data: updateData,
      });
    } catch (error) {
      throw new Error(`Failed to update organization: ${error.message}`);
    }
  }

  // Delete organization
  async deleteOrganization(id) {
    try {
      return await prisma.organization.delete({
        where: { id }
      });
    } catch (error) {
      throw new Error(`Failed to delete organization: ${error.message}`);
    }
  }

  // Add member to organization
  async addMember(orgId, userId, role = 'MEMBER') {
    try {
      return await prisma.organizationMember.create({
        data: {
          organizationId: orgId,
          userId,
          role,
        },
        include: {
          user: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              email: true,
              avatar: true,
            }
          }
        }
      });
    } catch (error) {
      throw new Error(`Failed to add member: ${error.message}`);
    }
  }

  // Remove member from organization
  async removeMember(orgId, userId) {
    try {
      return await prisma.organizationMember.deleteMany({
        where: {
          organizationId: orgId,
          userId,
        }
      });
    } catch (error) {
      throw new Error(`Failed to remove member: ${error.message}`);
    }
  }

  // Get organization members
  async getOrganizationMembers(orgId) {
    try {
      return await prisma.organizationMember.findMany({
        where: { organizationId: orgId },
        include: {
          user: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              email: true,
              avatar: true,
            }
          }
        }
      });
    } catch (error) {
      throw new Error(`Failed to get organization members: ${error.message}`);
    }
  }

  // Get user's organizations
  async getUserOrganizations(userId) {
    try {
      return await prisma.organizationMember.findMany({
        where: { userId },
        include: {
          organization: {
            select: {
              id: true,
              name: true,
              description: true,
              logo: true,
              createdAt: true,
            }
          }
        }
      });
    } catch (error) {
      throw new Error(`Failed to get user organizations: ${error.message}`);
    }
  }

  // Get all organizations (with pagination)
  async getAllOrganizations(page = 1, limit = 10) {
    try {
      const skip = (page - 1) * limit;
      
      const [organizations, total] = await Promise.all([
        prisma.organization.findMany({
          skip,
          take: limit,
          select: {
            id: true,
            name: true,
            description: true,
            logo: true,
            website: true,
            createdAt: true,
            _count: {
              select: {
                members: true,
                events: true,
              }
            }
          },
          orderBy: { createdAt: 'desc' }
        }),
        prisma.organization.count()
      ]);

      return {
        organizations,
        pagination: {
          current: page,
          total: Math.ceil(total / limit),
          count: total
        }
      };
    } catch (error) {
      throw new Error(`Failed to get organizations: ${error.message}`);
    }
  }
}

module.exports = new OrganizationService();
