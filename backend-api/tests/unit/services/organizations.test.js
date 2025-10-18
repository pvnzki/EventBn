const organizationsService = require('../../../services/core-service/organizations/index');
const prisma = require('../../../lib/database');

// Mock Prisma
jest.mock('../../../lib/database', () => ({
  organization: {
    findUnique: jest.fn(),
    findMany: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
  },
  event: {
    findMany: jest.fn(),
  },
}));

describe('Organizations Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('getOrganizationById', () => {
    const organizationId = 1;
    const mockOrganization = {
      organization_id: 1,
      name: 'Test Organization',
      description: 'Test Description',
      logo_url: 'https://example.com/logo.png',
      contact_email: 'test@example.com',
      contact_number: '+1234567890',
      website_url: 'https://example.com',
      user_id: 1,
      created_at: new Date(),
      updated_at: new Date(),
      user: {
        user_id: 1,
        name: 'John Doe',
        email: 'john@example.com'
      },
      events: [
        {
          event_id: 1,
          title: 'Test Event',
          start_time: new Date(),
          end_time: new Date(),
          status: 'ACTIVE',
          capacity: 100
        }
      ],
      _count: {
        events: 1
      }
    };

    it('should return organization by ID with related data', async () => {
      prisma.organization.findUnique.mockResolvedValueOnce(mockOrganization);

      const result = await organizationsService.getOrganizationById(organizationId);

      expect(prisma.organization.findUnique).toHaveBeenCalledWith({
        where: { organization_id: 1 },
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
      expect(result).toEqual(mockOrganization);
    });

    it('should handle string ID by converting to integer', async () => {
      prisma.organization.findUnique.mockResolvedValueOnce(mockOrganization);

      await organizationsService.getOrganizationById('1');

      expect(prisma.organization.findUnique).toHaveBeenCalledWith({
        where: { organization_id: 1 },
        include: expect.any(Object)
      });
    });

    it('should return null for non-existent organization', async () => {
      prisma.organization.findUnique.mockResolvedValueOnce(null);

      const result = await organizationsService.getOrganizationById(999);

      expect(result).toBeNull();
    });

    it('should throw error if database fails', async () => {
      prisma.organization.findUnique.mockRejectedValueOnce(new Error('DB error'));

      await expect(organizationsService.getOrganizationById(organizationId))
        .rejects
        .toThrow('Failed to fetch organization: DB error');
    });
  });

  describe('getAllOrganizations', () => {
    const mockOrganizations = [
      {
        organization_id: 1,
        name: 'Test Organization 1',
        user: { user_id: 1, name: 'John Doe', email: 'john@example.com' },
        _count: { events: 2 }
      },
      {
        organization_id: 2,
        name: 'Test Organization 2',
        user: { user_id: 2, name: 'Jane Doe', email: 'jane@example.com' },
        _count: { events: 1 }
      }
    ];

    it('should return all organizations when no filters provided', async () => {
      prisma.organization.findMany.mockResolvedValueOnce(mockOrganizations);

      const result = await organizationsService.getAllOrganizations();

      expect(prisma.organization.findMany).toHaveBeenCalledWith({
        where: {},
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
      expect(result).toEqual(mockOrganizations);
    });

    it('should filter by organization name', async () => {
      prisma.organization.findMany.mockResolvedValueOnce([mockOrganizations[0]]);

      await organizationsService.getAllOrganizations({ name: 'Test Organization 1' });

      expect(prisma.organization.findMany).toHaveBeenCalledWith({
        where: {
          name: { contains: 'Test Organization 1', mode: 'insensitive' }
        },
        include: expect.any(Object),
        orderBy: { created_at: 'desc' }
      });
    });

    it('should filter by user_id', async () => {
      prisma.organization.findMany.mockResolvedValueOnce([mockOrganizations[0]]);

      await organizationsService.getAllOrganizations({ user_id: 1 });

      expect(prisma.organization.findMany).toHaveBeenCalledWith({
        where: { user_id: 1 },
        include: expect.any(Object),
        orderBy: { created_at: 'desc' }
      });
    });

    it('should handle string user_id by converting to integer', async () => {
      prisma.organization.findMany.mockResolvedValueOnce([mockOrganizations[0]]);

      await organizationsService.getAllOrganizations({ user_id: '1' });

      expect(prisma.organization.findMany).toHaveBeenCalledWith({
        where: { user_id: 1 },
        include: expect.any(Object),
        orderBy: { created_at: 'desc' }
      });
    });

    it('should combine multiple filters', async () => {
      prisma.organization.findMany.mockResolvedValueOnce([mockOrganizations[0]]);

      await organizationsService.getAllOrganizations({ 
        name: 'Test', 
        user_id: 1 
      });

      expect(prisma.organization.findMany).toHaveBeenCalledWith({
        where: {
          name: { contains: 'Test', mode: 'insensitive' },
          user_id: 1
        },
        include: expect.any(Object),
        orderBy: { created_at: 'desc' }
      });
    });

    it('should return empty array when no organizations found', async () => {
      prisma.organization.findMany.mockResolvedValueOnce([]);

      const result = await organizationsService.getAllOrganizations();

      expect(result).toEqual([]);
    });

    it('should throw error if database fails', async () => {
      prisma.organization.findMany.mockRejectedValueOnce(new Error('DB error'));

      await expect(organizationsService.getAllOrganizations())
        .rejects
        .toThrow('Failed to fetch organizations: DB error');
    });
  });

  describe('createOrganization', () => {
    const organizationData = {
      user_id: 1,
      name: 'New Organization',
      description: 'New Description',
      logo_url: 'https://example.com/logo.png',
      contact_email: 'contact@example.com',
      contact_number: '+1234567890',
      website_url: 'https://example.com'
    };

    const mockCreatedOrganization = {
      organization_id: 1,
      ...organizationData,
      user_id: 1,
      created_at: new Date(),
      updated_at: new Date(),
      user: {
        user_id: 1,
        name: 'John Doe',
        email: 'john@example.com'
      }
    };

    it('should create organization with all provided data', async () => {
      prisma.organization.create.mockResolvedValueOnce(mockCreatedOrganization);

      const result = await organizationsService.createOrganization(organizationData);

      expect(prisma.organization.create).toHaveBeenCalledWith({
        data: {
          user_id: 1,
          name: 'New Organization',
          description: 'New Description',
          logo_url: 'https://example.com/logo.png',
          contact_email: 'contact@example.com',
          contact_number: '+1234567890',
          website_url: 'https://example.com'
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
      expect(result).toEqual(mockCreatedOrganization);
    });

    it('should create organization with minimal data and null defaults', async () => {
      const minimalData = {
        user_id: 1,
        name: 'Minimal Organization'
      };

      prisma.organization.create.mockResolvedValueOnce({
        ...mockCreatedOrganization,
        ...minimalData,
        description: null,
        logo_url: null,
        contact_email: null,
        contact_number: null,
        website_url: null
      });

      await organizationsService.createOrganization(minimalData);

      expect(prisma.organization.create).toHaveBeenCalledWith({
        data: {
          user_id: 1,
          name: 'Minimal Organization',
          description: null,
          logo_url: null,
          contact_email: null,
          contact_number: null,
          website_url: null
        },
        include: expect.any(Object)
      });
    });

    it('should handle string user_id by converting to integer', async () => {
      prisma.organization.create.mockResolvedValueOnce(mockCreatedOrganization);

      await organizationsService.createOrganization({
        ...organizationData,
        user_id: '1'
      });

      expect(prisma.organization.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          user_id: 1
        }),
        include: expect.any(Object)
      });
    });

    it('should throw error if database fails', async () => {
      prisma.organization.create.mockRejectedValueOnce(new Error('DB error'));

      await expect(organizationsService.createOrganization(organizationData))
        .rejects
        .toThrow('Failed to create organization: DB error');
    });
  });

  describe('updateOrganization', () => {
    const organizationId = 1;
    const updateData = {
      name: 'Updated Organization',
      description: 'Updated Description',
      organization_id: 999, // Should be removed
      created_at: new Date() // Should be removed
    };

    const mockUpdatedOrganization = {
      organization_id: 1,
      name: 'Updated Organization',
      description: 'Updated Description',
      user: {
        user_id: 1,
        name: 'John Doe',
        email: 'john@example.com'
      },
      _count: {
        events: 2
      }
    };

    it('should update organization successfully', async () => {
      prisma.organization.update.mockResolvedValueOnce(mockUpdatedOrganization);

      const result = await organizationsService.updateOrganization(organizationId, updateData);

      expect(prisma.organization.update).toHaveBeenCalledWith({
        where: { organization_id: 1 },
        data: {
          name: 'Updated Organization',
          description: 'Updated Description'
          // organization_id and created_at should be removed
        },
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
      expect(result).toEqual(mockUpdatedOrganization);
    });

    it('should handle string ID by converting to integer', async () => {
      prisma.organization.update.mockResolvedValueOnce(mockUpdatedOrganization);

      await organizationsService.updateOrganization('1', updateData);

      expect(prisma.organization.update).toHaveBeenCalledWith({
        where: { organization_id: 1 },
        data: expect.any(Object),
        include: expect.any(Object)
      });
    });

    it('should remove restricted fields from update data', async () => {
      prisma.organization.update.mockResolvedValueOnce(mockUpdatedOrganization);

      await organizationsService.updateOrganization(organizationId, updateData);

      const updateCall = prisma.organization.update.mock.calls[0][0];
      expect(updateCall.data).not.toHaveProperty('organization_id');
      expect(updateCall.data).not.toHaveProperty('created_at');
    });

    it('should throw error if database fails', async () => {
      prisma.organization.update.mockRejectedValueOnce(new Error('DB error'));

      await expect(organizationsService.updateOrganization(organizationId, updateData))
        .rejects
        .toThrow('Failed to update organization: DB error');
    });
  });

  describe('deleteOrganization', () => {
    const organizationId = 1;
    const mockDeletedOrganization = { organization_id: 1, name: 'Deleted Org' };

    it('should delete organization successfully', async () => {
      prisma.organization.delete.mockResolvedValueOnce(mockDeletedOrganization);

      const result = await organizationsService.deleteOrganization(organizationId);

      expect(prisma.organization.delete).toHaveBeenCalledWith({
        where: { organization_id: 1 }
      });
      expect(result).toEqual(mockDeletedOrganization);
    });

    it('should handle string ID by converting to integer', async () => {
      prisma.organization.delete.mockResolvedValueOnce(mockDeletedOrganization);

      await organizationsService.deleteOrganization('1');

      expect(prisma.organization.delete).toHaveBeenCalledWith({
        where: { organization_id: 1 }
      });
    });

    it('should throw error if database fails', async () => {
      prisma.organization.delete.mockRejectedValueOnce(new Error('DB error'));

      await expect(organizationsService.deleteOrganization(organizationId))
        .rejects
        .toThrow('Failed to delete organization: DB error');
    });
  });

  describe('getOrganizationEvents', () => {
    const organizationId = 1;
    const mockEvents = [
      {
        event_id: 1,
        title: 'Event 1',
        start_time: new Date('2024-01-15'),
        end_time: new Date('2024-01-15'),
        status: 'ACTIVE',
        organization_id: 1,
        organization: {
          organization_id: 1,
          name: 'Test Organization'
        }
      },
      {
        event_id: 2,
        title: 'Event 2',
        start_time: new Date('2024-01-16'),
        end_time: new Date('2024-01-16'),
        status: 'DRAFT',
        organization_id: 1,
        organization: {
          organization_id: 1,
          name: 'Test Organization'
        }
      }
    ];

    it('should return all events for organization without status filter', async () => {
      prisma.event.findMany.mockResolvedValueOnce(mockEvents);

      const result = await organizationsService.getOrganizationEvents(organizationId);

      expect(prisma.event.findMany).toHaveBeenCalledWith({
        where: { organization_id: 1 },
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
      expect(result).toEqual(mockEvents);
    });

    it('should filter events by status', async () => {
      const activeEvents = [mockEvents[0]];
      prisma.event.findMany.mockResolvedValueOnce(activeEvents);

      const result = await organizationsService.getOrganizationEvents(organizationId, 'ACTIVE');

      expect(prisma.event.findMany).toHaveBeenCalledWith({
        where: { 
          organization_id: 1,
          status: 'ACTIVE'
        },
        include: expect.any(Object),
        orderBy: { start_time: 'asc' }
      });
      expect(result).toEqual(activeEvents);
    });

    it('should handle string organizationId by converting to integer', async () => {
      prisma.event.findMany.mockResolvedValueOnce(mockEvents);

      await organizationsService.getOrganizationEvents('1');

      expect(prisma.event.findMany).toHaveBeenCalledWith({
        where: { organization_id: 1 },
        include: expect.any(Object),
        orderBy: { start_time: 'asc' }
      });
    });

    it('should return empty array when no events found', async () => {
      prisma.event.findMany.mockResolvedValueOnce([]);

      const result = await organizationsService.getOrganizationEvents(organizationId);

      expect(result).toEqual([]);
    });

    it('should throw error if database fails', async () => {
      prisma.event.findMany.mockRejectedValueOnce(new Error('DB error'));

      await expect(organizationsService.getOrganizationEvents(organizationId))
        .rejects
        .toThrow('Failed to fetch organization events: DB error');
    });
  });

  describe('searchOrganizations', () => {
    const searchQuery = 'test';
    const mockSearchResults = [
      {
        organization_id: 1,
        name: 'Test Organization',
        description: 'A test organization',
        user: {
          user_id: 1,
          name: 'John Doe'
        },
        _count: {
          events: 3
        }
      },
      {
        organization_id: 2,
        name: 'Another Org',
        description: 'Contains test in description',
        user: {
          user_id: 2,
          name: 'Jane Doe'
        },
        _count: {
          events: 1
        }
      }
    ];

    it('should search organizations by name and description', async () => {
      prisma.organization.findMany.mockResolvedValueOnce(mockSearchResults);

      const result = await organizationsService.searchOrganizations(searchQuery);

      expect(prisma.organization.findMany).toHaveBeenCalledWith({
        where: {
          OR: [
            { name: { contains: 'test', mode: 'insensitive' } },
            { description: { contains: 'test', mode: 'insensitive' } }
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
      expect(result).toEqual(mockSearchResults);
    });

    it('should handle empty search query', async () => {
      prisma.organization.findMany.mockResolvedValueOnce([]);

      const result = await organizationsService.searchOrganizations('');

      expect(prisma.organization.findMany).toHaveBeenCalledWith({
        where: {
          OR: [
            { name: { contains: '', mode: 'insensitive' } },
            { description: { contains: '', mode: 'insensitive' } }
          ]
        },
        include: expect.any(Object),
        orderBy: { created_at: 'desc' }
      });
      expect(result).toEqual([]);
    });

    it('should return empty array when no matches found', async () => {
      prisma.organization.findMany.mockResolvedValueOnce([]);

      const result = await organizationsService.searchOrganizations('nonexistent');

      expect(result).toEqual([]);
    });

    it('should throw error if database fails', async () => {
      prisma.organization.findMany.mockRejectedValueOnce(new Error('DB error'));

      await expect(organizationsService.searchOrganizations(searchQuery))
        .rejects
        .toThrow('Failed to search organizations: DB error');
    });
  });

  describe('getOrganizationsByUser', () => {
    const userId = 1;
    const mockUserOrganizations = [
      {
        organization_id: 1,
        name: 'User Org 1',
        user_id: 1,
        _count: {
          events: 5
        }
      },
      {
        organization_id: 2,
        name: 'User Org 2',
        user_id: 1,
        _count: {
          events: 2
        }
      }
    ];

    it('should return organizations for specific user', async () => {
      prisma.organization.findMany.mockResolvedValueOnce(mockUserOrganizations);

      const result = await organizationsService.getOrganizationsByUser(userId);

      expect(prisma.organization.findMany).toHaveBeenCalledWith({
        where: { user_id: 1 },
        include: {
          _count: {
            select: { events: true }
          }
        },
        orderBy: { created_at: 'desc' }
      });
      expect(result).toEqual(mockUserOrganizations);
    });

    it('should handle string userId by converting to integer', async () => {
      prisma.organization.findMany.mockResolvedValueOnce(mockUserOrganizations);

      await organizationsService.getOrganizationsByUser('1');

      expect(prisma.organization.findMany).toHaveBeenCalledWith({
        where: { user_id: 1 },
        include: expect.any(Object),
        orderBy: { created_at: 'desc' }
      });
    });

    it('should return empty array when user has no organizations', async () => {
      prisma.organization.findMany.mockResolvedValueOnce([]);

      const result = await organizationsService.getOrganizationsByUser(userId);

      expect(result).toEqual([]);
    });

    it('should throw error if database fails', async () => {
      prisma.organization.findMany.mockRejectedValueOnce(new Error('DB error'));

      await expect(organizationsService.getOrganizationsByUser(userId))
        .rejects
        .toThrow('Failed to fetch user organizations: DB error');
    });
  });
});