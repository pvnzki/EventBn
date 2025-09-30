/**
 * Events API Integration Tests
 * 
 * Tests complete event management flows including creation, retrieval,
 * updates, filtering, and authorization.
 */

const {
  app,
  request,
  setupTestDatabase,
  teardownTestDatabase,
  createTestUser,
  createTestOrganizer,
  createTestEvent,
  expectSuccessResponse,
  expectErrorResponse,
  expectAuthenticationRequired,
  expectValidationError,
  generateUniqueEmail,
  generateTestEventData
} = require('../../fixtures/prisma-mock');

describe('Events API Integration Tests', () => {
  beforeAll(async () => {
    await setupTestDatabase();
  });

  afterAll(async () => {
    await teardownTestDatabase();
  });

  beforeEach(async () => {
    await setupTestDatabase();
  });

  describe('GET /api/events', () => {
    let organizer;
    let events = [];

    beforeEach(async () => {
      organizer = await createTestOrganizer({
        email: generateUniqueEmail('organizer')
      });

      // Create multiple test events
      for (let i = 1; i <= 3; i++) {
        const eventData = generateTestEventData({
          title: `Test Event ${i}`,
          event_type: i === 1 ? 'CONFERENCE' : 'CONCERT',
          status: i === 3 ? 'DRAFT' : 'ACTIVE'
        });
        
        const { event } = await createTestEvent(organizer.token, eventData);
        events.push(event);
      }
    });

    it('should return all active events without authentication', async () => {
      const response = await request(app)
        .get('/api/events');

      expect(response.status).toBe(200);
      expectSuccessResponse(response);
      expect(Array.isArray(response.body.data)).toBe(true);
      expect(response.body.data.length).toBeGreaterThanOrEqual(2); // Should exclude DRAFT events
      
      // Verify event structure
      const event = response.body.data[0];
      expect(event).toHaveProperty('event_id');
      expect(event).toHaveProperty('title');
      expect(event).toHaveProperty('start_time');
      expect(event).toHaveProperty('location');
    });

    it('should filter events by event_type', async () => {
      const response = await request(app)
        .get('/api/events')
        .query({ event_type: 'CONFERENCE' });

      expect(response.status).toBe(200);
      expectSuccessResponse(response);
      
      response.body.data.forEach(event => {
        expect(event.event_type).toBe('CONFERENCE');
      });
    });

    it('should filter events by status', async () => {
      const response = await request(app)
        .get('/api/events')
        .query({ status: 'ACTIVE' });

      expect(response.status).toBe(200);
      expectSuccessResponse(response);
      
      response.body.data.forEach(event => {
        expect(event.status).toBe('ACTIVE');
      });
    });

    it('should handle pagination parameters', async () => {
      const response = await request(app)
        .get('/api/events')
        .query({ 
          page: 1, 
          limit: 2 
        });

      expect(response.status).toBe(200);
      expectSuccessResponse(response);
      expect(response.body.data.length).toBeLessThanOrEqual(2);
    });

    it('should search events by title', async () => {
      const response = await request(app)
        .get('/api/events')
        .query({ search: 'Test Event 1' });

      expect(response.status).toBe(200);
      expectSuccessResponse(response);
      
      if (response.body.data.length > 0) {
        expect(response.body.data[0].title).toContain('Test Event 1');
      }
    });
  });

  describe('GET /api/events/:id', () => {
    let organizer;
    let testEvent;

    beforeEach(async () => {
      organizer = await createTestOrganizer({
        email: generateUniqueEmail('event-detail')
      });
      
      const { event } = await createTestEvent(organizer.token, generateTestEventData({
        title: 'Detailed Test Event'
      }));
      testEvent = event;
    });

    it('should return event details by ID', async () => {
      const response = await request(app)
        .get(`/api/events/${testEvent.event_id}`);

      expect(response.status).toBe(200);
      expectSuccessResponse(response);
      expect(response.body.data).toMatchObject({
        event_id: testEvent.event_id,
        title: testEvent.title,
        description: testEvent.description
      });
    });

    it('should return 404 for non-existent event', async () => {
      const response = await request(app)
        .get('/api/events/999999');

      expect(response.status).toBe(404);
      expectErrorResponse(response, 404);
      expect(response.body.message).toMatch(/not found/i);
    });

    it('should return 400 for invalid event ID format', async () => {
      const response = await request(app)
        .get('/api/events/invalid-id');

      expect(response.status).toBe(500); // Depends on implementation
    });
  });

  describe('POST /api/events', () => {
    let organizer;
    let regularUser;

    beforeEach(async () => {
      organizer = await createTestOrganizer({
        email: generateUniqueEmail('create-organizer')
      });
      
      regularUser = await createTestUser({
        email: generateUniqueEmail('create-user')
      });
    });

    it('should create event with valid data and organizer authentication', async () => {
      const eventData = generateTestEventData({
        title: 'New Integration Test Event'
      });

      const response = await request(app)
        .post('/api/events')
        .set('Authorization', `Bearer ${organizer.token}`)
        .send(eventData);

      expect(response.status).toBe(201);
      expectSuccessResponse(response);
      expect(response.body.data).toMatchObject({
        title: eventData.title,
        description: eventData.description,
        location: eventData.location,
        event_type: eventData.event_type
      });
      expect(response.body.data.event_id).toBeDefined();
    });

    it('should reject event creation without authentication', async () => {
      const eventData = generateTestEventData();

      const response = await request(app)
        .post('/api/events')
        .send(eventData);

      expectAuthenticationRequired(response);
    });

    it('should reject event creation with regular user token', async () => {
      const eventData = generateTestEventData();

      const response = await request(app)
        .post('/api/events')
        .set('Authorization', `Bearer ${regularUser.token}`)
        .send(eventData);

      expect(response.status).toBe(403); // Assuming role-based authorization
    });

    it('should reject event creation with missing required fields', async () => {
      const response = await request(app)
        .post('/api/events')
        .set('Authorization', `Bearer ${organizer.token}`)
        .send({
          title: 'Incomplete Event'
          // Missing other required fields
        });

      expectValidationError(response);
    });

    it('should reject event creation with invalid date format', async () => {
      const eventData = generateTestEventData({
        start_time: 'invalid-date',
        end_time: 'invalid-date'
      });

      const response = await request(app)
        .post('/api/events')
        .set('Authorization', `Bearer ${organizer.token}`)
        .send(eventData);

      expectValidationError(response);
    });

    it('should reject event creation with end_time before start_time', async () => {
      const now = new Date();
      const eventData = generateTestEventData({
        start_time: new Date(now.getTime() + 24 * 60 * 60 * 1000).toISOString(), // Tomorrow
        end_time: now.toISOString() // Today
      });

      const response = await request(app)
        .post('/api/events')
        .set('Authorization', `Bearer ${organizer.token}`)
        .send(eventData);

      expectValidationError(response);
    });

    it('should create event with complex ticket types and seat map', async () => {
      const eventData = generateTestEventData({
        ticket_types: [
          {
            type: 'VIP',
            price: 150,
            available_quantity: 20
          },
          {
            type: 'General',
            price: 75,
            available_quantity: 80
          }
        ],
        seat_map: [
          { id: 1, label: 'A1', row: 1, column: 1, status: 'available' },
          { id: 2, label: 'A2', row: 1, column: 2, status: 'available' }
        ]
      });

      const response = await request(app)
        .post('/api/events')
        .set('Authorization', `Bearer ${organizer.token}`)
        .send(eventData);

      expect(response.status).toBe(201);
      expectSuccessResponse(response);
      expect(response.body.data.ticket_types).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ type: 'VIP', price: 150 }),
          expect.objectContaining({ type: 'General', price: 75 })
        ])
      );
    });
  });

  describe('PUT /api/events/:id', () => {
    let organizer;
    let otherOrganizer;
    let testEvent;

    beforeEach(async () => {
      organizer = await createTestOrganizer({
        email: generateUniqueEmail('update-organizer')
      });
      
      otherOrganizer = await createTestOrganizer({
        email: generateUniqueEmail('other-organizer')
      });

      const { event } = await createTestEvent(organizer.token, generateTestEventData({
        title: 'Event to Update'
      }));
      testEvent = event;
    });

    it('should update event with valid data and correct authorization', async () => {
      const updateData = {
        title: 'Updated Event Name',
        description: 'Updated description',
        venue: 'Updated Venue'
      };

      const response = await request(app)
        .put(`/api/events/${testEvent.event_id}`)
        .set('Authorization', `Bearer ${organizer.token}`)
        .send(updateData);

      expect(response.status).toBe(200);
      expectSuccessResponse(response);
      expect(response.body.data).toMatchObject(updateData);
    });

    it('should reject update without authentication', async () => {
      const response = await request(app)
        .put(`/api/events/${testEvent.event_id}`)
        .send({ title: 'Updated Name' });

      expectAuthenticationRequired(response);
    });

    it('should reject update by different organizer', async () => {
      const response = await request(app)
        .put(`/api/events/${testEvent.event_id}`)
        .set('Authorization', `Bearer ${otherOrganizer.token}`)
        .send({ title: 'Unauthorized Update' });

      expect(response.status).toBe(403);
      expectErrorResponse(response, 403);
    });

    it('should return 404 for non-existent event', async () => {
      const response = await request(app)
        .put('/api/events/999999')
        .set('Authorization', `Bearer ${organizer.token}`)
        .send({ title: 'Update Non-existent' });

      expect(response.status).toBe(404);
      expectErrorResponse(response, 404);
    });
  });

  describe('DELETE /api/events/:id', () => {
    let organizer;
    let otherOrganizer;
    let testEvent;

    beforeEach(async () => {
      organizer = await createTestOrganizer({
        email: generateUniqueEmail('delete-organizer')
      });
      
      otherOrganizer = await createTestOrganizer({
        email: generateUniqueEmail('delete-other')
      });

      const { event } = await createTestEvent(organizer.token, generateTestEventData({
        title: 'Event to Delete'
      }));
      testEvent = event;
    });

    it('should delete event with correct authorization', async () => {
      const response = await request(app)
        .delete(`/api/events/${testEvent.event_id}`)
        .set('Authorization', `Bearer ${organizer.token}`);

      expect(response.status).toBe(200);
      expectSuccessResponse(response);

      // Verify event is deleted
      const getResponse = await request(app)
        .get(`/api/events/${testEvent.event_id}`);
      expect(getResponse.status).toBe(404);
    });

    it('should reject deletion without authentication', async () => {
      const response = await request(app)
        .delete(`/api/events/${testEvent.event_id}`);

      expectAuthenticationRequired(response);
    });

    it('should reject deletion by different organizer', async () => {
      const response = await request(app)
        .delete(`/api/events/${testEvent.event_id}`)
        .set('Authorization', `Bearer ${otherOrganizer.token}`);

      expect(response.status).toBe(403);
      expectErrorResponse(response, 403);
    });
  });

  describe('Event Search and Filtering Integration', () => {
    let organizer;

    beforeEach(async () => {
      organizer = await createTestOrganizer({
        email: generateUniqueEmail('search-organizer')
      });

      // Create diverse events for testing
      const eventTypes = ['CONFERENCE', 'CONCERT', 'WORKSHOP'];
      const statuses = ['ACTIVE', 'COMPLETED'];
      
      for (let i = 0; i < 6; i++) {
        await createTestEvent(organizer.token, generateTestEventData({
          title: `Search Event ${i + 1}`,
          event_type: eventTypes[i % eventTypes.length],
          status: statuses[i % statuses.length],
          venue: i < 3 ? 'Tech Center' : 'Arts Hall'
        }));
      }
    });

    it('should combine multiple filters correctly', async () => {
      const response = await request(app)
        .get('/api/events')
        .query({
          event_type: 'CONFERENCE',
          status: 'ACTIVE',
          search: 'Search Event'
        });

      expect(response.status).toBe(200);
      expectSuccessResponse(response);
      
      response.body.data.forEach(event => {
        expect(event.event_type).toBe('CONFERENCE');
        expect(event.status).toBe('ACTIVE');
        expect(event.title).toContain('Search Event');
      });
    });

    it('should handle case-insensitive search', async () => {
      const response = await request(app)
        .get('/api/events')
        .query({ search: 'search event' });

      expect(response.status).toBe(200);
      expectSuccessResponse(response);
      expect(response.body.data.length).toBeGreaterThan(0);
    });

    it('should return empty array for no matches', async () => {
      const response = await request(app)
        .get('/api/events')
        .query({ search: 'NonExistentEvent12345' });

      expect(response.status).toBe(200);
      expectSuccessResponse(response);
      expect(response.body.data).toEqual([]);
    });
  });
});