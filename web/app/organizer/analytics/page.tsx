"use client";

import { useState, useEffect } from "react";
import { Sidebar } from "@/components/layout/sidebar";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import {
  TrendingUp,
  TrendingDown,
  Users,
  DollarSign,
  Target,
  Eye,
  ShoppingCart,
  Loader2,
} from "lucide-react";
import {
  Bar,
  BarChart,
  Area,
  AreaChart,
  Pie,
  PieChart,
  Cell,
  ResponsiveContainer,
  XAxis,
  YAxis,
  CartesianGrid,
  Legend,
} from "recharts";
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
} from "@/components/ui/chart";
import { useOrganizerAnalytics } from "@/hooks/use-organizer-analytics";
import { useOrganization } from "@/hooks/use-organization";

interface User {
  role: "admin" | "organizer";
  name: string;
  user_id?: number;
}

export default function AnalyticsPage() {
  const [user, setUser] = useState<User | null>(null);
  // Fixed time range for organizer analytics
  const FIXED_TIME_RANGE = "6months";

  // First fetch organization data using user ID
  const {
    organization,
    loading: orgLoading,
    error: orgError,
    refetch: refetchOrg,
  } = useOrganization(user?.user_id || null);

  // Then fetch analytics using organization ID (fixed time range)
  const {
    overview,
    revenueData,
    categoryData,
    attendeeData,
    topEvents,
    loading: analyticsLoading,
    error: analyticsError,
    refetch: refetchAnalytics,
  } = useOrganizerAnalytics(
    organization?.organization_id || 0,
    FIXED_TIME_RANGE
  );

  useEffect(() => {
    const userData = localStorage.getItem("user");
    if (userData) {
      const parsedUser = JSON.parse(userData);
      setUser(parsedUser);
    }
  }, []);

  const isAdmin = user?.role === "admin";
  const loading = orgLoading || analyticsLoading;
  const error = orgError || analyticsError;

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
    }).format(amount);
  };

  const formatNumber = (num: number) => {
    return new Intl.NumberFormat("en-US").format(num);
  };

  if (!user) {
    return (
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <div className="flex-1 lg:ml-64">
          <div className="flex items-center justify-center h-full">
            <div className="flex items-center space-x-2">
              <Loader2 className="h-6 w-6 animate-spin" />
              <span>Loading user data...</span>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (!organization) {
    return (
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <div className="flex-1 lg:ml-64">
          <div className="flex items-center justify-center h-full">
            <div className="text-center">
              <h2 className="text-xl font-semibold text-red-600 mb-2">
                No Organization Found
              </h2>
              <p className="text-gray-600 mb-4">
                You need to have an organization to view analytics. Please
                create an organization first.
              </p>
              <button
                onClick={refetchOrg}
                className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
              >
                Retry
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <div className="flex-1 lg:ml-64">
          <div className="flex items-center justify-center h-full">
            <div className="flex items-center space-x-2">
              <Loader2 className="h-6 w-6 animate-spin" />
              <span>Loading analytics...</span>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <div className="flex-1 lg:ml-64">
          <div className="flex items-center justify-center h-full">
            <div className="text-center">
              <h2 className="text-xl font-semibold text-red-600 mb-2">
                Error Loading Analytics
              </h2>
              <p className="text-gray-600 mb-4">{error}</p>
              <button
                onClick={() => {
                  refetchOrg();
                  refetchAnalytics();
                }}
                className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
              >
                Try Again
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />

      <div className="flex-1 lg:ml-64">
        <div className="p-6 lg:p-8">
          {/* Header */}
          <div className="flex justify-between items-center mb-8">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">
                Analytics Dashboard
              </h1>
              <p className="text-gray-600 mt-2">
                {isAdmin
                  ? "Platform-wide analytics and insights"
                  : "Your event performance and insights"}
              </p>
            </div>
            {/* Time range selection removed for organizers; using fixed 6 months */}
          </div>

          {/* Key Metrics */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  Total Revenue
                </CardTitle>
                <DollarSign className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {overview ? formatCurrency(overview.totalRevenue) : "$0"}
                </div>
                <div className="flex items-center text-xs text-green-600">
                  <TrendingUp className="h-3 w-3 mr-1" />
                  {overview?.revenueGrowth
                    ? `${
                        overview.revenueGrowth > 0 ? "+" : ""
                      }${overview.revenueGrowth.toFixed(1)}% growth`
                    : "No growth data"}
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  Tickets Sold
                </CardTitle>
                <ShoppingCart className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {overview ? formatNumber(overview.ticketsSold) : "0"}
                </div>
                <div className="flex items-center text-xs text-blue-600">
                  <Users className="h-3 w-3 mr-1" />
                  {overview?.totalAttendees || 0} attended (
                  {overview?.attendanceRate?.toFixed(1) || 0}%)
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  Conversion Rate
                </CardTitle>
                <Target className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {overview ? `${overview.conversionRate.toFixed(1)}%` : "0%"}
                </div>
                <div className="flex items-center text-xs text-gray-600">
                  <Target className="h-3 w-3 mr-1" />
                  Average: ${overview?.avgTicketPrice?.toFixed(2) || "0"} per
                  ticket
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  Total Events
                </CardTitle>
                <Eye className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {overview ? formatNumber(overview.totalEvents) : "0"}
                </div>
                <div className="flex items-center text-xs text-green-600">
                  <TrendingUp className="h-3 w-3 mr-1" />
                  Active events created
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Charts Row 1 */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
            <Card>
              <CardHeader>
                <CardTitle>Revenue Trend</CardTitle>
                <CardDescription>
                  Monthly revenue, tickets sold, and events
                </CardDescription>
              </CardHeader>
              <CardContent>
                {revenueData.length > 0 ? (
                  <ChartContainer
                    config={{
                      revenue: {
                        label: "Revenue",
                        color: "hsl(var(--chart-1))",
                      },
                      tickets: {
                        label: "Tickets",
                        color: "hsl(var(--chart-2))",
                      },
                    }}
                    className="h-[300px]"
                  >
                    <ResponsiveContainer width="100%" height="100%">
                      <AreaChart data={revenueData}>
                        <CartesianGrid strokeDasharray="3 3" />
                        <XAxis dataKey="month" />
                        <YAxis />
                        <ChartTooltip content={<ChartTooltipContent />} />
                        <Legend />
                        <Area
                          type="monotone"
                          dataKey="revenue"
                          stackId="1"
                          stroke="var(--color-revenue)"
                          fill="var(--color-revenue)"
                          name="Revenue ($)"
                        />
                        <Area
                          type="monotone"
                          dataKey="tickets"
                          stackId="2"
                          stroke="var(--color-tickets)"
                          fill="var(--color-tickets)"
                          name="Tickets Sold"
                        />
                      </AreaChart>
                    </ResponsiveContainer>
                  </ChartContainer>
                ) : (
                  <div className="h-[300px] flex items-center justify-center text-gray-500">
                    No revenue data available for the selected period
                  </div>
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Event Categories</CardTitle>
                <CardDescription>
                  Distribution of events by category
                </CardDescription>
              </CardHeader>
              <CardContent>
                {categoryData.length > 0 ? (
                  <ChartContainer
                    config={{
                      conferences: { label: "Conferences", color: "#8884d8" },
                      workshops: { label: "Workshops", color: "#82ca9d" },
                      concerts: { label: "Concerts", color: "#ffc658" },
                      sports: { label: "Sports", color: "#ff7300" },
                      others: { label: "Others", color: "#00ff00" },
                    }}
                    className="h-[300px]"
                  >
                    <ResponsiveContainer width="100%" height="100%">
                      <PieChart>
                        <Pie
                          data={categoryData}
                          cx="50%"
                          cy="50%"
                          outerRadius={80}
                          dataKey="value"
                          label={({ name, percent }) =>
                            `${name} ${((percent ?? 0) * 100).toFixed(0)}%`
                          }
                        >
                          {categoryData.map((entry, index) => (
                            <Cell key={`cell-${index}`} fill={entry.color} />
                          ))}
                        </Pie>
                        <ChartTooltip />
                      </PieChart>
                    </ResponsiveContainer>
                  </ChartContainer>
                ) : (
                  <div className="h-[300px] flex items-center justify-center text-gray-500">
                    No category data available. Add categories to events to see
                    distribution.
                  </div>
                )}
              </CardContent>
            </Card>
          </div>

          {/* Charts Row 2 */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
            <Card>
              <CardHeader>
                <CardTitle>Daily Attendees</CardTitle>
                <CardDescription>
                  Attendee check-ins by day of week
                </CardDescription>
              </CardHeader>
              <CardContent>
                {attendeeData.length > 0 ? (
                  <ChartContainer
                    config={{
                      attendees: {
                        label: "Attendees",
                        color: "hsl(var(--chart-3))",
                      },
                    }}
                    className="h-[300px]"
                  >
                    <ResponsiveContainer width="100%" height="100%">
                      <BarChart data={attendeeData}>
                        <CartesianGrid strokeDasharray="3 3" />
                        <XAxis dataKey="day" />
                        <YAxis />
                        <ChartTooltip content={<ChartTooltipContent />} />
                        <Bar
                          dataKey="attendees"
                          fill="var(--color-attendees)"
                          name="Attendees"
                        />
                      </BarChart>
                    </ResponsiveContainer>
                  </ChartContainer>
                ) : (
                  <div className="h-[300px] flex items-center justify-center text-gray-500">
                    No attendance data available for the last 7 days
                  </div>
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Top Performing Events</CardTitle>
                <CardDescription>
                  Events ranked by revenue and attendance
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {topEvents.length > 0 ? (
                    topEvents.map((event, index) => (
                      <div
                        key={index}
                        className="flex items-center justify-between p-3 border rounded-lg"
                      >
                        <div className="flex-1">
                          <h4 className="font-medium text-sm">{event.name}</h4>
                          <div className="flex items-center space-x-4 mt-1">
                            <span className="text-xs text-gray-600">
                              {formatNumber(event.attendees)} attendees
                            </span>
                            <span className="text-xs text-gray-600">
                              {formatCurrency(event.revenue)}
                            </span>
                          </div>
                        </div>
                        <div className="text-right">
                          <Badge
                            variant={
                              event.conversion >= 80 ? "default" : "secondary"
                            }
                          >
                            {event.conversion.toFixed(1)}% conversion
                          </Badge>
                        </div>
                      </div>
                    ))
                  ) : (
                    <div className="text-center py-8 text-gray-500">
                      No event data available yet. Create events and sell
                      tickets to see analytics.
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Performance Insights */}
          <Card>
            <CardHeader>
              <CardTitle>Performance Insights</CardTitle>
              <CardDescription>
                Key insights and recommendations
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
                  <div className="flex items-center mb-2">
                    <TrendingUp className="h-5 w-5 text-green-600 mr-2" />
                    <h4 className="font-medium text-green-800">
                      Revenue Status
                    </h4>
                  </div>
                  <p className="text-sm text-green-700">
                    {overview && overview.totalRevenue > 0
                      ? `Total revenue of ${formatCurrency(
                          overview.totalRevenue
                        )} from ${overview.totalEvents} events.`
                      : "No revenue generated yet. Create events and start selling tickets to see revenue insights."}
                  </p>
                </div>

                <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                  <div className="flex items-center mb-2">
                    <Users className="h-5 w-5 text-blue-600 mr-2" />
                    <h4 className="font-medium text-blue-800">
                      Event Performance
                    </h4>
                  </div>
                  <p className="text-sm text-blue-700">
                    {overview && overview.ticketsSold > 0
                      ? `${formatNumber(
                          overview.ticketsSold
                        )} tickets sold with ${overview.conversionRate.toFixed(
                          1
                        )} tickets per event average.`
                      : "No tickets sold yet. Promote your events to increase sales."}
                  </p>
                </div>

                <div className="p-4 bg-orange-50 border border-orange-200 rounded-lg">
                  <div className="flex items-center mb-2">
                    <Target className="h-5 w-5 text-orange-600 mr-2" />
                    <h4 className="font-medium text-orange-800">
                      Category Focus
                    </h4>
                  </div>
                  <p className="text-sm text-orange-700">
                    {categoryData.length > 0
                      ? `${
                          categoryData[0]?.name || "Unknown"
                        } is your top category with ${
                          categoryData[0]?.value || 0
                        } events.`
                      : "Create events with different categories to see which types perform best."}
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
