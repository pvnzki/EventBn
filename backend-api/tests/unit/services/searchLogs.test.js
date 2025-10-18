// Unit tests for tickets/search logs service
const searchLogsService = require('../../../services/core-service/tickets');

// Mock the database
jest.mock('../../../lib/database', () => ({
  search_Log: {
    create: jest.fn(),
    findMany: jest.fn(),
    findUnique: jest.fn(),
    groupBy: jest.fn(),
    count: jest.fn(),
    deleteMany: jest.fn(),
    update: jest.fn(),
    delete: jest.fn()
  }
}));

const db = require('../../../lib/database');

describe('Search Logs Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    // Reset date mocking
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2024-01-15')); // Set a fixed date for consistent testing
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  describe('createSearchLog', () => {
    const searchLogData = {
      user_id: 1,
      search_query: 'test search',
      search_time: '2024-01-15T10:00:00Z',
      filters_applied: '{"category": "music"}'
    };

    const mockCreatedLog = {
      log_id: 1,
      user_id: 1,
      search_query: 'test search',
      search_time: new Date('2024-01-15T10:00:00Z'),
      filters_applied: '{"category": "music"}',
      user: {
        user_id: 1,
        name: 'John Doe'
      }
    };

    it('should create search log with all provided data', async () => {
      db.search_Log.create.mockResolvedValueOnce(mockCreatedLog);

      const result = await searchLogsService.createSearchLog(searchLogData);

      expect(db.search_Log.create).toHaveBeenCalledWith({
        data: {
          user_id: 1,
          search_query: 'test search',
          search_time: new Date('2024-01-15T10:00:00Z'),
          filters_applied: '{"category": "music"}'
        },
        include: {
          user: {
            select: {
              user_id: true,
              name: true
            }
          }
        }
      });
      expect(result).toEqual(mockCreatedLog);
    });

    it('should create search log with minimal data and defaults', async () => {
      const minimalData = {
        search_query: 'test search'
      };

      db.search_Log.create.mockResolvedValueOnce(mockCreatedLog);

      await searchLogsService.createSearchLog(minimalData);

      expect(db.search_Log.create).toHaveBeenCalledWith({
        data: {
          user_id: null,
          search_query: 'test search',
          search_time: new Date('2024-01-15'),
          filters_applied: null
        },
        include: expect.any(Object)
      });
    });

    it('should handle string user_id by converting to integer', async () => {
      db.search_Log.create.mockResolvedValueOnce(mockCreatedLog);

      await searchLogsService.createSearchLog({
        user_id: '1',
        search_query: 'test'
      });

      expect(db.search_Log.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          user_id: 1
        }),
        include: expect.any(Object)
      });
    });

    it('should use current time when search_time not provided', async () => {
      db.search_Log.create.mockResolvedValueOnce(mockCreatedLog);

      await searchLogsService.createSearchLog({
        search_query: 'test'
      });

      expect(db.search_Log.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          search_time: new Date('2024-01-15')
        }),
        include: expect.any(Object)
      });
    });

    it('should throw error if database fails', async () => {
      db.search_Log.create.mockRejectedValueOnce(new Error('DB error'));

      await expect(searchLogsService.createSearchLog(searchLogData))
        .rejects
        .toThrow('Failed to create search log: DB error');
    });
  });

  describe('getAllSearchLogs', () => {
    const mockSearchLogs = [
      {
        log_id: 1,
        user_id: 1,
        search_query: 'test search 1',
        search_time: new Date('2024-01-15'),
        filters_applied: null,
        user: {
          user_id: 1,
          name: 'John Doe',
          email: 'john@example.com'
        }
      },
      {
        log_id: 2,
        user_id: 2,
        search_query: 'test search 2',
        search_time: new Date('2024-01-14'),
        filters_applied: '{"category": "sports"}',
        user: {
          user_id: 2,
          name: 'Jane Smith',
          email: 'jane@example.com'
        }
      }
    ];

    it('should return all search logs when no filters provided', async () => {
      db.search_Log.findMany.mockResolvedValueOnce(mockSearchLogs);

      const result = await searchLogsService.getAllSearchLogs();

      expect(db.search_Log.findMany).toHaveBeenCalledWith({
        where: {},
        include: {
          user: {
            select: {
              user_id: true,
              name: true,
              email: true
            }
          }
        },
        orderBy: { search_time: 'desc' }
      });
      expect(result).toEqual(mockSearchLogs);
    });

    it('should filter by user_id', async () => {
      db.search_Log.findMany.mockResolvedValueOnce([mockSearchLogs[0]]);

      await searchLogsService.getAllSearchLogs({ user_id: 1 });

      expect(db.search_Log.findMany).toHaveBeenCalledWith({
        where: { user_id: 1 },
        include: expect.any(Object),
        orderBy: { search_time: 'desc' }
      });
    });

    it('should handle string user_id by converting to integer', async () => {
      db.search_Log.findMany.mockResolvedValueOnce([]);

      await searchLogsService.getAllSearchLogs({ user_id: '1' });

      expect(db.search_Log.findMany).toHaveBeenCalledWith({
        where: { user_id: 1 },
        include: expect.any(Object),
        orderBy: { search_time: 'desc' }
      });
    });

    it('should filter by search_query', async () => {
      db.search_Log.findMany.mockResolvedValueOnce([mockSearchLogs[0]]);

      await searchLogsService.getAllSearchLogs({ search_query: 'test' });

      expect(db.search_Log.findMany).toHaveBeenCalledWith({
        where: {
          search_query: { contains: 'test', mode: 'insensitive' }
        },
        include: expect.any(Object),
        orderBy: { search_time: 'desc' }
      });
    });

    it('should filter by start_date', async () => {
      db.search_Log.findMany.mockResolvedValueOnce([mockSearchLogs[0]]);

      await searchLogsService.getAllSearchLogs({ start_date: '2024-01-10' });

      expect(db.search_Log.findMany).toHaveBeenCalledWith({
        where: {
          search_time: { gte: new Date('2024-01-10') }
        },
        include: expect.any(Object),
        orderBy: { search_time: 'desc' }
      });
    });

    it('should filter by end_date', async () => {
      db.search_Log.findMany.mockResolvedValueOnce([mockSearchLogs[1]]);

      await searchLogsService.getAllSearchLogs({ end_date: '2024-01-14' });

      expect(db.search_Log.findMany).toHaveBeenCalledWith({
        where: {
          search_time: { lte: new Date('2024-01-14') }
        },
        include: expect.any(Object),
        orderBy: { search_time: 'desc' }
      });
    });

    it('should filter by date range', async () => {
      db.search_Log.findMany.mockResolvedValueOnce(mockSearchLogs);

      await searchLogsService.getAllSearchLogs({ 
        start_date: '2024-01-10',
        end_date: '2024-01-20'
      });

      expect(db.search_Log.findMany).toHaveBeenCalledWith({
        where: {
          search_time: { 
            gte: new Date('2024-01-10'),
            lte: new Date('2024-01-20')
          }
        },
        include: expect.any(Object),
        orderBy: { search_time: 'desc' }
      });
    });

    it('should combine multiple filters', async () => {
      db.search_Log.findMany.mockResolvedValueOnce([]);

      await searchLogsService.getAllSearchLogs({
        user_id: 1,
        search_query: 'test',
        start_date: '2024-01-10'
      });

      expect(db.search_Log.findMany).toHaveBeenCalledWith({
        where: {
          user_id: 1,
          search_query: { contains: 'test', mode: 'insensitive' },
          search_time: { gte: new Date('2024-01-10') }
        },
        include: expect.any(Object),
        orderBy: { search_time: 'desc' }
      });
    });

    it('should throw error if database fails', async () => {
      db.search_Log.findMany.mockRejectedValueOnce(new Error('DB error'));

      await expect(searchLogsService.getAllSearchLogs())
        .rejects
        .toThrow('Failed to fetch search logs: DB error');
    });
  });

  describe('getSearchLogById', () => {
    const mockSearchLog = {
      log_id: 1,
      user_id: 1,
      search_query: 'test search',
      search_time: new Date('2024-01-15'),
      filters_applied: null,
      user: {
        user_id: 1,
        name: 'John Doe',
        email: 'john@example.com'
      }
    };

    it('should return search log for valid ID', async () => {
      db.search_Log.findUnique.mockResolvedValueOnce(mockSearchLog);

      const result = await searchLogsService.getSearchLogById(1);

      expect(db.search_Log.findUnique).toHaveBeenCalledWith({
        where: { log_id: 1 },
        include: {
          user: {
            select: {
              user_id: true,
              name: true,
              email: true
            }
          }
        }
      });
      expect(result).toEqual(mockSearchLog);
    });

    it('should return null for non-existent search log', async () => {
      db.search_Log.findUnique.mockResolvedValueOnce(null);

      const result = await searchLogsService.getSearchLogById(999);

      expect(result).toBeNull();
    });

    it('should handle string ID by converting to integer', async () => {
      db.search_Log.findUnique.mockResolvedValueOnce(mockSearchLog);

      await searchLogsService.getSearchLogById('1');

      expect(db.search_Log.findUnique).toHaveBeenCalledWith({
        where: { log_id: 1 },
        include: expect.any(Object)
      });
    });

    it('should throw error if database fails', async () => {
      db.search_Log.findUnique.mockRejectedValueOnce(new Error('DB error'));

      await expect(searchLogsService.getSearchLogById(1))
        .rejects
        .toThrow('Failed to fetch search log: DB error');
    });
  });

  describe('getUserSearchHistory', () => {
    const mockUserHistory = [
      {
        log_id: 1,
        user_id: 1,
        search_query: 'recent search',
        search_time: new Date('2024-01-15'),
        filters_applied: null
      },
      {
        log_id: 2,
        user_id: 1,
        search_query: 'older search',
        search_time: new Date('2024-01-14'),
        filters_applied: '{"category": "music"}'
      }
    ];

    it('should return user search history with default limit', async () => {
      db.search_Log.findMany.mockResolvedValueOnce(mockUserHistory);

      const result = await searchLogsService.getUserSearchHistory(1);

      expect(db.search_Log.findMany).toHaveBeenCalledWith({
        where: { user_id: 1 },
        orderBy: { search_time: 'desc' },
        take: 50
      });
      expect(result).toEqual(mockUserHistory);
    });

    it('should return user search history with custom limit', async () => {
      db.search_Log.findMany.mockResolvedValueOnce([mockUserHistory[0]]);

      await searchLogsService.getUserSearchHistory(1, 10);

      expect(db.search_Log.findMany).toHaveBeenCalledWith({
        where: { user_id: 1 },
        orderBy: { search_time: 'desc' },
        take: 10
      });
    });

    it('should handle string userId by converting to integer', async () => {
      db.search_Log.findMany.mockResolvedValueOnce([]);

      await searchLogsService.getUserSearchHistory('1');

      expect(db.search_Log.findMany).toHaveBeenCalledWith({
        where: { user_id: 1 },
        orderBy: { search_time: 'desc' },
        take: 50
      });
    });

    it('should return empty array if user has no search history', async () => {
      db.search_Log.findMany.mockResolvedValueOnce([]);

      const result = await searchLogsService.getUserSearchHistory(999);

      expect(result).toEqual([]);
    });

    it('should throw error if database fails', async () => {
      db.search_Log.findMany.mockRejectedValueOnce(new Error('DB error'));

      await expect(searchLogsService.getUserSearchHistory(1))
        .rejects
        .toThrow('Failed to fetch user search history: DB error');
    });
  });

  describe('getPopularSearchQueries', () => {
    const mockPopularQueries = [
      { search_query: 'popular search', _count: { search_query: 10 } },
      { search_query: 'another search', _count: { search_query: 8 } },
      { search_query: 'third search', _count: { search_query: 5 } }
    ];

    it('should return popular search queries with default parameters', async () => {
      db.search_Log.groupBy.mockResolvedValueOnce(mockPopularQueries);

      const result = await searchLogsService.getPopularSearchQueries();

      // Calculate expected start date (30 days ago from 2024-01-15)
      const expectedStartDate = new Date('2024-01-15');
      expectedStartDate.setDate(expectedStartDate.getDate() - 30);

      expect(db.search_Log.groupBy).toHaveBeenCalledWith({
        by: ['search_query'],
        where: {
          search_time: { gte: expectedStartDate }
        },
        _count: {
          search_query: true
        },
        orderBy: {
          _count: {
            search_query: 'desc'
          }
        },
        take: 10
      });

      expect(result).toEqual([
        { query: 'popular search', count: 10 },
        { query: 'another search', count: 8 },
        { query: 'third search', count: 5 }
      ]);
    });

    it('should return popular search queries with custom limit and days', async () => {
      db.search_Log.groupBy.mockResolvedValueOnce(mockPopularQueries.slice(0, 2));

      await searchLogsService.getPopularSearchQueries(5, 7);

      // Calculate expected start date (7 days ago from 2024-01-15)
      const expectedStartDate = new Date('2024-01-15');
      expectedStartDate.setDate(expectedStartDate.getDate() - 7);

      expect(db.search_Log.groupBy).toHaveBeenCalledWith({
        by: ['search_query'],
        where: {
          search_time: { gte: expectedStartDate }
        },
        _count: {
          search_query: true
        },
        orderBy: {
          _count: {
            search_query: 'desc'
          }
        },
        take: 5
      });
    });

    it('should return empty array if no popular queries found', async () => {
      db.search_Log.groupBy.mockResolvedValueOnce([]);

      const result = await searchLogsService.getPopularSearchQueries();

      expect(result).toEqual([]);
    });

    it('should throw error if database fails', async () => {
      db.search_Log.groupBy.mockRejectedValueOnce(new Error('DB error'));

      await expect(searchLogsService.getPopularSearchQueries())
        .rejects
        .toThrow('Failed to fetch popular search queries: DB error');
    });
  });

  describe('getSearchAnalytics', () => {
    it('should return search analytics with default 30 days', async () => {
      // Mock count query
      db.search_Log.count.mockResolvedValueOnce(150);
      
      // Mock unique users query
      db.search_Log.findMany.mockResolvedValueOnce([
        { user_id: 1 },
        { user_id: 2 },
        { user_id: 3 }
      ]);
      
      // Mock searches by day query
      db.search_Log.groupBy.mockResolvedValueOnce([
        { search_time: new Date('2024-01-15'), _count: { log_id: 25 } },
        { search_time: new Date('2024-01-14'), _count: { log_id: 30 } },
        { search_time: new Date('2024-01-13'), _count: { log_id: 20 } }
      ]);

      const result = await searchLogsService.getSearchAnalytics();

      // Calculate expected start date (30 days ago from 2024-01-15)
      const expectedStartDate = new Date('2024-01-15');
      expectedStartDate.setDate(expectedStartDate.getDate() - 30);

      // Check total searches count call
      expect(db.search_Log.count).toHaveBeenCalledWith({
        where: {
          search_time: { gte: expectedStartDate }
        }
      });

      // Check unique users findMany call
      expect(db.search_Log.findMany).toHaveBeenCalledWith({
        where: {
          search_time: { gte: expectedStartDate },
          user_id: { not: null }
        },
        distinct: ['user_id'],
        select: { user_id: true }
      });

      // Check searches by day groupBy call
      expect(db.search_Log.groupBy).toHaveBeenCalledWith({
        by: ['search_time'],
        where: {
          search_time: { gte: expectedStartDate }
        },
        _count: {
          log_id: true
        }
      });

      expect(result).toEqual({
        totalSearches: 150,
        uniqueUsers: 3,
        searchesByDay: [
          { date: new Date('2024-01-15'), count: 25 },
          { date: new Date('2024-01-14'), count: 30 },
          { date: new Date('2024-01-13'), count: 20 }
        ]
      });
    });

    it('should return search analytics with custom days', async () => {
      db.search_Log.count.mockResolvedValueOnce(50);
      db.search_Log.findMany.mockResolvedValueOnce([{ user_id: 1 }]);
      db.search_Log.groupBy.mockResolvedValueOnce([]);

      await searchLogsService.getSearchAnalytics(7);

      // Calculate expected start date (7 days ago from 2024-01-15)
      const expectedStartDate = new Date('2024-01-15');
      expectedStartDate.setDate(expectedStartDate.getDate() - 7);

      expect(db.search_Log.count).toHaveBeenCalledWith({
        where: {
          search_time: { gte: expectedStartDate }
        }
      });
    });

    it('should handle no data gracefully', async () => {
      db.search_Log.count.mockResolvedValueOnce(0);
      db.search_Log.findMany.mockResolvedValueOnce([]);
      db.search_Log.groupBy.mockResolvedValueOnce([]);

      const result = await searchLogsService.getSearchAnalytics();

      expect(result).toEqual({
        totalSearches: 0,
        uniqueUsers: 0,
        searchesByDay: []
      });
    });

    it('should throw error if database fails', async () => {
      db.search_Log.count.mockRejectedValueOnce(new Error('DB error'));

      await expect(searchLogsService.getSearchAnalytics())
        .rejects
        .toThrow('Failed to fetch search analytics: DB error');
    });
  });

  describe('cleanupOldSearchLogs', () => {
    it('should delete old search logs with default 90 days', async () => {
      const mockResult = { count: 25 };
      db.search_Log.deleteMany.mockResolvedValueOnce(mockResult);

      const result = await searchLogsService.cleanupOldSearchLogs();

      // Calculate expected cutoff date (90 days ago from 2024-01-15)
      const expectedCutoffDate = new Date('2024-01-15');
      expectedCutoffDate.setDate(expectedCutoffDate.getDate() - 90);

      expect(db.search_Log.deleteMany).toHaveBeenCalledWith({
        where: {
          search_time: { lt: expectedCutoffDate }
        }
      });

      expect(result).toEqual({ deletedCount: 25 });
    });

    it('should delete old search logs with custom days to keep', async () => {
      const mockResult = { count: 10 };
      db.search_Log.deleteMany.mockResolvedValueOnce(mockResult);

      await searchLogsService.cleanupOldSearchLogs(30);

      // Calculate expected cutoff date (30 days ago from 2024-01-15)
      const expectedCutoffDate = new Date('2024-01-15');
      expectedCutoffDate.setDate(expectedCutoffDate.getDate() - 30);

      expect(db.search_Log.deleteMany).toHaveBeenCalledWith({
        where: {
          search_time: { lt: expectedCutoffDate }
        }
      });
    });

    it('should return zero count when no old logs found', async () => {
      const mockResult = { count: 0 };
      db.search_Log.deleteMany.mockResolvedValueOnce(mockResult);

      const result = await searchLogsService.cleanupOldSearchLogs();

      expect(result).toEqual({ deletedCount: 0 });
    });

    it('should throw error if database fails', async () => {
      db.search_Log.deleteMany.mockRejectedValueOnce(new Error('DB error'));

      await expect(searchLogsService.cleanupOldSearchLogs())
        .rejects
        .toThrow('Failed to cleanup old search logs: DB error');
    });
  });

  describe('updateSearchLog', () => {
    const logId = 1;
    const updateData = {
      search_query: 'updated search',
      filters_applied: '{"category": "updated"}'
    };

    const mockUpdatedLog = {
      log_id: 1,
      user_id: 1,
      search_query: 'updated search',
      search_time: new Date('2024-01-15'),
      filters_applied: '{"category": "updated"}',
      user: {
        user_id: 1,
        name: 'John Doe'
      }
    };

    it('should update search log successfully', async () => {
      db.search_Log.update.mockResolvedValueOnce(mockUpdatedLog);

      const result = await searchLogsService.updateSearchLog(logId, updateData);

      expect(db.search_Log.update).toHaveBeenCalledWith({
        where: { log_id: 1 },
        data: {
          search_query: 'updated search',
          filters_applied: '{"category": "updated"}'
        },
        include: {
          user: {
            select: {
              user_id: true,
              name: true
            }
          }
        }
      });
      expect(result).toEqual(mockUpdatedLog);
    });

    it('should handle string logId by converting to integer', async () => {
      db.search_Log.update.mockResolvedValueOnce(mockUpdatedLog);

      await searchLogsService.updateSearchLog('1', updateData);

      expect(db.search_Log.update).toHaveBeenCalledWith({
        where: { log_id: 1 },
        data: expect.any(Object),
        include: expect.any(Object)
      });
    });

    it('should convert string user_id to integer when provided', async () => {
      db.search_Log.update.mockResolvedValueOnce(mockUpdatedLog);

      await searchLogsService.updateSearchLog(logId, {
        ...updateData,
        user_id: '2'
      });

      expect(db.search_Log.update).toHaveBeenCalledWith({
        where: { log_id: 1 },
        data: {
          search_query: 'updated search',
          filters_applied: '{"category": "updated"}',
          user_id: 2
        },
        include: expect.any(Object)
      });
    });

    it('should remove restricted fields from update data', async () => {
      db.search_Log.update.mockResolvedValueOnce(mockUpdatedLog);

      await searchLogsService.updateSearchLog(logId, {
        ...updateData,
        log_id: 999, // Should be removed
        search_time: new Date() // Should be removed
      });

      expect(db.search_Log.update).toHaveBeenCalledWith({
        where: { log_id: 1 },
        data: {
          search_query: 'updated search',
          filters_applied: '{"category": "updated"}'
        },
        include: expect.any(Object)
      });
    });

    it('should throw error if database fails', async () => {
      db.search_Log.update.mockRejectedValueOnce(new Error('DB error'));

      await expect(searchLogsService.updateSearchLog(logId, updateData))
        .rejects
        .toThrow('Failed to update search log: DB error');
    });
  });

  describe('deleteSearchLog', () => {
    it('should delete search log successfully', async () => {
      const mockDeletedLog = { log_id: 1 };
      db.search_Log.delete.mockResolvedValueOnce(mockDeletedLog);

      const result = await searchLogsService.deleteSearchLog(1);

      expect(db.search_Log.delete).toHaveBeenCalledWith({
        where: { log_id: 1 }
      });
      expect(result).toEqual(mockDeletedLog);
    });

    it('should handle string logId by converting to integer', async () => {
      const mockDeletedLog = { log_id: 1 };
      db.search_Log.delete.mockResolvedValueOnce(mockDeletedLog);

      await searchLogsService.deleteSearchLog('1');

      expect(db.search_Log.delete).toHaveBeenCalledWith({
        where: { log_id: 1 }
      });
    });

    it('should throw error if database fails', async () => {
      db.search_Log.delete.mockRejectedValueOnce(new Error('DB error'));

      await expect(searchLogsService.deleteSearchLog(1))
        .rejects
        .toThrow('Failed to delete search log: DB error');
    });
  });
});