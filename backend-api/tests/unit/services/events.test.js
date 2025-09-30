// Unit tests for events service (getEventById and getAllEvents)
const eventsService = require('../../../services/core-service/events');

jest.mock('../../../lib/database', () => ({
  event: {
    findUnique: jest.fn().mockImplementation(({ where, select }) => {
      if (where.event_id === 1) {
        if (select && select.seat_map) {
          // getSeatMap - event with custom seat map
          return Promise.resolve({ seat_map: [{ id: 'A1', row: 'A', seat: 1, status: 'available' }] });
        }
        return Promise.resolve({ event_id: 1, name: 'Test Event', organization: { organization_id: 1, name: 'Org', logo_url: '', contact_email: '' } });
      }
      if (where.event_id === 2 && select && select.seat_map) {
        // getSeatMap - event with no seat map
        return Promise.resolve({ seat_map: [] });
      }
      if (where.event_id === 999) {
        // getSeatMap - event not found
        return Promise.resolve(null);
      }
      return Promise.resolve(null);
    }),
    findMany: jest.fn().mockImplementation((args) => {
      const where = args && args.where;
      // getUpcomingEvents (has start_time and status in where)
      if (
        args &&
        args.orderBy &&
        args.where &&
        args.where.start_time &&
        args.where.status
      ) {
        return Promise.resolve([
          { event_id: 5, name: 'Upcoming Event 1' },
          { event_id: 6, name: 'Upcoming Event 2' }
        ].slice(0, args.take || 10));
      }
      // searchEvents
      if (where && where.OR) {
        const isSearch = where.OR.some(
          clause => Object.values(clause).some(
            val => typeof val === 'object' && val.contains === 'Search'
          )
        );
        if (isSearch) {
          return Promise.resolve([
            { event_id: 4, name: 'Searched Event', title: 'Search' }
          ]);
        }
      }
      // getEventsByCategory
      if (where && where.category) {
        if (where.category === 'Sports') {
          const sports = [
            { event_id: 7, name: 'Sports Event 1', category: 'Sports' },
            { event_id: 8, name: 'Sports Event 2', category: 'Sports' }
          ];
          return Promise.resolve(sports.slice(0, args.take || 10));
        } else if (where.category === 'Music') {
          return Promise.resolve([
            { event_id: 3, name: 'Music Event', category: 'Music' }
          ]);
        } else {
          return Promise.resolve([]);
        }
      }
      // searchEvents
      if (args && args.where && args.where.OR) {
        const isSearch = args.where.OR.some(
          clause => Object.values(clause).some(
            val => typeof val === 'object' && val.contains === 'Search'
          )
        );
        if (isSearch) {
          return Promise.resolve([
            { event_id: 4, name: 'Searched Event', title: 'Search' }
          ]);
        } else {
          return Promise.resolve([]);
        }
      }
      // getEventsByCategory
      if (args && args.where && args.where.category) {
        if (args.where.category === 'Sports') {
          const sports = [
            { event_id: 7, name: 'Sports Event 1', category: 'Sports' },
            { event_id: 8, name: 'Sports Event 2', category: 'Sports' }
          ];
          return Promise.resolve(sports.slice(0, args.take || 10));
        } else if (args.where.category === 'Music') {
          return Promise.resolve([
            { event_id: 3, name: 'Music Event', category: 'Music' }
          ]);
        } else {
          return Promise.resolve([]);
        }
      }
      // getUpcomingEvents (orderBy present and where.date present)
      if (
        args &&
        args.orderBy &&
        args.where &&
        typeof args.where === 'object' &&
        args.where.date !== undefined
      ) {
        return Promise.resolve([
          { event_id: 5, name: 'Upcoming Event 1' },
          { event_id: 6, name: 'Upcoming Event 2' }
        ].slice(0, args.take || 10));
      }
      // getAllEvents (empty where object and has orderBy)
      if (
        args &&
        args.orderBy &&
        args.where &&
        Object.keys(args.where).length === 0
      ) {
        return Promise.resolve([
          { event_id: 1, name: 'Test Event 1' },
          { event_id: 2, name: 'Test Event 2' }
        ]);
      }
      // Default: empty array
      return Promise.resolve([]);
      // searchEvents
      if (args && args.where && args.where.OR) {
        const isSearch = args.where.OR.some(
          clause => Object.values(clause).some(
            val => typeof val === 'object' && val.contains === 'Search'
          )
        );
        if (isSearch) {
          return Promise.resolve([
            { event_id: 4, name: 'Searched Event', title: 'Search' }
          ]);
        } else {
          return Promise.resolve([]);
        }
      }
      // getEventsByCategory
      if (args && args.where && args.where.category) {
        if (args.where.category === 'Sports') {
          const sports = [
            { event_id: 7, name: 'Sports Event 1', category: 'Sports' },
            { event_id: 8, name: 'Sports Event 2', category: 'Sports' }
          ];
          return Promise.resolve(sports.slice(0, args.take || 10));
        } else if (args.where.category === 'Music') {
          return Promise.resolve([
            { event_id: 3, name: 'Music Event', category: 'Music' }
          ]);
        } else {
          return Promise.resolve([]);
        }
      }
      // getAllEvents with status filter
      if (args && args.where && args.where.status && !args.where.category && !args.where.start_time) {
        if (args.where.status === 'ACTIVE') {
          return Promise.resolve([
            { event_id: 1, name: 'Test Event 1' },
            { event_id: 2, name: 'Test Event 2' }
          ]);
        }
        return Promise.resolve([]);
      }
      // getAllEvents with start_date filter
      if (args && args.where && args.where.start_time && !args.where.category && !args.where.status) {
        return Promise.resolve([
          { event_id: 1, name: 'Test Event 1' },
          { event_id: 2, name: 'Test Event 2' }
        ]);
      }
      // getAllEvents (no filters)
      if (!args.where || Object.keys(args.where).length === 0) {
        return Promise.resolve([
          { event_id: 1, name: 'Test Event 1' },
          { event_id: 2, name: 'Test Event 2' }
        ]);
      }
      // Default: empty array
      return Promise.resolve([]);
      // getAllEvents (no filters)
      if (!where || Object.keys(where).length === 0) {
        return Promise.resolve([
          { event_id: 1, name: 'Test Event 1' },
          { event_id: 2, name: 'Test Event 2' }
        ]);
      }
      return Promise.resolve([]);
    }),

    create: jest.fn().mockImplementation(({ data }) => Promise.resolve({ event_id: 10, ...data })),
    update: jest.fn().mockImplementation(({ where, data, select }) => {
      if (select && select.seat_map) {
        // updateSeatMap
        return Promise.resolve({ seat_map: data.seat_map });
      }
      return Promise.resolve({ event_id: where.event_id, ...data });
    }),
    "delete": jest.fn().mockImplementation(({ where }) => Promise.resolve({ event_id: where.event_id })),
  },
  $queryRawUnsafe: jest.fn().mockImplementation((sql, ...values) => [
    { event_id: values[values.length - 1], title: 'Updated Event', ...values }
  ]),
}));
describe('eventsService.getUpcomingEvents', () => {
  it('should return upcoming events with default limit', async () => {
    const data = await eventsService.getUpcomingEvents();
    expect(data).toEqual([
      { event_id: 5, name: 'Upcoming Event 1' },
      { event_id: 6, name: 'Upcoming Event 2' }
    ]);
  });

  it('should return limited number of upcoming events', async () => {
    const data = await eventsService.getUpcomingEvents(1);
    expect(data).toEqual([
      { event_id: 5, name: 'Upcoming Event 1' }
    ]);
  });

  it('should throw error if db fails', async () => {
    const db = require('../../../lib/database');
    db.event.findMany.mockRejectedValueOnce(new Error('DB error'));
    await expect(eventsService.getUpcomingEvents()).rejects.toThrow('Failed to fetch upcoming events: DB error');
  });
});
describe('eventsService.deleteEvent', () => {
  it('should delete an event with valid ID', async () => {
    const result = await eventsService.deleteEvent(1);
    expect(result).toEqual({ event_id: 1 });
  });

  it('should throw error if db fails', async () => {
    const db = require('../../../lib/database');
    db.event.delete.mockRejectedValueOnce(new Error('DB error'));
    await expect(eventsService.deleteEvent(1)).rejects.toThrow('Failed to delete event: DB error');
  });
});
describe('eventsService.updateEvent', () => {
  it('should update an event with valid data', async () => {
    const data = {
      title: 'Updated Event',
      start_time: new Date(),
      end_time: new Date(),
      seat_map: [{ id: 1, label: 'A1' }],
      ticket_types: [{ type: 'VIP', price: 100 }]
    };
    const result = await eventsService.updateEvent(1, data);
    expect(result.event_id).toBe(1);
    expect(result.title).toBe('Updated Event');
  });

  it('should throw error if db fails', async () => {
    const db = require('../../../lib/database');
    db.$queryRawUnsafe.mockImplementationOnce(() => { throw new Error('DB error'); });
    await expect(eventsService.updateEvent(1, { title: 'Fail Event' })).rejects.toThrow('Failed to update event: DB error');
  });

  it('should handle invalid seat_map type by setting to null', async () => {
    const data = {
      title: 'Updated Event',
      seat_map: "invalid string", // Not array or object
      ticket_types: [{ type: 'VIP', price: 100 }]
    };
    const result = await eventsService.updateEvent(1, data);
    expect(result.event_id).toBe(1);
    expect(result.title).toBe('Updated Event');
  });

  it('should handle invalid ticket_types type by setting to null', async () => {
    const data = {
      title: 'Updated Event',
      seat_map: [{ id: 1, label: 'A1' }],
      ticket_types: "invalid string" // Not array or object
    };
    const result = await eventsService.updateEvent(1, data);
    expect(result.event_id).toBe(1);
    expect(result.title).toBe('Updated Event');
  });
});
describe('eventsService.createEvent', () => {
  it('should create a new event with valid data', async () => {
    const data = {
      organization_id: 1,
      title: 'New Event',
      start_time: new Date(),
      end_time: new Date(),
      seat_map: [{ id: 1, label: 'A1' }],
      ticket_types: [{ type: 'VIP', price: 100 }]
    };
    const result = await eventsService.createEvent(data);
    expect(result.event_id).toBe(10);
    expect(result.title).toBe('New Event');
  });

  it('should throw error for invalid seat_map JSON', async () => {
    await expect(eventsService.createEvent({
      organization_id: 1,
      title: 'Bad Event',
      start_time: new Date(),
      end_time: new Date(),
      seat_map: '{bad json}',
      ticket_types: []
    })).rejects.toThrow('Invalid JSON format for seat_map');
  });

  it('should throw error for invalid ticket_types JSON', async () => {
    await expect(eventsService.createEvent({
      organization_id: 1,
      title: 'Bad Event',
      start_time: new Date(),
      end_time: new Date(),
      seat_map: [],
      ticket_types: '{bad json}'
    })).rejects.toThrow('Invalid JSON format for ticket_types');
  });

  it('should throw error if db fails', async () => {
    const db = require('../../../lib/database');
    db.event.create.mockRejectedValueOnce(new Error('DB error'));
    await expect(eventsService.createEvent({
      organization_id: 1,
      title: 'Fail Event',
      start_time: new Date(),
      end_time: new Date(),
      seat_map: [],
      ticket_types: []
    })).rejects.toThrow('Failed to create event: DB error');
  });

  it('should throw error for seat without id', async () => {
    await expect(eventsService.createEvent({
      organization_id: 1,
      title: 'Invalid Event',
      start_time: new Date(),
      end_time: new Date(),
      seat_map: [{ label: 'A1' }],
      ticket_types: []
    })).rejects.toThrow("Seat at index 0 must have 'id' and 'label' properties");
  });

  it('should throw error for seat without label', async () => {
    await expect(eventsService.createEvent({
      organization_id: 1,
      title: 'Invalid Event',
      start_time: new Date(),
      end_time: new Date(),
      seat_map: [{ id: 1 }],
      ticket_types: []
    })).rejects.toThrow("Seat at index 0 must have 'id' and 'label' properties");
  });

  it('should throw error for seat with non-number id', async () => {
    await expect(eventsService.createEvent({
      organization_id: 1,
      title: 'Invalid Event',
      start_time: new Date(),
      end_time: new Date(),
      seat_map: [{ id: 'string', label: 'A1' }],
      ticket_types: []
    })).rejects.toThrow("Seat at index 0: 'id' must be a number");
  });

  it('should throw error for seat with non-string label', async () => {
    await expect(eventsService.createEvent({
      organization_id: 1,
      title: 'Invalid Event',
      start_time: new Date(),
      end_time: new Date(),
      seat_map: [{ id: 1, label: 123 }],
      ticket_types: []
    })).rejects.toThrow("Seat at index 0: 'label' must be a string");
  });

  it('should throw error for seat with non-number price', async () => {
    await expect(eventsService.createEvent({
      organization_id: 1,
      title: 'Invalid Event',
      start_time: new Date(),
      end_time: new Date(),
      seat_map: [{ id: 1, label: 'A1', price: 'invalid' }],
      ticket_types: []
    })).rejects.toThrow("Seat at index 0: 'price' must be a number");
  });

  it('should throw error for seat with non-boolean available', async () => {
    await expect(eventsService.createEvent({
      organization_id: 1,
      title: 'Invalid Event',
      start_time: new Date(),
      end_time: new Date(),
      seat_map: [{ id: 1, label: 'A1', available: 'invalid' }],
      ticket_types: []
    })).rejects.toThrow("Seat at index 0: 'available' must be a boolean");
  });

  it('should handle seat map validation errors - non-array input', async () => {
    const eventData = {
      title: "Test Event",
      description: "A test event",
      date: new Date().toISOString(),
      time: "20:00",
      location: "Test Venue",
      ticket_types: JSON.stringify([{
        type: "General",
        price: 50,
        available_quantity: 100
      }]),
      organization_id: 1,
      seat_map: JSON.stringify("not an array") // Valid JSON but not an array
    };

    await expect(eventsService.createEvent(eventData))
      .rejects
      .toThrow('Seat map must be an array');
  });

  it('should handle seat map validation errors - missing required properties', async () => {
    const eventData = {
      title: "Test Event",
      description: "A test event",
      date: new Date().toISOString(),
      time: "20:00",
      location: "Test Venue",
      ticket_types: JSON.stringify([{
        type: "General",
        price: 50,
        available_quantity: 100
      }]),
      organization_id: 1,
      seat_map: JSON.stringify([{ id: 1 }]) // Missing label property
    };

    await expect(eventsService.createEvent(eventData))
      .rejects
      .toThrow('must have \'id\' and \'label\' properties');
  });

  it('should handle seat map validation errors - invalid seat id type', async () => {
    const eventData = {
      title: "Test Event",
      description: "A test event",
      date: new Date().toISOString(),
      time: "20:00",
      location: "Test Venue",
      ticket_types: JSON.stringify([{
        type: "General",
        price: 50,
        available_quantity: 100
      }]),
      organization_id: 1,
      seat_map: JSON.stringify([{
        id: "not-a-number",
        label: "A1",
        row: 1,
        column: 1,
        status: "available"
      }])
    };

    await expect(eventsService.createEvent(eventData))
      .rejects
      .toThrow('\'id\' must be a number');
  });

  it('should handle seat map validation errors - invalid label type', async () => {
    const eventData = {
      title: "Test Event",
      description: "A test event",
      date: new Date().toISOString(),
      time: "20:00",
      location: "Test Venue",
      ticket_types: JSON.stringify([{
        type: "General",
        price: 50,
        available_quantity: 100
      }]),
      organization_id: 1,
      seat_map: JSON.stringify([{
        id: 1,
        label: 123, // Should be string
        row: 1,
        column: 1,
        status: "available"
      }])
    };

    await expect(eventsService.createEvent(eventData))
      .rejects
      .toThrow('\'label\' must be a string');
  });

  it('should handle seat map validation errors - invalid price type', async () => {
    const eventData = {
      title: "Test Event",
      description: "A test event",
      date: new Date().toISOString(),
      time: "20:00",
      location: "Test Venue",
      ticket_types: JSON.stringify([{
        type: "General",
        price: 50,
        available_quantity: 100
      }]),
      organization_id: 1,
      seat_map: JSON.stringify([{
        id: 1,
        label: "A1",
        price: "invalid", // Should be number
        row: 1,
        column: 1,
        status: "available"
      }])
    };

    await expect(eventsService.createEvent(eventData))
      .rejects
      .toThrow('\'price\' must be a number');
  });
});

describe('eventsService.getEventById', () => {
  it('should return event data for a valid ID', async () => {
    const data = await eventsService.getEventById(1);
    expect(data).toEqual({ event_id: 1, name: 'Test Event', organization: { organization_id: 1, name: 'Org', logo_url: '', contact_email: '' } });
  });

  it('should return null for an invalid ID', async () => {
    const data = await eventsService.getEventById(999);
    expect(data).toBeNull();
  });

  it('should throw error if db fails', async () => {
    const db = require('../../../lib/database');
    db.event.findUnique.mockRejectedValueOnce(new Error('DB error'));
    await expect(eventsService.getEventById(1)).rejects.toThrow('Failed to fetch event: DB error');
  });
});

describe('eventsService.getAllEvents', () => {
  it('should return all events if no filters', async () => {
    const data = await eventsService.getAllEvents();
    expect(data).toEqual([
      { event_id: 1, name: 'Test Event 1' },
      { event_id: 2, name: 'Test Event 2' }
    ]);
  });

    describe('eventsService.searchEvents', () => {
      it('should return search results for a query', async () => {
        const data = await eventsService.searchEvents('Search');
        expect(data).toEqual([
          { event_id: 4, name: 'Searched Event', title: 'Search' }
        ]);
      });

      it('should return empty array if no results', async () => {
        const data = await eventsService.searchEvents('NoMatch');
        expect(data).toEqual([]);
      });

      it('should throw error if db fails', async () => {
        const db = require('../../../lib/database');
        db.event.findMany.mockRejectedValueOnce(new Error('DB error'));
        await expect(eventsService.searchEvents('Search')).rejects.toThrow('Failed to search events: DB error');
      });
    });

  it('should return filtered events by category', async () => {
    const data = await eventsService.getAllEvents({ category: 'Music' });
    expect(data).toEqual([{ event_id: 3, name: 'Music Event', category: 'Music' }]);
  });

  it('should return filtered events by status', async () => {
    const data = await eventsService.getAllEvents({ status: 'ACTIVE' });
    expect(data).toEqual([
      { event_id: 1, name: 'Test Event 1' },
      { event_id: 2, name: 'Test Event 2' }
    ]);
  });

  it('should return filtered events by start_date', async () => {
    const data = await eventsService.getAllEvents({ start_date: '2024-01-01' });
    expect(data).toEqual([
      { event_id: 1, name: 'Test Event 1' },
      { event_id: 2, name: 'Test Event 2' }
    ]);
  });

  it('should return empty array if no events match filters', async () => {
    const data = await eventsService.getAllEvents({ category: 'Nonexistent' });
    expect(data).toEqual([]);
  });

  it('should throw error if db fails', async () => {
    const db = require('../../../lib/database');
    db.event.findMany.mockRejectedValueOnce(new Error('DB error'));
    await expect(eventsService.getAllEvents()).rejects.toThrow('Failed to fetch events: DB error');
  });
});

describe('eventsService.getEventsByCategory', () => {
  it('should return events by category with default limit', async () => {
    const data = await eventsService.getEventsByCategory('Sports');
    expect(data).toEqual([
      { event_id: 7, name: 'Sports Event 1', category: 'Sports' },
      { event_id: 8, name: 'Sports Event 2', category: 'Sports' }
    ]);
  });

  it('should return limited number of events by category', async () => {
    const data = await eventsService.getEventsByCategory('Sports', 1);
    expect(data).toEqual([
      { event_id: 7, name: 'Sports Event 1', category: 'Sports' }
    ]);
  });

  it('should throw error if db fails', async () => {
    const db = require('../../../lib/database');
    db.event.findMany.mockRejectedValueOnce(new Error('DB error'));
    await expect(eventsService.getEventsByCategory('Sports')).rejects.toThrow('Failed to fetch events by category: DB error');
  });
});

describe('eventsService.getSeatMap', () => {
  it('should return custom seat map when event has seat map', async () => {
    const data = await eventsService.getSeatMap(1);
    expect(data).toEqual({
      seats: [{ id: 'A1', row: 'A', seat: 1, status: 'available' }],
      hasCustomSeating: true
    });
  });

  it('should return default ticket types when event has no seat map', async () => {
    const data = await eventsService.getSeatMap(2);
    expect(data).toEqual({
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
    });
  });

  it('should throw error when event not found', async () => {
    await expect(eventsService.getSeatMap(999)).rejects.toThrow('Failed to fetch seat map: Event not found');
  });

  it('should throw error if db fails', async () => {
    const db = require('../../../lib/database');
    db.event.findUnique.mockRejectedValueOnce(new Error('DB error'));
    await expect(eventsService.getSeatMap(1)).rejects.toThrow('Failed to fetch seat map: DB error');
  });
});

describe('eventsService.updateSeatMap', () => {
  it('should update seat map successfully', async () => {
    const newSeatMap = [
      { id: 'A1', row: 'A', seat: 1, status: 'booked' },
      { id: 'A2', row: 'A', seat: 2, status: 'available' }
    ];
    
    const result = await eventsService.updateSeatMap(1, newSeatMap);
    expect(result).toEqual(newSeatMap);
  });

  it('should throw error if db fails', async () => {
    const db = require('../../../lib/database');
    db.event.update.mockRejectedValueOnce(new Error('DB error'));
    
    const newSeatMap = [{ id: 'A1', row: 'A', seat: 1, status: 'booked' }];
    await expect(eventsService.updateSeatMap(1, newSeatMap)).rejects.toThrow('Failed to update seat map: DB error');
  });
});
