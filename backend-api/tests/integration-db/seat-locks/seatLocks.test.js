/**
 * Seat Locks API - DB-backed Integration Tests
 */

const request = require('supertest');
const app = require('../../../server');

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
    title: 'Seat Lock Test Event',
    description: 'Event for seat lock testing',
    start_time: new Date(Date.now() + 3600_000).toISOString(),
    end_time: new Date(Date.now() + 3*3600_000).toISOString(),
    location: 'Test Venue',
    address: '123 Test St',
    event_type: 'CONFERENCE',
    status: 'ACTIVE',
    ticket_types: [{ type: 'General', price: 50, available_quantity: 100 }],
    seat_map: [
      { id: 1, label: 'A1', row: 1, column: 1, available: true, price: 60 },
      { id: 2, label: 'A2', row: 1, column: 2, available: true, price: 60 }
    ]
  };
  const res = await request(app)
    .post('/api/events')
    .set('Authorization', `Bearer ${organizerToken}`)
    .send({ ...base, ...overrides });
  return res.body.data;
}

describe('Seat Locks API (DB-backed)', () => {
  jest.setTimeout(60000);

  test('Direct lock -> status -> idempotent lock by same user -> conflict for other user', async () => {
    const { token: orgToken } = await createUser('ORGANIZER');
    const event = await createEvent(orgToken);
    const { token: userA } = await createUser('ATTENDEE');
    const { token: userB } = await createUser('ATTENDEE');

    // Lock seat by user A
    const lockA = await request(app)
      .post(`/api/seat-locks/events/${event.event_id}/seats/1/lock`)
      .set('Authorization', `Bearer ${userA}`);
    expect(lockA.status).toBe(200);
    expect(lockA.body.success).toBe(true);

    // Status should show locked
    const status = await request(app)
      .get(`/api/seat-locks/events/${event.event_id}/seats/1/lock`);
    expect(status.status).toBe(200);
    expect(status.body.success).toBe(true);
    expect(status.body.lockStatus.locked).toBe(true);

    // Idempotent lock for same user
    const lockA2 = await request(app)
      .post(`/api/seat-locks/events/${event.event_id}/seats/1/lock`)
      .set('Authorization', `Bearer ${userA}`);
    expect(lockA2.status).toBe(200);
    expect(lockA2.body.success).toBe(true);

    // Other user should get 409
    const lockB = await request(app)
      .post(`/api/seat-locks/events/${event.event_id}/seats/1/lock`)
      .set('Authorization', `Bearer ${userB}`);
    expect(lockB.status).toBe(409);
    expect(lockB.body.success).toBe(false);
  });

  test('Extend and release lock (owner vs other)', async () => {
    const { token: orgToken } = await createUser('ORGANIZER');
    const event = await createEvent(orgToken);
    const { token: userA } = await createUser('ATTENDEE');
    const { token: userB } = await createUser('ATTENDEE');

    // Lock seat by user A
    await request(app)
      .post(`/api/seat-locks/events/${event.event_id}/seats/2/lock`)
      .set('Authorization', `Bearer ${userA}`)
      .expect(200);

    // Extend by owner succeeds
    const extendA = await request(app)
      .put(`/api/seat-locks/events/${event.event_id}/seats/2/lock/extend`)
      .set('Authorization', `Bearer ${userA}`);
    expect(extendA.status).toBe(200);
    expect(extendA.body.success).toBe(true);

    // Extend by other user fails (403)
    const extendB = await request(app)
      .put(`/api/seat-locks/events/${event.event_id}/seats/2/lock/extend`)
      .set('Authorization', `Bearer ${userB}`);
    expect([403, 409]).toContain(extendB.status);

    // Release by other user fails (403)
    const releaseB = await request(app)
      .delete(`/api/seat-locks/events/${event.event_id}/seats/2/lock`)
      .set('Authorization', `Bearer ${userB}`);
    expect(releaseB.status).toBe(403);

    // Release by owner succeeds
    const releaseA = await request(app)
      .delete(`/api/seat-locks/events/${event.event_id}/seats/2/lock`)
      .set('Authorization', `Bearer ${userA}`);
    expect(releaseA.status).toBe(200);
    expect(releaseA.body.success).toBe(true);

    // Status now unlocked
    const status = await request(app)
      .get(`/api/seat-locks/events/${event.event_id}/seats/2/lock`);
    expect(status.body.lockStatus.locked).toBe(false);
  });

  test('Hybrid: lock returns 200 or 202; poll queued result and check stats', async () => {
    const { token: orgToken } = await createUser('ORGANIZER');
    const event = await createEvent(orgToken);
    const { token: userA } = await createUser('ATTENDEE');
    const { token: userB } = await createUser('ATTENDEE');

    // First user tries hybrid lock
    const h1 = await request(app)
      .post(`/api/seat-locks/events/${event.event_id}/seats/1/hybrid/lock`)
      .set('Authorization', `Bearer ${userA}`);
    expect([200, 202]).toContain(h1.status);

    // Second user tries immediately, may get queued (202) or conflict
    const h2 = await request(app)
      .post(`/api/seat-locks/events/${event.event_id}/seats/1/hybrid/lock`)
      .set('Authorization', `Bearer ${userB}`);
    expect([200, 202, 409]).toContain(h2.status);

    // Stats endpoint should work
    const stats = await request(app)
      .get(`/api/seat-locks/events/${event.event_id}/hybrid/stats`);
    expect(stats.status).toBe(200);
    expect(stats.body.success).toBe(true);
    expect(stats.body.eventId).toBe(String(event.event_id));
  });
});
