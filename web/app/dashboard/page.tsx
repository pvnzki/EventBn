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
  X,
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

const monthNames = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec",
];

const DashboardPage = () => {
  type User = { role: string } | null;
  const [user, setUser] = useState<User>(null);
  type AnalyticsData = {
    month: number;
    total_events: number;
    total_attendees: number;
    total_revenue: number;
    growth_rate: number;
  };
  type Event = {
    event_id: number;
    organization_id: number | null;
    title: string;
    description: string;
    category: string;
    venue: string;
    location: string;
    start_time: string;
    end_time: string;
    capacity: number;
    cover_image_url: string;
    other_images_url: string;
    video_url: string;
    created_at: string;
    updated_at: string;
    status: string;
    organization?: { name: string; organization_id: number; logo_url: string };
  };

  const [analyticsData, setAnalyticsData] = useState<AnalyticsData[]>([]);
  const [events, setEvents] = useState<Event[]>([]);
  const [selectedEvent, setSelectedEvent] = useState<Event | null>(null);
  const [eventToDelete, setEventToDelete] = useState<Event | null>(null);

  useEffect(() => {
    const userData = localStorage.getItem("user");
    if (userData) {
      setUser(JSON.parse(userData));
    }
  }, []);

  useEffect(() => {
    fetch("http://localhost:3000/api/analytics")
      .then((res) => res.json())
      .then((response) => {
        if (response.success) {
          setAnalyticsData(response.data);
        }
      })
      .catch((err) => console.error(err));
  }, []);

  useEffect(() => {
    fetch("http://localhost:3000/api/events")
      .then((res) => res.json())
      .then((response) => {
        if (response.success) {
          setEvents(response.data);
        }
      })
      .catch((err) => console.error(err));
  }, []);

  const handleDeleteEvent = async (event: Event) => {
    try {
      const response = await fetch(
        `http://localhost:3000/api/events/${event.event_id}`,
        {
          method: "DELETE",
        }
      );
      if (response.ok) {
        setEvents(events.filter((e) => e.event_id !== event.event_id));
        setEventToDelete(null);
      } else {
        console.error("Failed to delete event");
      }
    } catch (err) {
      console.error("Error deleting event:", err);
    }
  };

  const isAdmin = user?.role === "admin";

  const recentData = analyticsData[0] || {
    total_events: 0,
    total_attendees: 0,
    total_revenue: 0,
    growth_rate: 0,
  };

  const previousData = analyticsData[1] || recentData;

  const eventsChange =
    previousData.total_events === 0
      ? 0
      : ((recentData.total_events - previousData.total_events) /
          previousData.total_events) *
        100;

  const attendeesChange =
    previousData.total_attendees === 0
      ? 0
      : ((recentData.total_attendees - previousData.total_attendees) /
          previousData.total_attendees) *
        100;

  const revenueChange =
    previousData.total_revenue === 0
      ? 0
      : ((recentData.total_revenue - previousData.total_revenue) /
          previousData.total_revenue) *
        100;

  const growthChange = recentData.growth_rate - previousData.growth_rate;

  let chartData: { month: string; sales: number; events: number }[] = [];
  if (analyticsData.length > 0) {
    const lastSix = analyticsData.slice(0, 6).reverse();
    chartData = lastSix.map((item) => ({
      month: monthNames[item.month - 1],
      sales: item.total_revenue,
      events: item.total_events,
    }));
  }

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toISOString().split("T")[0];
  };

  const formatDateTime = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleString();
  };

  const handleViewEvent = (event: Event) => {
    setSelectedEvent(event);
  };

  const closeModal = () => {
    setSelectedEvent(null);
  };

  const handleOpenDeleteModal = (event: Event) => {
    setEventToDelete(event);
  };

  const handleCloseDeleteModal = () => {
    setEventToDelete(null);
  };

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />
      <div className="flex-1 lg:ml-64">
        <div className="p-6 lg:p-8">
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
                  {recentData.total_events.toLocaleString()}
                </div>
                <p className="text-xs text-muted-foreground">
                  {eventsChange > 0 ? "+" : ""}
                  {eventsChange.toFixed(1)}% from last month
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
                  {recentData.total_attendees.toLocaleString()}
                </div>
                <p className="text-xs text-muted-foreground">
                  {attendeesChange > 0 ? "+" : ""}
                  {attendeesChange.toFixed(1)}% from last month
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
                  ${recentData.total_revenue.toLocaleString()}
                </div>
                <p className="text-xs text-muted-foreground">
                  {revenueChange > 0 ? "+" : ""}
                  {revenueChange.toFixed(1)}% from last month
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
                <div className="text-2xl font-bold">
                  {recentData.growth_rate > 0 ? "+" : ""}
                  {recentData.growth_rate.toFixed(2)}%
                </div>
                <p className="text-xs text-muted-foreground">
                  {growthChange > 0 ? "+" : ""}
                  {growthChange.toFixed(1)}% from last month
                </p>
              </CardContent>
            </Card>
          </div>

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
                    <BarChart data={chartData}>
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
                    <LineChart data={chartData}>
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
                {events.map((event) => (
                  <div
                    key={event.event_id}
                    className="flex items-center justify-between p-4 border rounded-lg"
                  >
                    <div className="flex items-center space-x-4">
                      <img
                        src={event.cover_image_url}
                        alt={event.title}
                        className="w-16 h-16 object-cover rounded-md"
                      />
                      <div className="flex-1">
                        <h3 className="font-semibold text-gray-900">
                          {event.title}
                        </h3>
                        <p className="text-sm text-gray-600">
                          Category: {event.category}
                        </p>
                        <p className="text-sm text-gray-600">
                          Venue: {event.venue}
                        </p>
                        <p className="text-sm text-gray-600">
                          Date: {formatDate(event.start_time)}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center space-x-3">
                      <Badge
                        variant={
                          event.status === "ACTIVE"
                            ? "default"
                            : event.status === "SOLD_OUT"
                            ? "destructive"
                            : "secondary"
                        }
                      >
                        {event.status.toLowerCase()}
                      </Badge>
                      <div className="flex space-x-1">
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => handleViewEvent(event)}
                        >
                          <Eye className="h-4 w-4" />
                        </Button>
                        <Button size="sm" variant="ghost">
                          <Edit className="h-4 w-4" />
                        </Button>
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => handleOpenDeleteModal(event)}
                        >
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

      {selectedEvent && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-4 w-full max-w-md max-h-[80vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-3">
              <h2 className="text-lg font-bold">{selectedEvent.title}</h2>
              <Button variant="ghost" onClick={closeModal}>
                <X className="h-4 w-4" />
              </Button>
            </div>
            <div className="space-y-2">
              <img
                src={selectedEvent.cover_image_url}
                alt={selectedEvent.title}
                className="w-32 h-16 object-cover rounded-md"
              />
              <p className="text-sm">
                <strong>Event ID:</strong> {selectedEvent.event_id}
              </p>
              <p className="text-sm">
                <strong>Title:</strong> {selectedEvent.title}
              </p>
              <p className="text-sm">
                <strong>Description:</strong> {selectedEvent.description}
              </p>
              <p className="text-sm">
                <strong>Category:</strong> {selectedEvent.category}
              </p>
              <p className="text-sm">
                <strong>Venue:</strong> {selectedEvent.venue}
              </p>
              <p className="text-sm">
                <strong>Location:</strong> {selectedEvent.location}
              </p>
              <p className="text-sm">
                <strong>Start Time:</strong>{" "}
                {formatDateTime(selectedEvent.start_time)}
              </p>
              <p className="text-sm">
                <strong>End Time:</strong>{" "}
                {formatDateTime(selectedEvent.end_time)}
              </p>
              <p className="text-sm">
                <strong>Capacity:</strong> {selectedEvent.capacity}
              </p>
              <p className="text-sm">
                <strong>Status:</strong> {selectedEvent.status.toLowerCase()}
              </p>
              <p className="text-sm">
                <strong>Cover Image URL:</strong>{" "}
                <a
                  href={selectedEvent.cover_image_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-blue-600 hover:underline"
                >
                  View Image
                </a>
              </p>
              <p className="text-sm">
                <strong>Other Images URL:</strong>{" "}
                {selectedEvent.other_images_url
                  .split(", ")
                  .map((url, index) => (
                    <a
                      key={index}
                      href={url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-blue-600 hover:underline block"
                    >
                      Image {index + 1}
                    </a>
                  ))}
              </p>
              <p className="text-sm">
                <strong>Video URL:</strong>{" "}
                {selectedEvent.video_url ? (
                  <a
                    href={selectedEvent.video_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-blue-600 hover:underline"
                  >
                    View Video
                  </a>
                ) : (
                  "N/A"
                )}
              </p>
              <p className="text-sm">
                <strong>Created At:</strong>{" "}
                {formatDateTime(selectedEvent.created_at)}
              </p>
              <p className="text-sm">
                <strong>Updated At:</strong>{" "}
                {formatDateTime(selectedEvent.updated_at)}
              </p>
              {selectedEvent.organization && (
                <p className="text-sm">
                  <strong>Organization:</strong>{" "}
                  {selectedEvent.organization.name}
                </p>
              )}
              <p className="text-sm">
                <strong>Organization ID:</strong>{" "}
                {selectedEvent.organization_id || "N/A"}
              </p>
            </div>
            <div className="mt-3 flex justify-end">
              <Button onClick={closeModal} size="sm">
                Close
              </Button>
            </div>
          </div>
        </div>
      )}

      {eventToDelete && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-bold">Confirm Delete</h2>
              <Button variant="ghost" onClick={handleCloseDeleteModal}>
                <X className="h-4 w-4" />
              </Button>
            </div>
            <p className="text-sm text-gray-600 mb-4">
              Are you sure you want to delete the event "{eventToDelete.title}"?
            </p>
            <div className="flex justify-end space-x-2">
              <Button
                variant="outline"
                size="sm"
                onClick={handleCloseDeleteModal}
              >
                Cancel
              </Button>
              <Button
                variant="destructive"
                size="sm"
                onClick={() => handleDeleteEvent(eventToDelete)}
              >
                Yes
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default DashboardPage;
