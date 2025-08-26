// Events module
const prisma = require("../../../lib/database");

module.exports = {
  // Get single event by ID
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
            },
          },
        },
      });
    } catch (error) {
      throw new Error(`Failed to fetch event: ${error.message}`);
    }
  },

  // Get all events with optional filtering
  async getAllEvents(filters = {}) {
    try {
      const where = {};

      if (filters.category) {
        where.category = filters.category;
      }

      if (filters.status) {
        where.status = filters.status;
      }

      if (filters.organization_id) {
        where.organization_id = parseInt(filters.organization_id);
      }

      if (filters.location) {
        where.location = { contains: filters.location, mode: "insensitive" };
      }

      if (filters.start_date) {
        where.start_time = { gte: new Date(filters.start_date) };
      }

      if (filters.end_date) {
        where.end_time = { lte: new Date(filters.end_date) };
      }

      return await prisma.event.findMany({
        where,
        include: {
          organization: {
            select: {
              organization_id: true,
              name: true,
              logo_url: true,
            },
          },
        },
        orderBy: { start_time: "asc" },
      });
    } catch (error) {
      throw new Error(`Failed to fetch events: ${error.message}`);
    }
  },

  // Create new event
  async createEvent(data) {
    try {
      return await prisma.event.create({
        data: {
          organization_id: data.organization_id
            ? parseInt(data.organization_id)
            : null,
          title: data.title,
          description: data.description || null,
          category: data.category || null,
          venue: data.venue || null,
          location: data.location || null,
          start_time: new Date(data.start_time),
          end_time: new Date(data.end_time),
          capacity: data.capacity ? parseInt(data.capacity) : null,
          cover_image_url: data.cover_image_url || null,
          other_images_url: data.other_images_url || null,
          video_url: data.video_url || null,
          status: data.status || "ACTIVE",
        },
        include: {
          organization: {
            select: {
              organization_id: true,
              name: true,
              logo_url: true,
            },
          },
        },
      });
    } catch (error) {
      throw new Error(`Failed to create event: ${error.message}`);
    }
  },

  // Update event
  async updateEvent(id, data) {
    try {
      const updateData = { ...data };
      delete updateData.event_id;
      delete updateData.created_at;

      // Convert dates if provided
      if (updateData.start_time) {
        updateData.start_time = new Date(updateData.start_time);
      }
      if (updateData.end_time) {
        updateData.end_time = new Date(updateData.end_time);
      }

      // Convert numbers if provided
      if (updateData.organization_id) {
        updateData.organization = {
    connect: { organization_id: parseInt(updateData.organization_id) }
      };
      delete updateData.organization_id;
      }
      if (updateData.capacity) {
        updateData.capacity = parseInt(updateData.capacity);
      }

      // Ensure video_url is present
      if (!("video_url" in updateData)) {
        updateData.video_url = null;
      }

      return await prisma.event.update({
        where: { event_id: parseInt(id) },
        data: updateData,
        include: {
          organization: {
            select: {
              organization_id: true,
              name: true,
              logo_url: true,
            },
          },
        },
      });
    } catch (error) {
      throw new Error(`Failed to update event: ${error.message}`);
    }
  },

  // Delete event
  async deleteEvent(id) {
    try {
      return await prisma.event.delete({
        where: { event_id: parseInt(id) },
      });
    } catch (error) {
      throw new Error(`Failed to delete event: ${error.message}`);
    }
  },

  // Search events
  async searchEvents(query, filters = {}) {
    try {
      const where = {
        OR: [
          { title: { contains: query, mode: "insensitive" } },
          { description: { contains: query, mode: "insensitive" } },
          { category: { contains: query, mode: "insensitive" } },
          { venue: { contains: query, mode: "insensitive" } },
          { location: { contains: query, mode: "insensitive" } },
        ],
      };

      // Apply additional filters
      if (filters.category) {
        where.category = filters.category;
      }
      if (filters.status) {
        where.status = filters.status;
      }
      if (filters.start_date) {
        where.start_time = { gte: new Date(filters.start_date) };
      }

      return await prisma.event.findMany({
        where,
        include: {
          organization: {
            select: {
              organization_id: true,
              name: true,
              logo_url: true,
            },
          },
        },
        orderBy: { start_time: "asc" },
      });
    } catch (error) {
      throw new Error(`Failed to search events: ${error.message}`);
    }
  },

  // Get upcoming events
  async getUpcomingEvents(limit = 10) {
    try {
      return await prisma.event.findMany({
        where: {
          start_time: { gte: new Date() },
          status: "ACTIVE",
        },
        include: {
          organization: {
            select: {
              organization_id: true,
              name: true,
              logo_url: true,
            },
          },
        },
        orderBy: { start_time: "asc" },
        take: limit,
      });
    } catch (error) {
      throw new Error(`Failed to fetch upcoming events: ${error.message}`);
    }
  },

  // Get events by category
  async getEventsByCategory(category, limit = 20) {
    try {
      return await prisma.event.findMany({
        where: {
          category: category,
          status: "ACTIVE",
        },
        include: {
          organization: {
            select: {
              organization_id: true,
              name: true,
              logo_url: true,
            },
          },
        },
        orderBy: { start_time: "asc" },
        take: limit,
      });
    } catch (error) {
      throw new Error(`Failed to fetch events by category: ${error.message}`);
    }
  },
};
