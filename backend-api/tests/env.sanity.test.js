describe('Environment variables sanity', () => {
  const required = ['DATABASE_URL', 'JWT_SECRET', 'REDIS_HOST', 'REDIS_PORT', 'NODE_ENV'];
  it('should have required env vars set', () => {
    const missing = required.filter(k => !process.env[k]);
    expect(missing).toEqual([]);
  });
  it('NODE_ENV is test', () => {
    expect(process.env.NODE_ENV).toBe('test');
  });
});
