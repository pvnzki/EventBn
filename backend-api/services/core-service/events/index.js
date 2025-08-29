// Events module
const prisma = require("../../../lib/database");

// Default seat map for events without custom seat maps - designed for ticket type selection
const DEFAULT_SEAT_MAP = [
  // Economy tickets (40 seats)
  {"label": "Economy Ticket 1", "id": 1, "ticketType": "Economy", "price": 25.0, "available": true},
  {"label": "Economy Ticket 2", "id": 2, "ticketType": "Economy", "price": 25.0, "available": true},
  {"label": "Economy Ticket 3", "id": 3, "ticketType": "Economy", "price": 25.0, "available": true},
  {"label": "Economy Ticket 4", "id": 4, "ticketType": "Economy", "price": 25.0, "available": true},
  {"label": "Economy Ticket 5", "id": 5, "ticketType": "Economy", "price": 25.0, "available": true},
  {"label": "Economy Ticket 6", "id": 6, "ticketType": "Economy", "price": 25.0, "available": true},
  {"label": "Economy Ticket 7", "id": 7, "ticketType": "Economy", "price": 25.0, "available": true},
  {"label": "Economy Ticket 8", "id": 8, "ticketType": "Economy", "price": 25.0, "available": true},
  {"label": "Economy Ticket 9", "id": 9, "ticketType": "Economy", "price": 25.0, "available": true},
  {"label": "Economy Ticket 10", "id": 10, "ticketType": "Economy", "price": 25.0, "available": true},
  
  // Standard tickets (30 seats)
  {"label": "Standard Ticket 1", "id": 11, "ticketType": "Standard", "price": 45.0, "available": true},
  {"label": "Standard Ticket 2", "id": 12, "ticketType": "Standard", "price": 45.0, "available": true},
  {"label": "Standard Ticket 3", "id": 13, "ticketType": "Standard", "price": 45.0, "available": true},
  {"label": "Standard Ticket 4", "id": 14, "ticketType": "Standard", "price": 45.0, "available": true},
  {"label": "Standard Ticket 5", "id": 15, "ticketType": "Standard", "price": 45.0, "available": true},
  {"label": "Standard Ticket 6", "id": 16, "ticketType": "Standard", "price": 45.0, "available": true},
  {"label": "Standard Ticket 7", "id": 17, "ticketType": "Standard", "price": 45.0, "available": true},
  {"label": "Standard Ticket 8", "id": 18, "ticketType": "Standard", "price": 45.0, "available": true},
  {"label": "Standard Ticket 9", "id": 19, "ticketType": "Standard", "price": 45.0, "available": true},
  {"label": "Standard Ticket 10", "id": 20, "ticketType": "Standard", "price": 45.0, "available": true},
  
  // VIP tickets (20 seats)
  {"label": "VIP Ticket 1", "id": 21, "ticketType": "VIP", "price": 75.0, "available": true},
  {"label": "VIP Ticket 2", "id": 22, "ticketType": "VIP", "price": 75.0, "available": true},
  {"label": "VIP Ticket 3", "id": 23, "ticketType": "VIP", "price": 75.0, "available": true},
  {"label": "VIP Ticket 4", "id": 24, "ticketType": "VIP", "price": 75.0, "available": true},
  {"label": "VIP Ticket 5", "id": 25, "ticketType": "VIP", "price": 75.0, "available": true},
  {"label": "VIP Ticket 6", "id": 26, "ticketType": "VIP", "price": 75.0, "available": true},
  {"label": "VIP Ticket 7", "id": 27, "ticketType": "VIP", "price": 75.0, "available": true},
  {"label": "VIP Ticket 8", "id": 28, "ticketType": "VIP", "price": 75.0, "available": true},
  {"label": "VIP Ticket 9", "id": 29, "ticketType": "VIP", "price": 75.0, "available": true},
  {"label": "VIP Ticket 10", "id": 30, "ticketType": "VIP", "price": 75.0, "available": true}
];

/**
 * Validates seat map JSON structure
 * @param {*} seatMap - The seat map to validate
 * @returns {boolean} - True if valid, throws error if invalid
 */
function validateSeatMap(seatMap) {
  if (!Array.isArray(seatMap)) {
    throw new Error("Seat map must be an array");
  }
  
  for (let i = 0; i < seatMap.length; i++) {
    const seat = seatMap[i];
    if (!seat.id || !seat.label) {
      throw new Error(`Seat at index ${i} must have 'id' and 'label' properties`);
    }
    if (typeof seat.id !== 'number') {
      throw new Error(`Seat at index ${i}: 'id' must be a number`);
    }
    if (typeof seat.label !== 'string') {
      throw new Error(`Seat at index ${i}: 'label' must be a string`);
    }
    if (seat.price !== undefined && typeof seat.price !== 'number') {
      throw new Error(`Seat at index ${i}: 'price' must be a number`);
    }
    if (seat.available !== undefined && typeof seat.available !== 'boolean') {
      throw new Error(`Seat at index ${i}: 'available' must be a boolean`);
    }
  }
  return true;
}

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
      // Handle seat map validation and processing
      let seatMapData = null;
      
      if (data.seat_map) {
        // If seat_map is provided, validate it
        if (typeof data.seat_map === 'string') {
          try {
            seatMapData = JSON.parse(data.seat_map);
          } catch (parseError) {
            throw new Error("Invalid JSON format for seat_map");
          }
        } else if (typeof data.seat_map === 'object') {
          seatMapData = data.seat_map;
        } else {
          throw new Error("seat_map must be a JSON object or valid JSON string");
        }
        
        // Validate the seat map structure
        validateSeatMap(seatMapData);
      }
      // If no seat_map provided, it will remain null (optional)

      const eventData = {
        organization_id: data.organization_id ? parseInt(data.organization_id) : null,
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
      };

      // Only add seat_map if it was provided and validated
      if (seatMapData) {
        eventData.seat_map = seatMapData;
      }

      return await prisma.event.create({
        data: eventData,
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

      // If no seat map exists, return standard ticket types
      if (!event.seat_map || event.seat_map.length === 0) {
        return {
          seats: [],
          hasCustomSeating: false,
          ticketTypes: {
            'Economy': {
              'price': 25.0,
              'totalSeats': 50,
              'availableSeats': 50,
            },
            'Standard': {
              'price': 50.0,
              'totalSeats': 30,
              'availableSeats': 30,
            },
            'VIP': {
              'price': 100.0,
              'totalSeats': 20,
              'availableSeats': 20,
            },
          }
        };
      }

      // Return the custom seat map
      return {
        seats: event.seat_map,
        hasCustomSeating: true
      };
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
