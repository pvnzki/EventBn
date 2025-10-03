/**
 * Cross-Service Integration Tests
 * 
 * Tests interactions between different services, particularly
 * ticket booking flows that involve events, users, and payments.
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
} = require('./setup');

describe('Cross-Service Integration Tests', () => {
  beforeAll(async () => {
    await setupTestDatabase();
  });

  afterAll(async () => {
    await teardownTestDatabase();
  });

  beforeEach(async () => {
    await setupTestDatabase();
  });

  describe('Ticket Booking Flow', () => {
    let organizer;
    let attendee;
    let testEvent;

    beforeEach(async () => {
      organizer = await createTestOrganizer({
        email: generateUniqueEmail('ticket-organizer')
      });
      
      attendee = await createTestUser({
        email: generateUniqueEmail('ticket-attendee')
      });

      const { event } = await createTestEvent(organizer.token, generateTestEventData({
        name: 'Ticket Test Event',
        max_attendees: 100,
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
        ]
      }));
      testEvent = event;
    });

    it('should complete full ticket booking flow', async () => {
      // Step 1: View available events
      const eventsResponse = await request(app)
        .get('/api/events');
      
      expect(eventsResponse.status).toBe(200);
      const availableEvent = eventsResponse.body.data.find(e => e.event_id === testEvent.event_id);
      expect(availableEvent).toBeDefined();

      // Step 2: Get event details
      const eventDetailsResponse = await request(app)
        .get(`/api/events/${testEvent.event_id}`);
      
      expect(eventDetailsResponse.status).toBe(200);
      expect(eventDetailsResponse.body.data.ticket_types).toBeDefined();

      // Step 3: Book tickets
      const bookingData = {
        event_id: testEvent.event_id,
        ticket_type: 'General',
        quantity: 2,
        attendee_details: {
          name: attendee.user.name,
          email: attendee.user.email,
          phone: attendee.user.phone
        }
      };

      const bookingResponse = await request(app)
        .post('/api/tickets/book')
        .set('Authorization', `Bearer ${attendee.token}`)
        .send(bookingData);

      expect(bookingResponse.status).toBe(201);
      expectSuccessResponse(bookingResponse);
      expect(bookingResponse.body.data).toMatchObject({
        event_id: testEvent.event_id,
        ticket_type: 'General',
        quantity: 2,
        status: 'CONFIRMED'
      });

      const bookingId = bookingResponse.body.data.booking_id;

      // Step 4: Verify booking in user's tickets
      const userTicketsResponse = await request(app)
        .get('/api/tickets/my-tickets')
        .set('Authorization', `Bearer ${attendee.token}`);

      expect(userTicketsResponse.status).toBe(200);
      expectSuccessResponse(userTicketsResponse);
      
      const userBooking = userTicketsResponse.body.data.find(t => t.booking_id === bookingId);
      expect(userBooking).toBeDefined();

      // Step 5: Get booking details
      const bookingDetailsResponse = await request(app)
        .get(`/api/tickets/${bookingId}`)
        .set('Authorization', `Bearer ${attendee.token}`);

      expect(bookingDetailsResponse.status).toBe(200);
      expect(bookingDetailsResponse.body.data.booking_id).toBe(bookingId);
    });

    it('should prevent overbooking when tickets are limited', async () => {
      // Book all available VIP tickets
      const vipBooking = await request(app)
        .post('/api/tickets/book')
        .set('Authorization', `Bearer ${attendee.token}`)
        .send({
          event_id: testEvent.event_id,
          ticket_type: 'VIP',
          quantity: 20 // All available VIP tickets
        });

      expect(vipBooking.status).toBe(201);

      // Try to book one more VIP ticket (should fail)
      const overbookingResponse = await request(app)
        .post('/api/tickets/book')
        .set('Authorization', `Bearer ${attendee.token}`)
        .send({
          event_id: testEvent.event_id,
          ticket_type: 'VIP',
          quantity: 1
        });

      expectValidationError(overbookingResponse);
      expect(overbookingResponse.body.message).toMatch(/not.*available|sold.*out/i);
    });

    it('should handle ticket cancellation flow', async () => {
      // Book tickets
      const bookingResponse = await request(app)
        .post('/api/tickets/book')
        .set('Authorization', `Bearer ${attendee.token}`)
        .send({
          event_id: testEvent.event_id,
          ticket_type: 'General',
          quantity: 1
        });

      expect(bookingResponse.status).toBe(201);
      const bookingId = bookingResponse.body.data.booking_id;

      // Cancel booking
      const cancellationResponse = await request(app)
        .put(`/api/tickets/${bookingId}/cancel`)
        .set('Authorization', `Bearer ${attendee.token}`);

      expect(cancellationResponse.status).toBe(200);
      expectSuccessResponse(cancellationResponse);
      expect(cancellationResponse.body.data.status).toBe('CANCELLED');

      // Verify tickets are available again
      const eventDetailsResponse = await request(app)
        .get(`/api/events/${testEvent.event_id}`);
      
      const generalTickets = eventDetailsResponse.body.data.ticket_types.find(t => t.type === 'General');
      expect(generalTickets.available_quantity).toBe(80); // Should be restored
    });
  });

  describe('Event Analytics Integration', () => {
    let organizer;
    let attendees = [];
    let testEvent;

    beforeEach(async () => {
      organizer = await createTestOrganizer({
        email: generateUniqueEmail('analytics-organizer')
      });

      // Create multiple attendees
      for (let i = 1; i <= 3; i++) {
        const attendee = await createTestUser({
          email: generateUniqueEmail(`analytics-attendee${i}`)
        });
        attendees.push(attendee);
      }

      const { event } = await createTestEvent(organizer.token, generateTestEventData({
        name: 'Analytics Test Event'
      }));
      testEvent = event;
    });

    it('should track event analytics through booking activity', async () => {
      // Generate booking activity
      for (let i = 0; i < attendees.length; i++) {
        await request(app)
          .post('/api/tickets/book')
          .set('Authorization', `Bearer ${attendees[i].token}`)
          .send({
            event_id: testEvent.event_id,
            ticket_type: 'General',
            quantity: i + 1 // 1, 2, 3 tickets respectively
          });
      }

      // Check event analytics
      const analyticsResponse = await request(app)
        .get(`/api/analytics/events/${testEvent.event_id}`)
        .set('Authorization', `Bearer ${organizer.token}`);

      expect(analyticsResponse.status).toBe(200);
      expectSuccessResponse(analyticsResponse);
      
      const analytics = analyticsResponse.body.data;
      expect(analytics.total_bookings).toBe(3);
      expect(analytics.total_tickets_sold).toBe(6); // 1 + 2 + 3
      expect(analytics.revenue).toBeGreaterThan(0);
    });

    it('should provide organizer dashboard analytics', async () => {
      // Create bookings
      await request(app)
        .post('/api/tickets/book')
        .set('Authorization', `Bearer ${attendees[0].token}`)
        .send({
          event_id: testEvent.event_id,
          ticket_type: 'General',
          quantity: 2
        });

      // Check organizer dashboard
      const dashboardResponse = await request(app)
        .get('/api/analytics/dashboard')
        .set('Authorization', `Bearer ${organizer.token}`);

      expect(dashboardResponse.status).toBe(200);
      expectSuccessResponse(dashboardResponse);
      
      const dashboard = dashboardResponse.body.data;
      expect(dashboard.total_events).toBeGreaterThanOrEqual(1);
      expect(dashboard.total_revenue).toBeGreaterThanOrEqual(0);
    });
  });

  describe('User Event Interactions', () => {
    let organizer;
    let attendee;
    let testEvent;

    beforeEach(async () => {
      organizer = await createTestOrganizer({
        email: generateUniqueEmail('interaction-organizer')
      });
      
      attendee = await createTestUser({
        email: generateUniqueEmail('interaction-attendee')
      });

      const { event } = await createTestEvent(organizer.token, generateTestEventData({
        name: 'Interaction Test Event'
      }));
      testEvent = event;
    });

    it('should handle event favoriting/bookmarking', async () => {
      // Add event to favorites
      const favoriteResponse = await request(app)
        .post(`/api/users/favorites/${testEvent.event_id}`)
        .set('Authorization', `Bearer ${attendee.token}`);

      expect(favoriteResponse.status).toBe(200);
      expectSuccessResponse(favoriteResponse);

      // Get user's favorite events
      const favoritesListResponse = await request(app)
        .get('/api/users/favorites')
        .set('Authorization', `Bearer ${attendee.token}`);

      expect(favoritesListResponse.status).toBe(200);
      expectSuccessResponse(favoritesListResponse);
      
      const favoriteEvent = favoritesListResponse.body.data.find(e => e.event_id === testEvent.event_id);
      expect(favoriteEvent).toBeDefined();

      // Remove from favorites
      const unfavoriteResponse = await request(app)
        .delete(`/api/users/favorites/${testEvent.event_id}`)
        .set('Authorization', `Bearer ${attendee.token}`);

      expect(unfavoriteResponse.status).toBe(200);
    });

    it('should show event attendance history', async () => {
      // Book a ticket
      const bookingResponse = await request(app)
        .post('/api/tickets/book')
        .set('Authorization', `Bearer ${attendee.token}`)
        .send({
          event_id: testEvent.event_id,
          ticket_type: 'General',
          quantity: 1
        });

      expect(bookingResponse.status).toBe(201);

      // Check attendance history
      const historyResponse = await request(app)
        .get('/api/users/attendance-history')
        .set('Authorization', `Bearer ${attendee.token}`);

      expect(historyResponse.status).toBe(200);
      expectSuccessResponse(historyResponse);
      
      const attendedEvent = historyResponse.body.data.find(e => e.event_id === testEvent.event_id);
      expect(attendedEvent).toBeDefined();
    });
  });

  describe('Search Integration Across Services', () => {
    let organizer;
    let testEvents = [];

    beforeEach(async () => {
      organizer = await createTestOrganizer({
        email: generateUniqueEmail('search-organizer')
      });

      // Create events with different characteristics
      const eventConfigs = [
        { name: 'Tech Conference 2024', event_type: 'CONFERENCE', venue: 'Tech Center' },
        { name: 'Rock Concert', event_type: 'CONCERT', venue: 'Music Hall' },
        { name: 'Art Workshop', event_type: 'WORKSHOP', venue: 'Art Studio' }
      ];

      for (const config of eventConfigs) {
        const { event } = await createTestEvent(organizer.token, generateTestEventData(config));
        testEvents.push(event);
      }
    });

    it('should provide comprehensive search across events and venues', async () => {
      // Search by event type
      const conferenceSearch = await request(app)
        .get('/api/events')
        .query({ event_type: 'CONFERENCE' });

      expect(conferenceSearch.status).toBe(200);
      expect(conferenceSearch.body.data.length).toBeGreaterThanOrEqual(1);

      // Search by venue
      const venueSearch = await request(app)
        .get('/api/events')
        .query({ search: 'Tech Center' });

      expect(venueSearch.status).toBe(200);
      
      // Search by name
      const nameSearch = await request(app)
        .get('/api/events')
        .query({ search: 'Rock Concert' });

      expect(nameSearch.status).toBe(200);
      
      if (nameSearch.body.data.length > 0) {
        expect(nameSearch.body.data[0].name).toContain('Rock Concert');
      }
    });

    it('should handle complex filtering combinations', async () => {
      const complexSearch = await request(app)
        .get('/api/events')
        .query({
          event_type: 'WORKSHOP',
          status: 'ACTIVE',
          search: 'Art'
        });

      expect(complexSearch.status).toBe(200);
      expectSuccessResponse(complexSearch);
      
      complexSearch.body.data.forEach(event => {
        expect(event.event_type).toBe('WORKSHOP');
        expect(event.status).toBe('ACTIVE');
      });
    });
  });

  describe('Error Handling Across Services', () => {
    let organizer;
    let attendee;

    beforeEach(async () => {
      organizer = await createTestOrganizer({
        email: generateUniqueEmail('error-organizer')
      });
      
      attendee = await createTestUser({
        email: generateUniqueEmail('error-attendee')
      });
    });

    it('should handle booking tickets for non-existent event', async () => {
      const response = await request(app)
        .post('/api/tickets/book')
        .set('Authorization', `Bearer ${attendee.token}`)
        .send({
          event_id: 999999,
          ticket_type: 'General',
          quantity: 1
        });

      expect(response.status).toBe(404);
      expectErrorResponse(response, 404);
    });

    it('should handle accessing other user tickets', async () => {
      const otherUser = await createTestUser({
        email: generateUniqueEmail('other-user')
      });

      const response = await request(app)
        .get('/api/tickets/my-tickets')
        .set('Authorization', `Bearer ${otherUser.token}`);

      expect(response.status).toBe(200);
      expect(response.body.data).toEqual([]); // Should be empty for new user
    });

    it('should handle concurrent booking attempts gracefully', async () => {
      const { event } = await createTestEvent(organizer.token, generateTestEventData({
        ticket_types: [
          {
            type: 'Limited',
            price: 100,
            available_quantity: 1 // Only 1 ticket available
          }
        ]
      }));

      // Simulate concurrent booking attempts
      const bookingPromises = [
        request(app)
          .post('/api/tickets/book')
          .set('Authorization', `Bearer ${attendee.token}`)
          .send({
            event_id: event.event_id,
            ticket_type: 'Limited',
            quantity: 1
          }),
        request(app)
          .post('/api/tickets/book')
          .set('Authorization', `Bearer ${attendee.token}`)
          .send({
            event_id: event.event_id,
            ticket_type: 'Limited',
            quantity: 1
          })
      ];

      const results = await Promise.all(bookingPromises);
      
      // One should succeed, one should fail
      const successCount = results.filter(r => r.status === 201).length;
      const failureCount = results.filter(r => r.status === 400).length;
      
      expect(successCount).toBe(1);
      expect(failureCount).toBe(1);
    });
  });
});