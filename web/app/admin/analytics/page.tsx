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

interface User {
  role: "admin" | "organizer";
  name: string;
}

const revenueData = [
  { month: "Jan", revenue: 4000, tickets: 120, events: 5 },
  { month: "Feb", revenue: 3000, tickets: 90, events: 4 },
  { month: "Mar", revenue: 5000, tickets: 150, events: 7 },
  { month: "Apr", revenue: 4500, tickets: 135, events: 6 },
  { month: "May", revenue: 6000, tickets: 180, events: 8 },
  { month: "Jun", revenue: 5500, tickets: 165, events: 7 },
];

const categoryData = [
  { name: "Conferences", value: 35, color: "#8884d8" },
  { name: "Workshops", value: 25, color: "#82ca9d" },
  { name: "Concerts", value: 20, color: "#ffc658" },
  { name: "Sports", value: 15, color: "#ff7300" },
  { name: "Others", value: 5, color: "#00ff00" },
];

const attendeeData = [
  { day: "Mon", attendees: 120 },
  { day: "Tue", attendees: 150 },
  { day: "Wed", attendees: 180 },
  { day: "Thu", attendees: 200 },
  { day: "Fri", attendees: 250 },
  { day: "Sat", attendees: 300 },
  { day: "Sun", attendees: 280 },
];

const topEvents = [
  { name: "Tech Summit 2024", attendees: 500, revenue: 25000, conversion: 85 },
  { name: "Music Festival", revenue: 45000, attendees: 800, conversion: 92 },
  { name: "Business Workshop", attendees: 150, revenue: 7500, conversion: 78 },
  { name: "Art Exhibition", attendees: 200, revenue: 10000, conversion: 65 },
  { name: "Sports Tournament", attendees: 350, revenue: 17500, conversion: 88 },
];

export default function AnalyticsPage() {
  const [user, setUser] = useState<User | null>(null);
  const [timeRange, setTimeRange] = useState("6months");

  useEffect(() => {
    const userData = localStorage.getItem("user");
    if (userData) {
      setUser(JSON.parse(userData));
    }
  }, []);

  const isAdmin = user?.role === "admin";

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
                <div className="text-2xl font-bold">$28,000</div>
                <div className="flex items-center text-xs text-green-600">
                  <TrendingUp className="h-3 w-3 mr-1" />
                  +12.5% from last period
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
                <div className="text-2xl font-bold">840</div>
                <div className="flex items-center text-xs text-green-600">
                  <TrendingUp className="h-3 w-3 mr-1" />
                  +8.2% from last period
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
                <div className="text-2xl font-bold">82.4%</div>
                <div className="flex items-center text-xs text-red-600">
                  <TrendingDown className="h-3 w-3 mr-1" />
                  -2.1% from last period
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
                <div className="text-2xl font-bold">12,450</div>
                <div className="flex items-center text-xs text-green-600">
                  <TrendingUp className="h-3 w-3 mr-1" />
                  +15.3% from last period
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
                          `${name} ${(percent * 100).toFixed(0)}%`
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
                  {topEvents.map((event, index) => (
                    <div
                      key={index}
                      className="flex items-center justify-between p-3 border rounded-lg"
                    >
                      <div className="flex-1">
                        <h4 className="font-medium text-sm">{event.name}</h4>
                        <div className="flex items-center space-x-4 mt-1">
                          <span className="text-xs text-gray-600">
                            {event.attendees} attendees
                          </span>
                          <span className="text-xs text-gray-600">
                            ${event.revenue.toLocaleString()}
                          </span>
                        </div>
                      </div>
                      <div className="text-right">
                        <Badge
                          variant={
                            event.conversion >= 80 ? "default" : "secondary"
                          }
                        >
                          {event.conversion}% conversion
                        </Badge>
                      </div>
                    </div>
                  ))}
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
                      Revenue Growth
                    </h4>
                  </div>
                  <p className="text-sm text-green-700">
                    Revenue increased by 12.5% compared to last period. Weekend
                    events show higher conversion rates.
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
                    Tech conferences have the highest attendance rates. Consider
                    expanding this category.
                  </p>
                </div>

                <div className="p-4 bg-orange-50 border border-orange-200 rounded-lg">
                  <div className="flex items-center mb-2">
                    <Target className="h-5 w-5 text-orange-600 mr-2" />
                    <h4 className="font-medium text-orange-800">
                      Optimization
                    </h4>
                  </div>
                  <p className="text-sm text-orange-700">
                    Conversion rate dropped slightly. Consider improving event
                    descriptions and early bird pricing.
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
