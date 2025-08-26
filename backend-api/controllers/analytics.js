const analyticsService = require('../services/core-service/analytics');

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
  }
};