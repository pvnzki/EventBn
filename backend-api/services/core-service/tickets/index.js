// Search Logs module
const prisma = require('../../../lib/database');

module.exports = {
  // Create new search log
  async createSearchLog(data) {
    try {
      return await prisma.search_Log.create({
        data: {
          user_id: data.user_id ? parseInt(data.user_id) : null,
          search_query: data.search_query,
          search_time: data.search_time ? new Date(data.search_time) : new Date(),
          filters_applied: data.filters_applied || null
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
    } catch (error) {
      throw new Error(`Failed to create search log: ${error.message}`);
    }
  },

  // Get all search logs with optional filtering
  async getAllSearchLogs(filters = {}) {
    try {
      const where = {};
      
      if (filters.user_id) {
        where.user_id = parseInt(filters.user_id);
      }
      
      if (filters.search_query) {
        where.search_query = { contains: filters.search_query, mode: 'insensitive' };
      }
      
      if (filters.start_date) {
        where.search_time = { gte: new Date(filters.start_date) };
      }
      
      if (filters.end_date) {
        where.search_time = { 
          ...where.search_time,
          lte: new Date(filters.end_date) 
        };
      }

      return await prisma.search_Log.findMany({
        where,
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
    } catch (error) {
      throw new Error(`Failed to fetch search logs: ${error.message}`);
    }
  },

  // Get search log by ID
  async getSearchLogById(id) {
    try {
      return await prisma.search_Log.findUnique({
        where: { log_id: parseInt(id) },
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
    } catch (error) {
      throw new Error(`Failed to fetch search log: ${error.message}`);
    }
  },

  // Get user's search history
  async getUserSearchHistory(userId, limit = 50) {
    try {
      return await prisma.search_Log.findMany({
        where: { user_id: parseInt(userId) },
        orderBy: { search_time: 'desc' },
        take: limit
      });
    } catch (error) {
      throw new Error(`Failed to fetch user search history: ${error.message}`);
    }
  },

  // Get popular search queries
  async getPopularSearchQueries(limit = 10, days = 30) {
    try {
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - days);

      const result = await prisma.search_Log.groupBy({
        by: ['search_query'],
        where: {
          search_time: { gte: startDate }
        },
        _count: {
          search_query: true
        },
        orderBy: {
          _count: {
            search_query: 'desc'
          }
        },
        take: limit
      });

      return result.map(item => ({
        query: item.search_query,
        count: item._count.search_query
      }));
    } catch (error) {
      throw new Error(`Failed to fetch popular search queries: ${error.message}`);
    }
  },

  // Get search analytics
  async getSearchAnalytics(days = 30) {
    try {
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - days);

      const totalSearches = await prisma.search_Log.count({
        where: {
          search_time: { gte: startDate }
        }
      });

      const uniqueUsers = await prisma.search_Log.findMany({
        where: {
          search_time: { gte: startDate },
          user_id: { not: null }
        },
        distinct: ['user_id'],
        select: { user_id: true }
      });

      const searchesByDay = await prisma.search_Log.groupBy({
        by: ['search_time'],
        where: {
          search_time: { gte: startDate }
        },
        _count: {
          log_id: true
        }
      });

      return {
        totalSearches,
        uniqueUsers: uniqueUsers.length,
        searchesByDay: searchesByDay.map(item => ({
          date: item.search_time,
          count: item._count.log_id
        }))
      };
    } catch (error) {
      throw new Error(`Failed to fetch search analytics: ${error.message}`);
    }
  },

  // Delete old search logs
  async cleanupOldSearchLogs(daysToKeep = 90) {
    try {
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - daysToKeep);

      const result = await prisma.search_Log.deleteMany({
        where: {
          search_time: { lt: cutoffDate }
        }
      });

      return { deletedCount: result.count };
    } catch (error) {
      throw new Error(`Failed to cleanup old search logs: ${error.message}`);
    }
  },

  // Update search log
  async updateSearchLog(id, data) {
    try {
      const updateData = { ...data };
      delete updateData.log_id;
      delete updateData.search_time;
      
      if (updateData.user_id) {
        updateData.user_id = parseInt(updateData.user_id);
      }

      return await prisma.search_Log.update({
        where: { log_id: parseInt(id) },
        data: updateData,
        include: {
          user: {
            select: {
              user_id: true,
              name: true
            }
          }
        }
      });
    } catch (error) {
      throw new Error(`Failed to update search log: ${error.message}`);
    }
  },

  // Delete search log
  async deleteSearchLog(id) {
    try {
      return await prisma.search_Log.delete({
        where: { log_id: parseInt(id) }
      });
    } catch (error) {
      throw new Error(`Failed to delete search log: ${error.message}`);
    }
  }
};
