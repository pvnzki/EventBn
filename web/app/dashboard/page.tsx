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
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Calendar,
  Users,
  DollarSign,
  TrendingUp,
  Eye,
  Edit,
  Trash2,
} from "lucide-react";
import {
  Bar,
  BarChart,
  Line,
  LineChart,
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

const salesData = [
  { month: "Jan", sales: 4000, events: 12 },
  { month: "Feb", sales: 3000, events: 8 },
  { month: "Mar", sales: 5000, events: 15 },
  { month: "Apr", sales: 4500, events: 11 },
  { month: "May", sales: 6000, events: 18 },
  { month: "Jun", sales: 5500, events: 16 },
];

const recentEvents = [
  {
    id: 1,
    name: "Tech Conference 2024",
    date: "2024-03-15",
    status: "active",
    attendees: 250,
    revenue: 12500,
  },
  {
    id: 2,
    name: "Music Festival",
    date: "2024-03-20",
    status: "sold-out",
    attendees: 500,
    revenue: 25000,
  },
  {
    id: 3,
    name: "Business Workshop",
    date: "2024-03-25",
    status: "active",
    attendees: 80,
    revenue: 4000,
  },
  {
    id: 4,
    name: "Art Exhibition",
    date: "2024-04-01",
    status: "draft",
    attendees: 0,
    revenue: 0,
  },
];

export default function DashboardPage() {
  const [user, setUser] = useState<User | null>(null);

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
          <div className="mb-8">
            <h1 className="text-3xl font-bold text-gray-900">
              {isAdmin ? "Admin Dashboard" : "Organizer Dashboard"}
            </h1>
            <p className="text-gray-600 mt-2">
              {isAdmin
                ? "Overview of all platform activities and metrics"
                : "Manage your events and track performance"}
            </p>
          </div>

          {/* Stats Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {isAdmin ? "Total Events" : "My Events"}
                </CardTitle>
                <Calendar className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {isAdmin ? "1,222" : "12"}
                </div>
                <p className="text-xs text-muted-foreground">
                  +20.1% from last month
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  {isAdmin ? "Total Attendees" : "My Attendees"}
                </CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {isAdmin ? "45,231" : "1,830"}
                </div>
                <p className="text-xs text-muted-foreground">
                  +180.1% from last month
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Revenue</CardTitle>
                <DollarSign className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {isAdmin ? "$573,430" : "$41,500"}
                </div>
                <p className="text-xs text-muted-foreground">
                  +19% from last month
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  Growth Rate
                </CardTitle>
                <TrendingUp className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">+12.5%</div>
                <p className="text-xs text-muted-foreground">
                  +2.1% from last month
                </p>
              </CardContent>
            </Card>
          </div>

          {/* Charts */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
            <Card>
              <CardHeader>
                <CardTitle>Revenue Overview</CardTitle>
                <CardDescription>
                  Monthly revenue and event count
                </CardDescription>
              </CardHeader>
              <CardContent>
                <ChartContainer
                  config={{
                    sales: {
                      label: "Revenue",
                      color: "hsl(var(--chart-1))",
                    },
                    events: {
                      label: "Events",
                      color: "hsl(var(--chart-2))",
                    },
                  }}
                  className="h-[300px]"
                >
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={salesData}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="month" />
                      <YAxis />
                      <ChartTooltip content={<ChartTooltipContent />} />
                      <Legend />
                      <Bar
                        dataKey="sales"
                        fill="var(--color-sales)"
                        name="Revenue ($)"
                      />
                      <Bar
                        dataKey="events"
                        fill="var(--color-events)"
                        name="Events"
                      />
                    </BarChart>
                  </ResponsiveContainer>
                </ChartContainer>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Sales Trend</CardTitle>
                <CardDescription>Revenue growth over time</CardDescription>
              </CardHeader>
              <CardContent>
                <ChartContainer
                  config={{
                    sales: {
                      label: "Sales",
                      color: "hsl(var(--chart-1))",
                    },
                  }}
                  className="h-[300px]"
                >
                  <ResponsiveContainer width="100%" height="100%">
                    <LineChart data={salesData}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="month" />
                      <YAxis />
                      <ChartTooltip content={<ChartTooltipContent />} />
                      <Line
                        type="monotone"
                        dataKey="sales"
                        stroke="var(--color-sales)"
                        strokeWidth={2}
                        name="Revenue ($)"
                      />
                    </LineChart>
                  </ResponsiveContainer>
                </ChartContainer>
              </CardContent>
            </Card>
          </div>

          {/* Recent Events */}
          <Card>
            <CardHeader>
              <CardTitle>
                {isAdmin ? "Recent Events" : "My Recent Events"}
              </CardTitle>
              <CardDescription>
                {isAdmin
                  ? "Latest events across the platform"
                  : "Your latest event activities"}
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {recentEvents.map((event) => (
                  <div
                    key={event.id}
                    className="flex items-center justify-between p-4 border rounded-lg"
                  >
                    <div className="flex-1">
                      <h3 className="font-semibold text-gray-900">
                        {event.name}
                      </h3>
                      <p className="text-sm text-gray-600">
                        Date: {event.date}
                      </p>
                      <div className="flex items-center space-x-4 mt-2">
                        <span className="text-sm text-gray-600">
                          Attendees: {event.attendees}
                        </span>
                        <span className="text-sm text-gray-600">
                          Revenue: ${event.revenue.toLocaleString()}
                        </span>
                      </div>
                    </div>
                    <div className="flex items-center space-x-3">
                      <Badge
                        variant={
                          event.status === "active"
                            ? "default"
                            : event.status === "sold-out"
                            ? "destructive"
                            : "secondary"
                        }
                      >
                        {event.status}
                      </Badge>
                      <div className="flex space-x-1">
                        <Button size="sm" variant="ghost">
                          <Eye className="h-4 w-4" />
                        </Button>
                        <Button size="sm" variant="ghost">
                          <Edit className="h-4 w-4" />
                        </Button>
                        <Button size="sm" variant="ghost">
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
