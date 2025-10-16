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
import { useAnalytics } from "@/hooks/use-analytics";
import { useAdminAnalytics } from "@/hooks/use-admin-analytics";

interface User {
  role: "admin" | "organizer";
  name: string;
}

export default function AnalyticsPage() {
  const [user, setUser] = useState<User | null>(null);
  const [timeRange, setTimeRange] = useState("6months");

  useEffect(() => {
    const userData = localStorage.getItem("user");
    if (userData) {
      setUser(JSON.parse(userData));
    }
  }, []);

  // Only fetch analytics if user is loaded and is admin
  const isAdmin = user?.role === "admin";
  // Mirror organizer analytics flow: wait for user, require admin, then fetch platform-wide analytics
  // IMPORTANT: hooks must be called unconditionally — call the admin analytics hook here even if user is null
  const {
    overview,
    revenueData,
    categoryData,
    attendeeData,
    topEvents,
    loading,
    error,
    refetch,
  } = useAdminAnalytics(!!isAdmin, timeRange);

  if (user && !isAdmin) {
    return (
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <div className="flex-1 lg:ml-64 p-8">
          <div className="max-w-2xl mx-auto text-center">
            <h2 className="text-2xl font-semibold">Access denied</h2>
            <p className="mt-2 text-gray-600">
              You must be an admin to view platform analytics.
            </p>
          </div>
        </div>
      </div>
    );
  }

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

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
    }).format(amount);
  };

  const formatNumber = (num: number) => {
    return new Intl.NumberFormat("en-US").format(num);
  };

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
                onClick={refetch}
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
            <Select value={timeRange} onValueChange={setTimeRange}>
              <SelectTrigger className="w-40">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="7days">Last 7 days</SelectItem>
                <SelectItem value="30days">Last 30 days</SelectItem>
                <SelectItem value="3months">Last 3 months</SelectItem>
                <SelectItem value="6months">Last 6 months</SelectItem>
                <SelectItem value="1year">Last year</SelectItem>
              </SelectContent>
            </Select>
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
                  {overview
                    ? formatCurrency(overview.totalRevenue)
                    : "No revenue yet"}
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
                  {overview
                    ? formatNumber(overview.ticketsSold)
                    : "No tickets sold"}
                </div>
                <div className="flex items-center text-xs text-green-600">
                  <TrendingUp className="h-3 w-3 mr-1" />
                  {overview
                    ? `Across ${overview.totalEvents} events`
                    : "No events found"}
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
                  {overview
                    ? `${overview.conversionRate.toFixed(1)}%`
                    : "No conversion yet"}
                </div>
                <div className="flex items-center text-xs text-gray-600">
                  <Target className="h-3 w-3 mr-1" />
                  Tickets per event
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  Page Views
                </CardTitle>
                <Eye className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {overview
                    ? formatNumber(overview.totalAttendees)
                    : "No attendees yet"}
                </div>
                <div className="flex items-center text-xs text-green-600">
                  <TrendingUp className="h-3 w-3 mr-1" />
                  Attendees tracked
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
                  <ChartContainer config={{}} className="h-[300px]">
                    <ResponsiveContainer width="100%" height="100%">
                      <PieChart>
                        <Pie
                          data={categoryData.map((cat) => ({
                            name: cat.name || cat.category,
                            value: cat.value ?? cat.count,
                            color: cat.color,
                          }))}
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
                  <ChartContainer config={{}} className="h-[300px]">
                    <ResponsiveContainer width="100%" height="100%">
                      <BarChart
                        data={attendeeData.map((a) => ({
                          day: a.day ?? a.date,
                          attendees: a.attendees ?? a.count,
                        }))}
                      >
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
                      No event data available yet
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
                    {overview
                      ? `Total revenue of ${formatCurrency(
                          overview.totalRevenue
                        )} across ${overview.totalEvents} events.`
                      : "No revenue data available yet. Start by creating events and processing payments."}
                  </p>
                </div>

                <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                  <div className="flex items-center mb-2">
                    <Users className="h-5 w-5 text-blue-600 mr-2" />
                    <h4 className="font-medium text-blue-800">
                      Audience Engagement
                    </h4>
                  </div>
                  <p className="text-sm text-blue-700">
                    {overview
                      ? `${formatNumber(
                          overview.ticketsSold
                        )} tickets sold with ${overview.conversionRate.toFixed(
                          1
                        )} tickets per event on average.`
                      : "No ticket sales data available yet."}
                  </p>
                </div>

                <div className="p-4 bg-orange-50 border border-orange-200 rounded-lg">
                  <div className="flex items-center mb-2">
                    <Target className="h-5 w-5 text-orange-600 mr-2" />
                    <h4 className="font-medium text-orange-800">
                      Category Insights
                    </h4>
                  </div>
                  <p className="text-sm text-orange-700">
                    {categoryData.length > 0
                      ? `${
                          categoryData[0]?.name || "Unknown"
                        } is your top category with ${
                          categoryData[0]?.value || 0
                        }% of events.`
                      : "No category data available. Add categories to your events for better insights."}
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
          {/* Debug: raw data (temporary) */}
          <Card className="mt-6">
            <CardHeader>
              <CardTitle>Debug: Raw Analytics JSON</CardTitle>
              <CardDescription>
                Temporary - remove in production
              </CardDescription>
            </CardHeader>
            <CardContent>
              <pre className="text-xs overflow-auto max-h-64">
                {JSON.stringify(
                  {
                    overview,
                    revenueData,
                    categoryData,
                    attendeeData,
                    topEvents,
                  },
                  null,
                  2
                )}
              </pre>
            </CardContent>
          </Card>
          <Card className="mt-4">
            <CardHeader>
              <CardTitle>Debug: User</CardTitle>
            </CardHeader>
            <CardContent>
              <pre className="text-xs">
                {JSON.stringify({ user, isAdmin }, null, 2)}
              </pre>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
