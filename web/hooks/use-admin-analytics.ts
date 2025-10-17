import { useState, useEffect } from 'react';
import { DashboardOverview, RevenueData, CategoryData, AttendeeData, TopEvent } from './use-analytics';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

export const useAdminAnalytics = (enabled: boolean, timeRange: string = '6months') => {
  const [overview, setOverview] = useState<DashboardOverview | null>(null);
  const [revenueData, setRevenueData] = useState<RevenueData[]>([]);
  const [categoryData, setCategoryData] = useState<CategoryData[]>([]);
  const [attendeeData, setAttendeeData] = useState<AttendeeData[]>([]);
  const [topEvents, setTopEvents] = useState<TopEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);


  const fetchData = async () => {
    if (!enabled) {
      // If analytics are not enabled for this session (user not admin), ensure we are not left in loading state
      setLoading(false);
      return;
    }
    try {
      setLoading(true);
      setError(null);

      const [overviewRes, revenueRes, categoriesRes, attendeesRes, topEventsRes] = await Promise.all([
        fetch(`${API_BASE_URL}/api/analytics/platform/dashboard/overview?timeRange=${timeRange}`),
        fetch(`${API_BASE_URL}/api/analytics/platform/dashboard/revenue-trend?timeRange=${timeRange}`),
        fetch(`${API_BASE_URL}/api/analytics/platform/dashboard/categories`),
        fetch(`${API_BASE_URL}/api/analytics/platform/dashboard/daily-attendees`),
        fetch(`${API_BASE_URL}/api/analytics/platform/dashboard/top-events?limit=5`)
      ]);

      if (!overviewRes.ok || !revenueRes.ok || !categoriesRes.ok || !attendeesRes.ok || !topEventsRes.ok) {
        throw new Error('Failed to fetch admin analytics data');
      }

      const [overviewData, revenueDataRes, categoriesData, attendeesData, topEventsData] = await Promise.all([
        overviewRes.json(),
        revenueRes.json(),
        categoriesRes.json(),
        attendeesRes.json(),
        topEventsRes.json()
      ]);

      // Debug logging
      try {
        console.debug('Admin analytics raw responses:', {
          overview: overviewData,
          revenue: revenueDataRes,
          categories: categoriesData,
          attendees: attendeesData,
          topEvents: topEventsData,
        });
      } catch (e) {
        // ignore
      }

      if (overviewData.success) setOverview(overviewData.data);
      if (revenueDataRes.success) setRevenueData(revenueDataRes.data);
      if (categoriesData.success) setCategoryData(categoriesData.data);
      if (attendeesData.success) setAttendeeData(attendeesData.data);
      if (topEventsData.success) setTopEvents(topEventsData.data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
      console.error('Admin analytics fetch error:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (enabled) fetchData();
  }, [enabled, timeRange]);

  return { overview, revenueData, categoryData, attendeeData, topEvents, loading, error, refetch: fetchData };
};
