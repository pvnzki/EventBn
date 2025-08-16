const prisma = require('../../../lib/database');

module.exports = {
  // Get all analytics
  async getAllAnalytics() {
    try {
      return await prisma.monthlyAnalytics.findMany({
        orderBy: [{ year: 'desc' }, { month: 'desc' }]
      });
    } catch (error) {
      throw new Error(`Failed to fetch analytics: ${error.message}`);
    }
  },

  // Get analytics by year
  async getAnalyticsByYear(year) {
    try {
      return await prisma.monthly_analytics.findMany({
        where: { year: parseInt(year) },
        orderBy: { month: 'asc' }
      });
    } catch (error) {
      throw new Error(`Failed to fetch analytics by year: ${error.message}`);
    }
  },

  // Get analytics by year + month
  async getAnalyticsByMonth(year, month) {
    try {
      return await prisma.monthly_analytics.findUnique({
        where: {
          year_month: {
            year: parseInt(year),
            month: parseInt(month),
          }
        }
      });
    } catch (error) {
      throw new Error(`Failed to fetch analytics by month: ${error.message}`);
    }
  },

  // Create analytics record
  async createAnalytics(data) {
    try {
      return await prisma.monthly_analytics.create({
        data
      });
    } catch (error) {
      throw new Error(`Failed to create analytics: ${error.message}`);
    }
  },

  // Update analytics record
  async updateAnalytics(id, data) {
    try {
      return await prisma.monthly_analytics.update({
        where: { id: parseInt(id) },
        data
      });
    } catch (error) {
      throw new Error(`Failed to update analytics: ${error.message}`);
    }
  },

  // Delete analytics record
  async deleteAnalytics(id) {
    try {
      return await prisma.monthly_analytics.delete({
        where: { id: parseInt(id) }
      });
    } catch (error) {
      throw new Error(`Failed to delete analytics: ${error.message}`);
    }
  }
};
