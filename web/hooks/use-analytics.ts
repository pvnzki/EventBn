import { useState, useEffect } from 'react';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

export interface DashboardOverview {
  totalRevenue: number;
  ticketsSold: number;
  conversionRate: number;
  totalEvents: number;
  totalAttendees: number;
  avgTicketPrice: number;
  revenueGrowth: number;
  attendeeGrowth: number;
  attendanceRate: number;
  totalCapacity?: number;
  activeEvents?: number;
  currentPeriodTickets?: number;
  currentPeriodRevenue?: number;
}

export interface RevenueData {
  month: string;
  revenue: number;
}

export interface CategoryData {
  category: string;
  count: number;
  name?: string; // For frontend compatibility
  value?: number; // For frontend compatibility
  color?: string;
}

export interface AttendeeData {
  date: string;
  count: number;
  day?: string; // For frontend compatibility
  attendees?: number; // For frontend compatibility
}

export interface TopEvent {
  event_id: number;
  name: string;
  title: string;
  start_time: string;
  venue: string;
  attendees: number;
  ticketsSold: number;
  revenue: number;
  conversion: number;
}

export const useAnalytics = (timeRange: string = '6months', isAdmin: boolean = false, organizerId?: number) => {
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
      let base = `${API_BASE_URL}/api/analytics`;
      let prefix = isAdmin ? '/platform/dashboard' : `/organizer/${organizerId}/dashboard`;
      const [
        overviewRes,
        revenueRes,
        categoriesRes,
        attendeesRes,
        topEventsRes
      ] = await Promise.all([
        fetch(`${base}${prefix}/overview?timeRange=${timeRange}`),
        fetch(`${base}${prefix}/revenue-trend?timeRange=${timeRange}`),
        fetch(`${base}${prefix}/categories`),
        fetch(`${base}${prefix}/daily-attendees`),
        fetch(`${base}${prefix}/top-events?limit=5`)
      ]);
      if (!overviewRes.ok || !revenueRes.ok || !categoriesRes.ok || !attendeesRes.ok || !topEventsRes.ok) {
        throw new Error('Failed to fetch analytics data');
      }
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
  }, [timeRange, isAdmin, organizerId]);

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