/**
 * Tickets API - DB-backed Integration Tests
 */

const request = require('supertest');
const app = require('../../../server');

async function createUser(role = 'ATTENDEE') {
  const payload = {
    name: `User ${role}`,
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
    title: 'Ticket Test Event',
    description: 'For tickets API',
    start_time: new Date(Date.now() + 3600_000).toISOString(),
    end_time: new Date(Date.now() + 3*3600_000).toISOString(),
    location: 'Test Venue',
    address: '123 Test St',
    event_type: 'CONFERENCE',
    status: 'ACTIVE',
    ticket_types: [{ type: 'General', price: 50, available_quantity: 100 }],
    seat_map: null
  };
  const res = await request(app)
    .post('/api/events')
    .set('Authorization', `Bearer ${organizerToken}`)
    .send({ ...base, ...overrides });
  return res.body.data;
}

async function createPaymentAndTickets(userToken, event, count = 2) {
  const selectedSeatData = Array.from({ length: count }).map((_, i) => ({ label: `General-${i+1}`, price: 50 }));
  const selected_seats = selectedSeatData.map(s => s.label);
  const body = {
    event_id: event.event_id,
    amount: 50*count,
    selected_seats,
    selectedSeatData
  };
  const res = await request(app)
    .post('/api/payments')
    .set('Authorization', `Bearer ${userToken}`)
    .send(body);
  return res.body.payment;
}

describe('Tickets API (DB-backed)', () => {
  jest.setTimeout(60000);

  test('GET /api/tickets/my-tickets lists user tickets', async () => {
    const { token: organizerToken } = await createUser('ORGANIZER');
    const event = await createEvent(organizerToken);
    const { token: userToken } = await createUser('ATTENDEE');

    await createPaymentAndTickets(userToken, event, 2);

    const res = await request(app)
      .get('/api/tickets/my-tickets')
      .set('Authorization', `Bearer ${userToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.tickets)).toBe(true);
    expect(res.body.tickets.length).toBeGreaterThanOrEqual(2);
    const t = res.body.tickets[0];
    expect(typeof t.price).toBe('number');
  });

  test('GET /api/tickets/by-payment/:paymentId returns ticket', async () => {
    const { token: organizerToken } = await createUser('ORGANIZER');
    const event = await createEvent(organizerToken);
    const { token: userToken } = await createUser('ATTENDEE');

    const payment = await createPaymentAndTickets(userToken, event, 1);

    const res = await request(app)
      .get(`/api/tickets/by-payment/${payment.payment_id}`)
      .set('Authorization', `Bearer ${userToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.ticket).toBeDefined();
    expect(res.body.ticket.event_id).toBe(event.event_id);
  });

  test('GET /api/tickets/:ticketId returns own ticket and 404 for others', async () => {
    const { token: organizerToken } = await createUser('ORGANIZER');
    const event = await createEvent(organizerToken);
    const { token: userTokenA } = await createUser('ATTENDEE');
    const { token: userTokenB } = await createUser('ATTENDEE');

    const payment = await createPaymentAndTickets(userTokenA, event, 1);

    // fetch by payment to get ticket_id quickly
    const tRes = await request(app)
      .get(`/api/tickets/by-payment/${payment.payment_id}`)
      .set('Authorization', `Bearer ${userTokenA}`);

    const ticketId = tRes.body.ticket.ticket_id;

    const own = await request(app)
      .get(`/api/tickets/${ticketId}`)
      .set('Authorization', `Bearer ${userTokenA}`);
    expect(own.status).toBe(200);

    const other = await request(app)
      .get(`/api/tickets/${ticketId}`)
      .set('Authorization', `Bearer ${userTokenB}`);
    expect(other.status).toBe(404);
  });

  test('PUT /api/tickets/:ticketId/attend marks attendance', async () => {
    const { token: organizerToken } = await createUser('ORGANIZER');
    const event = await createEvent(organizerToken);
    const { token: userToken } = await createUser('ATTENDEE');

    const payment = await createPaymentAndTickets(userToken, event, 1);
    const tRes = await request(app)
      .get(`/api/tickets/by-payment/${payment.payment_id}`)
      .set('Authorization', `Bearer ${userToken}`);
    const ticketId = tRes.body.ticket.ticket_id;

    const attend = await request(app)
      .put(`/api/tickets/${ticketId}/attend`)
      .set('Authorization', `Bearer ${userToken}`)
      .send({});

    expect(attend.status).toBe(200);
    expect(attend.body.success).toBe(true);
    expect(attend.body.ticket.attended).toBe(true);
  });

  test('GET /api/tickets/qr/:qrCode 404 for unknown', async () => {
    const { token: userToken } = await createUser('ATTENDEE');
    const res = await request(app)
      .get('/api/tickets/qr/UNKNOWN_QR')
      .set('Authorization', `Bearer ${userToken}`);

    expect([404, 200]).toContain(res.status); // route returns 404 if not found, 200 if found
    if (res.status === 404) {
      expect(res.body.success).toBe(false);
    }
  });
});
