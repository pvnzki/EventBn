/**
 * Payments API - DB-backed Integration Tests
 */

const request = require('supertest');
const app = require('../../../server');

// Simple helper to register and login a user
async function createUser(role = 'ATTENDEE') {
  const payload = {
    name: `Test ${role}`,
    email: `${role.toLowerCase()}_${Date.now()}@example.com`,
    password: 'password123',
    phone: '+1000000000',
    role
  };
  const res = await request(app).post('/api/auth/register').send(payload);
  return { token: res.body.token, user: res.body.data };
}

async function createEvent(organizerToken, overrides = {}) {
  const base = {
    title: 'DB Test Event',
    description: 'Event for payments testing',
    start_time: new Date(Date.now() + 3600_000).toISOString(),
    end_time: new Date(Date.now() + 3*3600_000).toISOString(),
    location: 'Test Venue',
    address: '123 Test St',
    event_type: 'CONFERENCE',
    status: 'ACTIVE',
    ticket_types: [{ type: 'General', price: 50, available_quantity: 100 }],
    seat_map: []
  };
  const res = await request(app)
    .post('/api/events')
    .set('Authorization', `Bearer ${organizerToken}`)
    .send({ ...base, ...overrides });
  return res.body.data;
}

describe('Payments API (DB-backed)', () => {
  jest.setTimeout(60000);

  test('POST /api/payments creates payment and tickets (no seat_map)', async () => {
    const { token: organizerToken } = await createUser('ORGANIZER');
    const event = await createEvent(organizerToken, { seat_map: null });
    const { token: userToken, user } = await createUser('ATTENDEE');

    const body = {
      event_id: event.event_id,
      amount: 100.0,
      payment_method: 'card',
      selected_seats: ['General-1', 'General-2'],
      selectedSeatData: [
        { label: 'General-1', price: 50 },
        { label: 'General-2', price: 50 }
      ]
    };

    const payRes = await request(app)
      .post('/api/payments')
      .set('Authorization', `Bearer ${userToken}`)
      .send(body);

    expect(payRes.status).toBe(201);
    expect(payRes.body.success).toBe(true);
    expect(payRes.body.payment).toBeDefined();
    expect(payRes.body.payment.event_id).toBe(event.event_id);

    // Fetch my payments
    const listRes = await request(app)
      .get('/api/payments/my-payments')
      .set('Authorization', `Bearer ${userToken}`);
    expect(listRes.status).toBe(200);
    expect(listRes.body.success).toBe(true);
    expect(Array.isArray(listRes.body.payments)).toBe(true);
    expect(listRes.body.payments.length).toBeGreaterThanOrEqual(1);

    // Tickets by payment
    const paymentId = payRes.body.payment.payment_id;
    const ticketByPayment = await request(app)
      .get(`/api/tickets/by-payment/${paymentId}`)
      .set('Authorization', `Bearer ${userToken}`);

    expect(ticketByPayment.status).toBe(200);
    expect(ticketByPayment.body.success).toBe(true);
    expect(ticketByPayment.body.ticket).toBeDefined();
    expect(ticketByPayment.body.ticket.event_id).toBe(event.event_id);
  });

  test('POST /api/payments with seat_map updates seat availability', async () => {
    const { token: organizerToken } = await createUser('ORGANIZER');
    const seatMap = [
      { id: 1, label: 'A1', row: 1, column: 1, available: true, price: 60 },
      { id: 2, label: 'A2', row: 1, column: 2, available: true, price: 60 }
    ];
    const event = await createEvent(organizerToken, { seat_map: seatMap });
    const { token: userToken } = await createUser('ATTENDEE');

    const payRes = await request(app)
      .post('/api/payments')
      .set('Authorization', `Bearer ${userToken}`)
      .send({
        event_id: event.event_id,
        amount: 120.0,
        selected_seats: ['1', '2']
      });

    expect(payRes.status).toBe(201);

    // Get event again to verify seat_map updated (via GET /api/events/:id)
    const eventRes = await request(app).get(`/api/events/${event.event_id}`);
    expect(eventRes.status).toBe(200);
    const updated = eventRes.body.data.seat_map;
    const a1 = updated.find(s => s.id === 1);
    const a2 = updated.find(s => s.id === 2);
    expect(a1.available).toBe(false);
    expect(a2.available).toBe(false);
  });

  test('Validation: missing fields and 404 event', async () => {
    const { token: userToken } = await createUser('ATTENDEE');

    const bad1 = await request(app)
      .post('/api/payments')
      .set('Authorization', `Bearer ${userToken}`)
      .send({});
    expect(bad1.status).toBe(400);

    const bad2 = await request(app)
      .post('/api/payments')
      .set('Authorization', `Bearer ${userToken}`)
      .send({ event_id: 999999, amount: 10, selected_seats: ['X'] });
    expect(bad2.status).toBe(404);
  });

  test('Auth required on payments endpoints', async () => {
    const res = await request(app).get('/api/payments/my-payments');
    expect([401, 400]).toContain(res.status);
  });
});
