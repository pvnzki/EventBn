const analyticsController = require('../controllers/analytics');
const analyticsService = require('../services/core-service/analytics');

// Mock the analytics service
jest.mock('../services/core-service/analytics', () => ({
  getAllAnalytics: jest.fn(),
  getAnalyticsByYear: jest.fn(),
  getAnalyticsByMonth: jest.fn(),
  createAnalytics: jest.fn(),
  updateAnalytics: jest.fn(),
  deleteAnalytics: jest.fn(),
}));

describe('Analytics Controller', () => {
  let req, res;

  beforeEach(() => {
    jest.clearAllMocks();
    
    // Mock request object
    req = {
      params: {},
      body: {}
    };

    // Mock response object
    res = {
      json: jest.fn().mockReturnThis(),
      status: jest.fn().mockReturnThis()
    };
  });

  describe('getAll', () => {
    const mockAnalyticsData = [
      {
        analytics_id: 1,
        event_id: 1,
        year: 2024,
        month: 1,
        total_registrations: 100,
        total_revenue: 5000.00
      },
      {
        analytics_id: 2,
        event_id: 2,
        year: 2024,
        month: 2,
        total_registrations: 150,
        total_revenue: 7500.00
      }
    ];

    it('should return all analytics data successfully', async () => {
      analyticsService.getAllAnalytics.mockResolvedValueOnce(mockAnalyticsData);

      await analyticsController.getAll(req, res);

      expect(analyticsService.getAllAnalytics).toHaveBeenCalledTimes(1);
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        data: mockAnalyticsData
      });
      expect(res.status).not.toHaveBeenCalled();
    });

    it('should handle service errors and return 500 status', async () => {
      const errorMessage = 'Database connection failed';
      analyticsService.getAllAnalytics.mockRejectedValueOnce(new Error(errorMessage));

      await analyticsController.getAll(req, res);

      expect(analyticsService.getAllAnalytics).toHaveBeenCalledTimes(1);
      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: errorMessage
      });
    });

    it('should handle empty analytics data', async () => {
      analyticsService.getAllAnalytics.mockResolvedValueOnce([]);

      await analyticsController.getAll(req, res);

      expect(res.json).toHaveBeenCalledWith({
        success: true,
        data: []
      });
    });
  });

  describe('getByYear', () => {
    const mockYearData = [
      {
        analytics_id: 1,
        year: 2024,
        total_registrations: 250,
        total_revenue: 12500.00
      }
    ];

    it('should return analytics data for specific year', async () => {
      req.params.year = '2024';
      analyticsService.getAnalyticsByYear.mockResolvedValueOnce(mockYearData);

      await analyticsController.getByYear(req, res);

      expect(analyticsService.getAnalyticsByYear).toHaveBeenCalledWith('2024');
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        data: mockYearData
      });
    });

    it('should handle service errors and return 500 status', async () => {
      req.params.year = '2024';
      const errorMessage = 'Invalid year parameter';
      analyticsService.getAnalyticsByYear.mockRejectedValueOnce(new Error(errorMessage));

      await analyticsController.getByYear(req, res);

      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: errorMessage
      });
    });

    it('should handle missing year parameter', async () => {
      req.params = {}; // No year parameter
      analyticsService.getAnalyticsByYear.mockResolvedValueOnce([]);

      await analyticsController.getByYear(req, res);

      expect(analyticsService.getAnalyticsByYear).toHaveBeenCalledWith(undefined);
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        data: []
      });
    });
  });

  describe('getByMonth', () => {
    const mockMonthData = {
      analytics_id: 1,
      year: 2024,
      month: 3,
      total_registrations: 75,
      total_revenue: 3750.00
    };

    it('should return analytics data for specific year and month', async () => {
      req.params = { year: '2024', month: '3' };
      analyticsService.getAnalyticsByMonth.mockResolvedValueOnce(mockMonthData);

      await analyticsController.getByMonth(req, res);

      expect(analyticsService.getAnalyticsByMonth).toHaveBeenCalledWith('2024', '3');
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        data: mockMonthData
      });
    });

    it('should return 404 when no data found', async () => {
      req.params = { year: '2024', month: '13' };
      analyticsService.getAnalyticsByMonth.mockResolvedValueOnce(null);

      await analyticsController.getByMonth(req, res);

      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: "Not found"
      });
    });

    it('should handle service errors and return 500 status', async () => {
      req.params = { year: '2024', month: '3' };
      const errorMessage = 'Invalid month parameter';
      analyticsService.getAnalyticsByMonth.mockRejectedValueOnce(new Error(errorMessage));

      await analyticsController.getByMonth(req, res);

      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: errorMessage
      });
    });

    it('should handle missing parameters', async () => {
      req.params = {}; // No year or month
      analyticsService.getAnalyticsByMonth.mockResolvedValueOnce(null);

      await analyticsController.getByMonth(req, res);

      expect(analyticsService.getAnalyticsByMonth).toHaveBeenCalledWith(undefined, undefined);
      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: "Not found"
      });
    });
  });

  describe('create', () => {
    const newAnalyticsData = {
      event_id: 1,
      year: 2024,
      month: 4,
      total_registrations: 50,
      total_revenue: 2500.00
    };

    const createdAnalytics = {
      analytics_id: 3,
      ...newAnalyticsData,
      created_at: new Date(),
      updated_at: new Date()
    };

    it('should create new analytics record successfully', async () => {
      req.body = newAnalyticsData;
      analyticsService.createAnalytics.mockResolvedValueOnce(createdAnalytics);

      await analyticsController.create(req, res);

      expect(analyticsService.createAnalytics).toHaveBeenCalledWith(newAnalyticsData);
      expect(res.status).toHaveBeenCalledWith(201);
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        data: createdAnalytics
      });
    });

    it('should handle validation errors and return 400 status', async () => {
      req.body = { invalid: 'data' };
      const errorMessage = 'Missing required fields';
      analyticsService.createAnalytics.mockRejectedValueOnce(new Error(errorMessage));

      await analyticsController.create(req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: errorMessage
      });
    });

    it('should handle empty request body', async () => {
      req.body = {};
      const errorMessage = 'Request body is empty';
      analyticsService.createAnalytics.mockRejectedValueOnce(new Error(errorMessage));

      await analyticsController.create(req, res);

      expect(analyticsService.createAnalytics).toHaveBeenCalledWith({});
      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: errorMessage
      });
    });
  });

  describe('update', () => {
    const updateData = {
      total_registrations: 80,
      total_revenue: 4000.00
    };

    const updatedAnalytics = {
      analytics_id: 1,
      event_id: 1,
      year: 2024,
      month: 1,
      ...updateData,
      updated_at: new Date()
    };

    it('should update analytics record successfully', async () => {
      req.params.id = '1';
      req.body = updateData;
      analyticsService.updateAnalytics.mockResolvedValueOnce(updatedAnalytics);

      await analyticsController.update(req, res);

      expect(analyticsService.updateAnalytics).toHaveBeenCalledWith('1', updateData);
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        data: updatedAnalytics
      });
      expect(res.status).not.toHaveBeenCalled();
    });

    it('should handle update errors and return 400 status', async () => {
      req.params.id = '999';
      req.body = updateData;
      const errorMessage = 'Analytics record not found';
      analyticsService.updateAnalytics.mockRejectedValueOnce(new Error(errorMessage));

      await analyticsController.update(req, res);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: errorMessage
      });
    });

    it('should handle missing ID parameter', async () => {
      req.params = {}; // No ID
      req.body = updateData;
      const errorMessage = 'Invalid ID parameter';
      analyticsService.updateAnalytics.mockRejectedValueOnce(new Error(errorMessage));

      await analyticsController.update(req, res);

      expect(analyticsService.updateAnalytics).toHaveBeenCalledWith(undefined, updateData);
      expect(res.status).toHaveBeenCalledWith(400);
    });

    it('should handle empty update data', async () => {
      req.params.id = '1';
      req.body = {};
      analyticsService.updateAnalytics.mockResolvedValueOnce(updatedAnalytics);

      await analyticsController.update(req, res);

      expect(analyticsService.updateAnalytics).toHaveBeenCalledWith('1', {});
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        data: updatedAnalytics
      });
    });
  });

  describe('remove', () => {
    it('should delete analytics record successfully', async () => {
      req.params.id = '1';
      analyticsService.deleteAnalytics.mockResolvedValueOnce();

      await analyticsController.remove(req, res);

      expect(analyticsService.deleteAnalytics).toHaveBeenCalledWith('1');
      expect(res.json).toHaveBeenCalledWith({
        success: true,
        message: "Deleted successfully"
      });
      expect(res.status).not.toHaveBeenCalled();
    });

    it('should handle deletion errors and return 500 status', async () => {
      req.params.id = '999';
      const errorMessage = 'Analytics record not found';
      analyticsService.deleteAnalytics.mockRejectedValueOnce(new Error(errorMessage));

      await analyticsController.remove(req, res);

      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: errorMessage
      });
    });

    it('should handle missing ID parameter', async () => {
      req.params = {}; // No ID
      const errorMessage = 'Invalid ID parameter';
      analyticsService.deleteAnalytics.mockRejectedValueOnce(new Error(errorMessage));

      await analyticsController.remove(req, res);

      expect(analyticsService.deleteAnalytics).toHaveBeenCalledWith(undefined);
      expect(res.status).toHaveBeenCalledWith(500);
    });

    it('should handle database constraint errors', async () => {
      req.params.id = '1';
      const errorMessage = 'Cannot delete: record has dependencies';
      analyticsService.deleteAnalytics.mockRejectedValueOnce(new Error(errorMessage));

      await analyticsController.remove(req, res);

      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        message: errorMessage
      });
    });
  });
});