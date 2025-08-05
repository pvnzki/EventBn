// Events service module within core-service
const prisma = require('../../../lib/database');

class EventService {
  // Get event by ID
  async getEventById(id) {
    try {
      return await prisma.event.findUnique({ 
        where: { event_id: parseInt(id) },
        include: {
          organization: {
            select: {
              organization_id: true,
              name: true,
              logo_url: true,
              contact_email: true,
            }
          }
        }
      });
    } catch (error) {
      throw new Error(`Failed to get event: ${error.message}`);
    }
  }

  // Create new event
  async createEvent(eventData, organizerId) {
    try {
      const { 
        title, description, category, venue, location, 
        start_time, end_time, capacity, organization_id,
        cover_image_url, other_images_url
      } = eventData;
      
      return await prisma.event.create({
        data: {
          title,
          description,
          category,
          venue,
          location,
          start_time: new Date(start_time),
          end_time: new Date(end_time),
          capacity,
          organization_id: organization_id ? parseInt(organization_id) : null,
          cover_image_url,
          other_images_url,
          status: 'draft',
        },
        include: {
          organization: {
            select: {
              organization_id: true,
              name: true,
            }
          }
        }
      });
    } catch (error) {
      throw new Error(`Failed to create event: ${error.message}`);
    }
  }

  // Update event
  async updateEvent(id, updateData) {
    try {
      return await prisma.event.update({
        where: { event_id: parseInt(id) },
        data: {
          ...updateData,
          ...(updateData.start_time && { start_time: new Date(updateData.start_time) }),
          ...(updateData.end_time && { end_time: new Date(updateData.end_time) }),
        },
        include: {
          organization: {
            select: {
              organization_id: true,
              name: true,
            }
          }
        }
      });
    } catch (error) {
      throw new Error(`Failed to update event: ${error.message}`);
    }
  }

  // Delete event
  async deleteEvent(id) {
    try {
      return await prisma.event.delete({
        where: { event_id: parseInt(id) }
      });
    } catch (error) {
      throw new Error(`Failed to delete event: ${error.message}`);
    }
  }

  // Get all events with filters and pagination
  async getAllEvents(filters = {}, page = 1, limit = 10) {
    try {
      const { 
        category, location, start_time, end_time, 
        status = 'published', organization_id 
      } = filters;
      
      const skip = (page - 1) * limit;
      
      const where = {
        status,
        ...(category && { category: { contains: category, mode: 'insensitive' } }),
        ...(location && { location: { contains: location, mode: 'insensitive' } }),
        ...(organization_id && { organization_id: parseInt(organization_id) }),
        ...(start_time && { start_time: { gte: new Date(start_time) } }),
        ...(end_time && { end_time: { lte: new Date(end_time) } }),
      };

      const [events, total] = await Promise.all([
        prisma.event.findMany({
          where,
          skip,
          take: limit,
          include: {
            organization: {
              select: {
                organization_id: true,
                name: true,
                logo_url: true,
              }
            }
          },
          orderBy: { start_time: 'asc' }
        }),
        prisma.event.count({ where })
      ]);

      return {
        events,
        pagination: {
          current: page,
          total: Math.ceil(total / limit),
          count: total
        }
      };
    } catch (error) {
      throw new Error(`Failed to get events: ${error.message}`);
    }
  }

  // Publish event
  async publishEvent(id) {
    try {
      return await this.updateEvent(id, { status: 'published' });
    } catch (error) {
      throw new Error(`Failed to publish event: ${error.message}`);
    }
  }

  // Cancel event
  async cancelEvent(id) {
    try {
      return await this.updateEvent(id, { status: 'cancelled' });
    } catch (error) {
      throw new Error(`Failed to cancel event: ${error.message}`);
    }
  }

  // Health check
  async healthCheck() {
    try {
      await prisma.event.findFirst();
      return { status: 'healthy', timestamp: new Date().toISOString() };
    } catch (error) {
      throw new Error(`Events service unhealthy: ${error.message}`);
    }
  }
}

module.exports = new EventService();
