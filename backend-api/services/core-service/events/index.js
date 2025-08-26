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

      // Default seat map if none provided
      const defaultSeatMap = [
        {"label": "A1", "id": 1, "ticketType": "Economy", "price": 20.0, "available": true},
        {"label": "A2", "id": 2, "ticketType": "Economy", "price": 20.0, "available": true},
        {"label": "A3", "id": 3, "ticketType": "Economy", "price": 20.0, "available": true},
        {"label": "A4", "id": 4, "ticketType": "Economy", "price": 20.0, "available": true},
        {"label": "A5", "id": 5, "ticketType": "Economy", "price": 20.0, "available": true},
        {"label": "A6", "id": 6, "ticketType": "Economy", "price": 20.0, "available": true},
        {"label": "A7", "id": 7, "ticketType": "Economy", "price": 20.0, "available": true},
        {"label": "A8", "id": 8, "ticketType": "Economy", "price": 20.0, "available": true},
        {"label": "B1", "id": 9, "ticketType": "Economy", "price": 20.0, "available": true},
        {"label": "B2", "id": 10, "ticketType": "Economy", "price": 20.0, "available": true},
        {"label": "B3", "id": 11, "ticketType": "Economy", "price": 20.0, "available": true},
        {"label": "B4", "id": 12, "ticketType": "Economy", "price": 20.0, "available": true},
        {"label": "B5", "id": 13, "ticketType": "Economy", "price": 20.0, "available": true},
        {"label": "B6", "id": 14, "ticketType": "Economy", "price": 20.0, "available": true},
        {"label": "B7", "id": 15, "ticketType": "Economy", "price": 20.0, "available": true},
        {"label": "B8", "id": 16, "ticketType": "Economy", "price": 20.0, "available": true},
        {"label": "C1", "id": 17, "ticketType": "VIP", "price": 50.0, "available": true},
        {"label": "C2", "id": 18, "ticketType": "VIP", "price": 50.0, "available": true},
        {"label": "C3", "id": 19, "ticketType": "VIP", "price": 50.0, "available": true},
        {"label": "C4", "id": 20, "ticketType": "VIP", "price": 50.0, "available": true},
        {"label": "C5", "id": 21, "ticketType": "VIP", "price": 50.0, "available": true},
        {"label": "C6", "id": 22, "ticketType": "VIP", "price": 50.0, "available": true},
        {"label": "C7", "id": 23, "ticketType": "VIP", "price": 50.0, "available": true},
        {"label": "C8", "id": 24, "ticketType": "VIP", "price": 50.0, "available": true},
        {"label": "D1", "id": 25, "ticketType": "VIP", "price": 50.0, "available": true},
        {"label": "D2", "id": 26, "ticketType": "VIP", "price": 50.0, "available": true},
        {"label": "D3", "id": 27, "ticketType": "VIP", "price": 50.0, "available": true},
        {"label": "D4", "id": 28, "ticketType": "VIP", "price": 50.0, "available": true},
        {"label": "D5", "id": 29, "ticketType": "VIP", "price": 50.0, "available": true},
        {"label": "D6", "id": 30, "ticketType": "VIP", "price": 50.0, "available": true},
        {"label": "D7", "id": 31, "ticketType": "VIP", "price": 50.0, "available": true},
        {"label": "D8", "id": 32, "ticketType": "VIP", "price": 50.0, "available": true},
        {"label": "E1", "id": 33, "ticketType": "VIP", "price": 50.0, "available": true},
        {"label": "E2", "id": 34, "ticketType": "VIP", "price": 50.0, "available": true},
        {"label": "E3", "id": 35, "ticketType": "VIP", "price": 50.0, "available": true},
        {"label": "E4", "id": 36, "ticketType": "VIP", "price": 50.0, "available": true},
        {"label": "E5", "id": 37, "ticketType": "VIP", "price": 50.0, "available": true},
        {"label": "E6", "id": 38, "ticketType": "VIP", "price": 50.0, "available": true},
        {"label": "E7", "id": 39, "ticketType": "VIP", "price": 50.0, "available": true},
        {"label": "E8", "id": 40, "ticketType": "VIP", "price": 50.0, "available": true}
      ];

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

          seat_map: data.seat_map || defaultSeatMap,

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

      throw new Error(`Failed to fetch events by category: ${error.message}`);
    }
  },

  // Get seat map for an event
  async getSeatMap(eventId) {
    try {
      const event = await prisma.event.findUnique({
        where: { event_id: parseInt(eventId) },
        select: { seat_map: true },
      });

      if (!event) {
        throw new Error("Event not found");
      }

      // If no seat map exists, return default seat map
      if (!event.seat_map) {
        const defaultSeatMap = [
          {"label": "A1", "id": 1, "ticketType": "Economy", "price": 20.0, "available": true},
          {"label": "A2", "id": 2, "ticketType": "Economy", "price": 20.0, "available": true},
          {"label": "A3", "id": 3, "ticketType": "Economy", "price": 20.0, "available": true},
          {"label": "A4", "id": 4, "ticketType": "Economy", "price": 20.0, "available": true},
          {"label": "A5", "id": 5, "ticketType": "Economy", "price": 20.0, "available": true},
          {"label": "A6", "id": 6, "ticketType": "Economy", "price": 20.0, "available": true},
          {"label": "A7", "id": 7, "ticketType": "Economy", "price": 20.0, "available": true},
          {"label": "A8", "id": 8, "ticketType": "Economy", "price": 20.0, "available": true},
          {"label": "B1", "id": 9, "ticketType": "Economy", "price": 20.0, "available": true},
          {"label": "B2", "id": 10, "ticketType": "Economy", "price": 20.0, "available": true},
          {"label": "B3", "id": 11, "ticketType": "Economy", "price": 20.0, "available": true},
          {"label": "B4", "id": 12, "ticketType": "Economy", "price": 20.0, "available": true},
          {"label": "B5", "id": 13, "ticketType": "Economy", "price": 20.0, "available": true},
          {"label": "B6", "id": 14, "ticketType": "Economy", "price": 20.0, "available": true},
          {"label": "B7", "id": 15, "ticketType": "Economy", "price": 20.0, "available": true},
          {"label": "B8", "id": 16, "ticketType": "Economy", "price": 20.0, "available": true},
          {"label": "C1", "id": 17, "ticketType": "VIP", "price": 50.0, "available": true},
          {"label": "C2", "id": 18, "ticketType": "VIP", "price": 50.0, "available": true},
          {"label": "C3", "id": 19, "ticketType": "VIP", "price": 50.0, "available": true},
          {"label": "C4", "id": 20, "ticketType": "VIP", "price": 50.0, "available": true},
          {"label": "C5", "id": 21, "ticketType": "VIP", "price": 50.0, "available": true},
          {"label": "C6", "id": 22, "ticketType": "VIP", "price": 50.0, "available": true},
          {"label": "C7", "id": 23, "ticketType": "VIP", "price": 50.0, "available": true},
          {"label": "C8", "id": 24, "ticketType": "VIP", "price": 50.0, "available": true},
          {"label": "D1", "id": 25, "ticketType": "VIP", "price": 50.0, "available": true},
          {"label": "D2", "id": 26, "ticketType": "VIP", "price": 50.0, "available": true},
          {"label": "D3", "id": 27, "ticketType": "VIP", "price": 50.0, "available": true},
          {"label": "D4", "id": 28, "ticketType": "VIP", "price": 50.0, "available": true},
          {"label": "D5", "id": 29, "ticketType": "VIP", "price": 50.0, "available": true},
          {"label": "D6", "id": 30, "ticketType": "VIP", "price": 50.0, "available": true},
          {"label": "D7", "id": 31, "ticketType": "VIP", "price": 50.0, "available": true},
          {"label": "D8", "id": 32, "ticketType": "VIP", "price": 50.0, "available": true},
          {"label": "E1", "id": 33, "ticketType": "VIP", "price": 50.0, "available": true},
          {"label": "E2", "id": 34, "ticketType": "VIP", "price": 50.0, "available": true},
          {"label": "E3", "id": 35, "ticketType": "VIP", "price": 50.0, "available": true},
          {"label": "E4", "id": 36, "ticketType": "VIP", "price": 50.0, "available": true},
          {"label": "E5", "id": 37, "ticketType": "VIP", "price": 50.0, "available": true},
          {"label": "E6", "id": 38, "ticketType": "VIP", "price": 50.0, "available": true},
          {"label": "E7", "id": 39, "ticketType": "VIP", "price": 50.0, "available": true},
          {"label": "E8", "id": 40, "ticketType": "VIP", "price": 50.0, "available": true}
        ];
        
        // Save default seat map to database
        await prisma.event.update({
          where: { event_id: parseInt(eventId) },
          data: { seat_map: defaultSeatMap },
        });
        
        return defaultSeatMap;
      }

      return event.seat_map;
    } catch (error) {
      throw new Error(`Failed to fetch seat map: ${error.message}`);
    }
  },

  // Update seat map for an event (for booking seats)
  async updateSeatMap(eventId, seatMap) {
    try {
      const updatedEvent = await prisma.event.update({
        where: { event_id: parseInt(eventId) },
        data: { seat_map: seatMap },
        select: { seat_map: true },
      });

      return updatedEvent.seat_map;
    } catch (error) {
      throw new Error(`Failed to update seat map: ${error.message}`);
    }
  },

};
