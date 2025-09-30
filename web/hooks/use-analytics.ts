import { useState, useEffect } from 'react';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

export interface DashboardOverview {
  totalRevenue: number;
  ticketsSold: number;
  conversionRate: number;
  pageViews: number;
  totalPayments: number;
  totalEvents: number;
}

export interface RevenueData {
  month: string;
  revenue: number;
  tickets: number;
  events: number;
}

export interface CategoryData {
  name: string;
  value: number;
  color: string;
}

export interface AttendeeData {
  day: string;
  attendees: number;
}

export interface TopEvent {
  name: string;
  attendees: number;
  revenue: number;
  conversion: number;
}

export const useAnalytics = (timeRange: string = '6months') => {
  const [overview, setOverview] = useState<DashboardOverview | null>(null);
  const [revenueData, setRevenueData] = useState<RevenueData[]>([]);
  const [categoryData, setCategoryData] = useState<CategoryData[]>([]);
  const [attendeeData, setAttendeeData] = useState<AttendeeData[]>([]);
  const [topEvents, setTopEvents] = useState<TopEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = async () => {
    try {
      setLoading(true);
      setError(null);

      // Fetch all analytics data
      const [
        overviewRes,
        revenueRes,
        categoriesRes,
        attendeesRes,
        topEventsRes
      ] = await Promise.all([
        fetch(`${API_BASE_URL}/api/analytics/dashboard/overview?timeRange=${timeRange}`),
        fetch(`${API_BASE_URL}/api/analytics/dashboard/revenue-trend?timeRange=${timeRange}`),
        fetch(`${API_BASE_URL}/api/analytics/dashboard/categories`),
        fetch(`${API_BASE_URL}/api/analytics/dashboard/daily-attendees`),
        fetch(`${API_BASE_URL}/api/analytics/dashboard/top-events?limit=5`)
      ]);

      // Check if all requests were successful
      if (!overviewRes.ok || !revenueRes.ok || !categoriesRes.ok || !attendeesRes.ok || !topEventsRes.ok) {
        throw new Error('Failed to fetch analytics data');
      }

      // Parse responses
      const [
        overviewData,
        revenueData,
        categoriesData,
        attendeesData,
        topEventsData
      ] = await Promise.all([
        overviewRes.json(),
        revenueRes.json(),
        categoriesRes.json(),
        attendeesRes.json(),
        topEventsRes.json()
      ]);

      // Update state
      if (overviewData.success) setOverview(overviewData.data);
      if (revenueData.success) setRevenueData(revenueData.data);
      if (categoriesData.success) setCategoryData(categoriesData.data);
      if (attendeesData.success) setAttendeeData(attendeesData.data);
      if (topEventsData.success) setTopEvents(topEventsData.data);

    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
      console.error('Analytics fetch error:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [timeRange]);

  const refetch = () => {
    fetchData();
  };

  return {
    overview,
    revenueData,
    categoryData,
    attendeeData,
    topEvents,
    loading,
    error,
    refetch
  };
};

// Hook for individual analytics endpoints
export const useAnalyticsEndpoint = <T>(endpoint: string, timeRange?: string) => {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = async () => {
    try {
      setLoading(true);
      setError(null);

      const url = timeRange 
        ? `${API_BASE_URL}/api/analytics/${endpoint}?timeRange=${timeRange}`
        : `${API_BASE_URL}/api/analytics/${endpoint}`;

      const response = await fetch(url);
      
      if (!response.ok) {
        throw new Error(`Failed to fetch ${endpoint}`);
      }

      const result = await response.json();
      
      if (result.success) {
        setData(result.data);
      } else {
        throw new Error(result.message || 'Failed to fetch data');
      }

    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
      console.error(`${endpoint} fetch error:`, err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [endpoint, timeRange]);

  const refetch = () => {
    fetchData();
  };

  return { data, loading, error, refetch };
};