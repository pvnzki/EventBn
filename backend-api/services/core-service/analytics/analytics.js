const analyticsService = require('./index');

module.exports = {
  async getAll(req, res) {
    try {
      const data = await analyticsService.getAllAnalytics();
      res.json({ success: true, data });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  },

  async getByYear(req, res) {
    try {
      const { year } = req.params;
      const data = await analyticsService.getAnalyticsByYear(year);
      res.json({ success: true, data });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  },

  async getByMonth(req, res) {
    try {
      const { year, month } = req.params;
      const data = await analyticsService.getAnalyticsByMonth(year, month);

      if (!data) {
        return res.status(404).json({ success: false, message: "Not found" });
      }

      res.json({ success: true, data });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  },

  async create(req, res) {
    try {
      const newRecord = await analyticsService.createAnalytics(req.body);
      res.status(201).json({ success: true, data: newRecord });
    } catch (error) {
      res.status(400).json({ success: false, message: error.message });
    }
  },

  async update(req, res) {
    try {
      const { id } = req.params;
      const updated = await analyticsService.updateAnalytics(id, req.body);
      res.json({ success: true, data: updated });
    } catch (error) {
      res.status(400).json({ success: false, message: error.message });
    }
  },

  async remove(req, res) {
    try {
      const { id } = req.params;
      await analyticsService.deleteAnalytics(id);
      res.json({ success: true, message: "Deleted successfully" });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  },

  // New dashboard endpoints
  async getDashboardOverview(req, res) {
    try {
      const { timeRange = '6months' } = req.query;
      const data = await analyticsService.getDashboardOverview(timeRange);
      res.json({ success: true, data });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  },

  async getRevenueTrend(req, res) {
    try {
      const { timeRange = '6months' } = req.query;
      const data = await analyticsService.getRevenueTrend(timeRange);
      res.json({ success: true, data });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  },

  async getEventCategories(req, res) {
    try {
      const data = await analyticsService.getEventCategories();
      res.json({ success: true, data });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  },

  async getTopEvents(req, res) {
    try {
      const { limit = 5 } = req.query;
      const data = await analyticsService.getTopEvents(parseInt(limit));
      res.json({ success: true, data });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  },

  async getDailyAttendees(req, res) {
    try {
      const data = await analyticsService.getDailyAttendees();
      res.json({ success: true, data });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  },

  // Organizer-specific endpoints
  async getOrganizerDashboardOverview(req, res) {
    try {
      const { organizationId } = req.params;
      const { timeRange = '6months' } = req.query;
      const data = await analyticsService.getOrganizerDashboardOverview(organizationId, timeRange);
      res.json({ success: true, data });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  },

  async getOrganizerRevenueTrend(req, res) {
    try {
      const { organizationId } = req.params;
      const { timeRange = '6months' } = req.query;
      const data = await analyticsService.getOrganizerRevenueTrend(organizationId, timeRange);
      res.json({ success: true, data });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  },

  async getOrganizerEventCategories(req, res) {
    try {
      const { organizationId } = req.params;
      const data = await analyticsService.getOrganizerEventCategories(organizationId);
      res.json({ success: true, data });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  },

  async getOrganizerTopEvents(req, res) {
    try {
      const { organizationId } = req.params;
      const { limit = 5 } = req.query;
      const data = await analyticsService.getOrganizerTopEvents(organizationId, parseInt(limit));
      res.json({ success: true, data });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  },

  async getOrganizerDailyAttendees(req, res) {
    try {
      const { organizationId } = req.params;
      const data = await analyticsService.getOrganizerDailyAttendees(organizationId);
      res.json({ success: true, data });
    } catch (error) {
      res.status(500).json({ success: false, message: error.message });
    }
  }
};