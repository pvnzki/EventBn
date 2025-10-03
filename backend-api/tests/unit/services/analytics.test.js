// Unit test for analyticsService.getAllAnalytics with mocked database
const analyticsService = require('../services/core-service/analytics');

jest.mock('../lib/database', () => ({
  monthlyAnalytics: {
    findMany: jest.fn().mockResolvedValue([
      { year: 2025, month: 9, value: 100 },
      { year: 2025, month: 8, value: 80 }
    ])
  },
  monthly_analytics: {
    findMany: jest.fn().mockImplementation(({ where }) => {
      if (where && where.year === 2025) {
        return Promise.resolve([
          { year: 2025, month: 7, value: 50 },
          { year: 2025, month: 8, value: 80 }
        ]);
      }
      return Promise.resolve([]);
    }),
    findUnique: jest.fn().mockImplementation(({ where }) => {
      if (where && where.year_month && where.year_month.year === 2025 && where.year_month.month === 9) {
        return Promise.resolve({ year: 2025, month: 9, value: 100 });
      }
      return Promise.resolve(null);
    }),
    create: jest.fn().mockImplementation(({ data }) => Promise.resolve({ id: 1, ...data })),
    update: jest.fn().mockImplementation(({ where, data }) => Promise.resolve({ id: where.id, ...data })),
    delete: jest.fn().mockImplementation(({ where }) => Promise.resolve({ id: where.id })),
  }
}));
describe('analyticsService.createAnalytics', () => {
  it('should create a new analytics record', async () => {
    const data = { year: 2025, month: 10, value: 200 };
    const result = await analyticsService.createAnalytics(data);
    expect(result).toEqual({ id: 1, year: 2025, month: 10, value: 200 });
  });

  it('should throw error if db fails', async () => {
    const db = require('../lib/database');
    db.monthly_analytics.create.mockRejectedValueOnce(new Error('DB error'));
    await expect(analyticsService.createAnalytics({})).rejects.toThrow('Failed to create analytics: DB error');
  });
});

describe('analyticsService.updateAnalytics', () => {
  it('should update an analytics record', async () => {
    const data = { value: 300 };
    const result = await analyticsService.updateAnalytics(1, data);
    expect(result).toEqual({ id: 1, value: 300 });
  });

  it('should throw error if db fails', async () => {
    const db = require('../lib/database');
    db.monthly_analytics.update.mockRejectedValueOnce(new Error('DB error'));
    await expect(analyticsService.updateAnalytics(1, {})).rejects.toThrow('Failed to update analytics: DB error');
  });
});

describe('analyticsService.deleteAnalytics', () => {
  it('should delete an analytics record', async () => {
    const result = await analyticsService.deleteAnalytics(1);
    expect(result).toEqual({ id: 1 });
  });

  it('should throw error if db fails', async () => {
    const db = require('../lib/database');
    db.monthly_analytics.delete.mockRejectedValueOnce(new Error('DB error'));
    await expect(analyticsService.deleteAnalytics(1)).rejects.toThrow('Failed to delete analytics: DB error');
  });
});

describe('analyticsService.getAllAnalytics', () => {
  it('should return analytics data ordered by year and month', async () => {
    const data = await analyticsService.getAllAnalytics();
    expect(data).toEqual([
      { year: 2025, month: 9, value: 100 },
      { year: 2025, month: 8, value: 80 }
    ]);
  });
  it('should throw error if db fails', async () => {
    const db = require('../lib/database');
    db.monthlyAnalytics.findMany.mockRejectedValueOnce(new Error('DB error'));
    await expect(analyticsService.getAllAnalytics()).rejects.toThrow('Failed to fetch analytics: DB error');
  });
});
describe('analyticsService.getAnalyticsByYear', () => {
  it('should return analytics data for a given year', async () => {
    const data = await analyticsService.getAnalyticsByYear(2025);
    expect(data).toEqual([
      { year: 2025, month: 7, value: 50 },
      { year: 2025, month: 8, value: 80 }
    ]);
  });

  it('should return an empty array if no data for year', async () => {
    const data = await analyticsService.getAnalyticsByYear(1999);
    expect(data).toEqual([]);
  });

  it('should throw error if db fails', async () => {
    const db = require('../lib/database');
    db.monthly_analytics.findMany.mockRejectedValueOnce(new Error('DB error'));
    await expect(analyticsService.getAnalyticsByYear(2025)).rejects.toThrow('Failed to fetch analytics by year: DB error');
  });
});

describe('analyticsService.getAnalyticsByMonth', () => {
  it('should return analytics data for a given year and month', async () => {
    const data = await analyticsService.getAnalyticsByMonth(2025, 9);
    expect(data).toEqual({ year: 2025, month: 9, value: 100 });
  });

  it('should return null if no data for year and month', async () => {
    const data = await analyticsService.getAnalyticsByMonth(2020, 1);
    expect(data).toBeNull();
  });

  it('should throw error if db fails', async () => {
    const db = require('../lib/database');
    db.monthly_analytics.findUnique.mockRejectedValueOnce(new Error('DB error'));
    await expect(analyticsService.getAnalyticsByMonth(2025, 9)).rejects.toThrow('Failed to fetch analytics by month: DB error');
  });
});
