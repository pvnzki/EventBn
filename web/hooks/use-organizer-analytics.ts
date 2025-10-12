import { useState, useEffect } from 'react';
import { DashboardOverview, RevenueData, CategoryData, AttendeeData, TopEvent } from './use-analytics';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

export const useOrganizerAnalytics = (organizationId: number | string, timeRange: string = '6months') => {
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

      if (!organizationId || organizationId === 0) {
        // Don't throw an error, just set empty data
        setOverview(null);
        setRevenueData([]);
        setCategoryData([]);
        setAttendeeData([]);
        setTopEvents([]);
        setLoading(false);
        return;
      }

      // Fetch all organizer analytics data
      const [
        overviewRes,
        revenueRes,
        categoriesRes,
        attendeesRes,
        topEventsRes
      ] = await Promise.all([
        fetch(`${API_BASE_URL}/api/analytics/organizer/${organizationId}/dashboard/overview?timeRange=${timeRange}`),
        fetch(`${API_BASE_URL}/api/analytics/organizer/${organizationId}/dashboard/revenue-trend?timeRange=${timeRange}`),
        fetch(`${API_BASE_URL}/api/analytics/organizer/${organizationId}/dashboard/categories`),
        fetch(`${API_BASE_URL}/api/analytics/organizer/${organizationId}/dashboard/daily-attendees`),
        fetch(`${API_BASE_URL}/api/analytics/organizer/${organizationId}/dashboard/top-events?limit=5`)
      ]);

      // Check if all requests were successful
      if (!overviewRes.ok || !revenueRes.ok || !categoriesRes.ok || !attendeesRes.ok || !topEventsRes.ok) {
        throw new Error('Failed to fetch organizer analytics data');
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
      console.error('Organizer analytics fetch error:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (organizationId) {
      fetchData();
    }
  }, [organizationId, timeRange]);

  const refetch = () => {
    if (organizationId) {
      fetchData();
    }
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

// Hook for individual organizer analytics endpoints
export const useOrganizerAnalyticsEndpoint = <T>(
  organizationId: number | string, 
  endpoint: string, 
  timeRange?: string
) => {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = async () => {
    try {
      setLoading(true);
      setError(null);

      if (!organizationId) {
        throw new Error('Organization ID is required');
      }

      const url = timeRange 
        ? `${API_BASE_URL}/api/analytics/organizer/${organizationId}/${endpoint}?timeRange=${timeRange}`
        : `${API_BASE_URL}/api/analytics/organizer/${organizationId}/${endpoint}`;

      const response = await fetch(url);
      
      if (!response.ok) {
        throw new Error(`Failed to fetch organizer ${endpoint}`);
      }

      const result = await response.json();
      
      if (result.success) {
        setData(result.data);
      } else {
        throw new Error(result.message || 'Failed to fetch data');
      }

    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
      console.error(`Organizer ${endpoint} fetch error:`, err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (organizationId) {
      fetchData();
    }
  }, [organizationId, endpoint, timeRange]);

  const refetch = () => {
    if (organizationId) {
      fetchData();
    }
  };

  return { data, loading, error, refetch };
};