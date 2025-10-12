"use client";
import { useRouter } from "next/navigation";

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
import { Separator } from "@/components/ui/separator";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import {
  Calendar,
  Users,
  DollarSign,
  TrendingUp,
  Eye,
  Edit,
  Trash2,
  X,
  MapPin,
  Clock,
  Image as ImageIcon,
  Video,
  Building2,
  ExternalLink,
} from "lucide-react";
import {
  Bar,
  BarChart,
  Line,
  LineChart,
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
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
  DialogDescription,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { useToast } from "@/components/ui/use-toast";

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

const AdminDashboardPage = () => {
  const router = useRouter();
  type User = { role: string; organization_id?: number } | null;
  const [user, setUser] = useState<User>(null);
  type AnalyticsData = {
    totalRevenue: number;
    ticketsSold: number;
    conversionRate: number;
    pageViews: number;
    totalPayments: number;
    totalEvents: number;
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

  const [analyticsData, setAnalyticsData] = useState<AnalyticsData | null>(
    null
  );
  const [chartData, setChartData] = useState<
    {
      month: string;
      revenue: number;
      events: number;
    }[]
  >([]);
  const [events, setEvents] = useState<Event[]>([]);
  const [selectedEvent, setSelectedEvent] = useState<Event | null>(null);
  const [isViewDialogOpen, setIsViewDialogOpen] = useState(false);
  const [eventToDelete, setEventToDelete] = useState<Event | null>(null);
  const [deleteError, setDeleteError] = useState<string | null>(null);
  const [eventToEdit, setEventToEdit] = useState<Event | null>(null);
  const [formData, setFormData] = useState<Partial<Event>>({});
  const { toast } = useToast();

  useEffect(() => {
    const userData = localStorage.getItem("user");
    const token = localStorage.getItem("token");
    console.log("Raw user data from localStorage:", userData);
    console.log("Token from localStorage:", token);
    if (userData) {
      try {
        const parsedUser = JSON.parse(userData);
        console.log("Parsed user data:", parsedUser);
        console.log("Organization ID:", parsedUser?.organization_id);

        // If user is an organizer but has no organization_id, try to fetch it
        if (parsedUser.role === "ORGANIZER" && !parsedUser.organization_id) {
          console.log(
            "Organizer missing organization_id, attempting to fetch organization"
          );

          // Prepare headers with token if available
          const headers: HeadersInit = {
            "Content-Type": "application/json",
          };
          if (token) {
            headers["Authorization"] = `Bearer ${token}`;
          }

          // Try to get user's organization
          fetch(
            `http://localhost:3001/api/organizations/user/${parsedUser.id}`,
            {
              headers,
            }
          )
            .then((res) => {
              console.log("Organization API response status:", res.status);
              return res.json();
            })
            .then((orgResponse) => {
              console.log("Organization API response:", orgResponse);
              if (orgResponse && orgResponse.organization_id) {
                const updatedUser = {
                  ...parsedUser,
                  organization_id: orgResponse.organization_id,
                };
                console.log("Updated user with organization_id:", updatedUser);
                setUser(updatedUser);
                // Update localStorage with the complete user data
                localStorage.setItem("user", JSON.stringify(updatedUser));
                toast({
                  title: "Organization Found",
                  description: `Linked to organization: ${orgResponse.name}`,
                });
              } else {
                setUser(parsedUser);
                toast({
                  title: "No Organization Found",
                  description:
                    "Your account is not associated with an organization. Please contact support or create one.",
                  variant: "destructive",
                });
              }
            })
            .catch((err) => {
              console.error("Error fetching organization:", err);
              setUser(parsedUser);
              toast({
                title: "Organization Error",
                description: "Unable to load organization data.",
                variant: "destructive",
              });
            });
        } else {
          setUser(parsedUser);
        }
      } catch (error) {
        console.error("Error parsing user data:", error);
        toast({
          title: "Authentication Error",
          description: "Invalid user data. Please log in again.",
          variant: "destructive",
        });
      }
    } else {
      console.log("No user data found in localStorage");
      toast({
        title: "Authentication Required",
        description: "Please log in to view the dashboard.",
        variant: "destructive",
      });
    }
  }, []);

  useEffect(() => {
    if (user?.organization_id) {
      console.log("Fetching analytics for organization:", user.organization_id);

      // Prepare headers with token
      const token = localStorage.getItem("token");
      const headers: HeadersInit = {
        "Content-Type": "application/json",
      };
      if (token) {
        headers["Authorization"] = `Bearer ${token}`;
      }

      fetch(
        `http://localhost:3001/api/analytics/organizer/${user.organization_id}/dashboard/overview`,
        { headers }
      )
        .then((res) => {
          console.log("Analytics API response status:", res.status);
          return res.json();
        })
        .then((response) => {
          console.log("Analytics API response:", response);
          if (response.success) {
            setAnalyticsData(response.data);
          } else {
            console.error("Analytics API returned error:", response);
            // Set mock data as fallback
            setAnalyticsData({
              totalRevenue: 25680,
              ticketsSold: 1247,
              conversionRate: 3.2,
              pageViews: 8934,
              totalPayments: 1247,
              totalEvents: 8,
            });
            toast({
              title: "Using Mock Data",
              description:
                "Analytics service unavailable, showing sample data.",
              variant: "destructive",
            });
          }
        })
        .catch((err) => {
          console.error("Error fetching analytics:", err);
          // Set mock data as fallback for network errors too
          setAnalyticsData({
            totalRevenue: 25680,
            ticketsSold: 1247,
            conversionRate: 3.2,
            pageViews: 8934,
            totalPayments: 1247,
            totalEvents: 8,
          });
          toast({
            title: "Using Mock Data",
            description: "Analytics service unavailable, showing sample data.",
            variant: "destructive",
          });
        });
    } else {
      console.log("No organization_id found, skipping analytics fetch");
    }
  }, [user]);

  useEffect(() => {
    if (user?.organization_id) {
      console.log(
        "Fetching chart data for organization:",
        user.organization_id
      );

      // Prepare headers with token
      const token = localStorage.getItem("token");
      const headers: HeadersInit = {
        "Content-Type": "application/json",
      };
      if (token) {
        headers["Authorization"] = `Bearer ${token}`;
      }

      fetch(
        `http://localhost:3001/api/analytics/organizer/${user.organization_id}/dashboard/revenue-trend`,
        { headers }
      )
        .then((res) => {
          console.log("Chart data API response status:", res.status);
          return res.json();
        })
        .then((response) => {
          console.log("Chart data API response:", response);
          if (response.success) {
            setChartData(response.data);
          } else {
            console.error("Chart data API returned error:", response);
            // Set mock chart data as fallback
            setChartData([
              { month: "Jan", revenue: 4200, events: 3 },
              { month: "Feb", revenue: 3100, events: 2 },
              { month: "Mar", revenue: 6800, events: 4 },
              { month: "Apr", revenue: 5400, events: 3 },
              { month: "May", revenue: 7200, events: 5 },
              { month: "Jun", revenue: 4900, events: 3 },
            ]);
          }
        })
        .catch((err) => {
          console.error("Error fetching chart data:", err);
          // Set mock chart data as fallback for network errors too
          setChartData([
            { month: "Jan", revenue: 4200, events: 3 },
            { month: "Feb", revenue: 3100, events: 2 },
            { month: "Mar", revenue: 6800, events: 4 },
            { month: "Apr", revenue: 5400, events: 3 },
            { month: "May", revenue: 7200, events: 5 },
            { month: "Jun", revenue: 4900, events: 3 },
          ]);
          toast({
            title: "Using Mock Chart Data",
            description: "Chart service unavailable, showing sample data.",
            variant: "destructive",
          });
        });
    } else {
      console.log("No organization_id found, skipping chart data fetch");
    }
  }, [user]);

  useEffect(() => {
    console.log("Fetching events, user:", user);

    // Only fetch events if user is loaded
    if (!user) {
      console.log("User not loaded yet, skipping events fetch");
      return;
    }

    fetch("http://localhost:3001/api/events")
      .then((res) => {
        console.log("Events API response status:", res.status);
        return res.json();
      })
      .then((response) => {
        console.log("Events API response:", response);
        if (response.success) {
          if (user?.organization_id) {
            // Filter events to only include those matching the user's organization_id
            const filteredEvents = response.data.filter(
              (event: Event) => event.organization_id === user.organization_id
            );
            console.log("Filtered events for organization:", filteredEvents);
            setEvents(filteredEvents);
          } else {
            // If no organization_id, show all events as fallback
            console.log("No organization_id, showing all events as fallback");
            setEvents(response.data);
            if (user?.role === "ORGANIZER") {
              toast({
                title: "Organization Missing",
                description:
                  "Showing all events. Your account needs to be linked to an organization.",
                variant: "destructive",
              });
            }
          }
        } else {
          console.error("Events API returned error:", response);
          toast({
            title: "Events Loading Error",
            description: "Failed to load events data.",
            variant: "destructive",
          });
        }
      })
      .catch((err) => {
        console.error("Error fetching events:", err);
        toast({
          title: "Network Error",
          description: "Unable to connect to events service.",
          variant: "destructive",
        });
      });
  }, [user]); // Add user as a dependency to refetch events when user data changes

  const handleDeleteEvent = async (event: Event) => {
    try {
      // Get token from localStorage
      const token = localStorage.getItem("token");
      const headers: HeadersInit = {};
      if (token) {
        headers["Authorization"] = `Bearer ${token}`;
      }

      const response = await fetch(
        `http://localhost:3001/api/events/${event.event_id}`,
        {
          method: "DELETE",
          headers: headers,
        }
      );

      const data = await response.json();

      if (response.ok) {
        setEvents(events.filter((e) => e.event_id !== event.event_id));
        setEventToDelete(null);
        toast({
          title: "Success",
          description: "Event deleted successfully",
        });
      } else {
        console.error("Failed to delete event:", data);
        // Show error popup instead of toast
        setDeleteError(data.message || "Failed to delete event");
        setEventToDelete(null);
      }
    } catch (err) {
      console.error("Error deleting event:", err);
      setDeleteError("Error deleting event. Please try again.");
      setEventToDelete(null);
    }
  };

  const handleOpenEditModal = (event: Event) => {
    console.log("Opening edit modal for event:", event);
    setEventToEdit(event);
    setFormData({
      title: event.title,
      description: event.description,
      category: event.category,
      venue: event.venue,
      location: event.location,
      start_time: event.start_time,
      end_time: event.end_time,
      capacity: event.capacity,
      cover_image_url: event.cover_image_url,
      other_images_url: event.other_images_url,
      video_url: event.video_url,
      status: event.status,
      organization_id: event.organization_id,
    });
    console.log("Form data set to:", {
      title: event.title,
      description: event.description,
      category: event.category,
      venue: event.venue,
      location: event.location,
      start_time: event.start_time,
      end_time: event.end_time,
      capacity: event.capacity,
      cover_image_url: event.cover_image_url,
      other_images_url: event.other_images_url,
      video_url: event.video_url,
      status: event.status,
      organization_id: event.organization_id,
    });
  };

  const handleCloseEditModal = () => {
    console.log("Closing edit modal");
    setEventToEdit(null);
    setFormData({});
  };

  const handleInputChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    console.log(`Input changed: ${name} = ${value}`);
  };

  const handleSaveEdit = async () => {
    if (!eventToEdit) {
      console.error("No event to edit");
      return;
    }

    try {
      console.log("Sending PUT request with data:", formData);

      // Get token from localStorage
      const token = localStorage.getItem("token");
      const headers: HeadersInit = {
        "Content-Type": "application/json",
      };
      if (token) {
        headers["Authorization"] = `Bearer ${token}`;
      }

      const response = await fetch(
        `http://localhost:3001/api/events/${eventToEdit.event_id}`,
        {
          method: "PUT",
          headers: headers,
          body: JSON.stringify(formData),
        }
      );

      if (response.ok) {
        const updatedEvent = await response.json();
        console.log("Event updated successfully:", updatedEvent);
        setEvents(
          events.map((e) =>
            e.event_id === eventToEdit.event_id ? updatedEvent.data : e
          )
        );
        setEventToEdit(null);
        setFormData({});
        toast({
          title: "Success",
          description: "Event updated successfully",
        });
      } else {
        console.error("Failed to update event:", response.statusText);
        toast({
          title: "Error",
          description: "Failed to update event",
          variant: "destructive",
        });
      }
    } catch (err) {
      console.error("Error updating event:", err);
      toast({
        title: "Error",
        description: "Error updating event",
        variant: "destructive",
      });
    }
  };

  const recentData = analyticsData || {
    totalEvents: 4,
    ticketsSold: 58,
    totalRevenue: 25680,
    conversionRate: 3.2,
  };

  // For organizer dashboard, we'll show current data without comparison
  // Historical trends would require additional endpoints

  // Chart data is now managed in state and fetched from revenue trend endpoint

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
    setIsViewDialogOpen(true);
  };

  const closeModal = () => {
    setSelectedEvent(null);
    setIsViewDialogOpen(false);
  };

  const handleOpenDeleteModal = (event: Event) => {
    console.log("Opening delete modal for event:", event);
    setEventToDelete(event);
  };

  const handleCloseDeleteModal = () => {
    console.log("Closing delete modal");
    setEventToDelete(null);
  };

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />
      <div className="flex-1 lg:ml-64">
        <div className="p-6 lg:p-8">
          <div className="mb-8">
            <h1 className="text-3xl font-bold text-gray-900">
              Organizer Dashboard
            </h1>
            <p className="text-gray-600 mt-2">
              Overview of all platform activities and metrics
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">My Events</CardTitle>
                <Calendar className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {(recentData?.totalEvents || 0).toLocaleString()}
                </div>
                <p className="text-xs text-muted-foreground">
                  Your active events
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  Tickets Sold
                </CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {(recentData?.ticketsSold || 0).toLocaleString()}
                </div>
                <p className="text-xs text-muted-foreground">
                  Total tickets purchased
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
                  ${(recentData?.totalRevenue || 0).toLocaleString()}
                </div>
                <p className="text-xs text-muted-foreground">
                  Your total revenue
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  Conversion Rate
                </CardTitle>
                <TrendingUp className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {(recentData?.conversionRate || 0).toFixed(1)}%
                </div>
                <p className="text-xs text-muted-foreground">
                  Tickets per event ratio
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
                    revenue: {
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
                  <div style={{ width: "379px", height: "300px" }}>
                    <BarChart data={chartData} width={379} height={300}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="month" />
                      <YAxis />
                      <ChartTooltip content={<ChartTooltipContent />} />
                      <Legend />
                      <Bar
                        dataKey="revenue"
                        fill="var(--color-revenue)"
                        name="Revenue ($)"
                      />
                      <Bar
                        dataKey="events"
                        fill="var(--color-events)"
                        name="Events"
                      />
                    </BarChart>
                  </div>
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
                    revenue: {
                      label: "Revenue",
                      color: "hsl(var(--chart-1))",
                    },
                  }}
                  className="h-[300px]"
                >
                  <div style={{ width: "379px", height: "300px" }}>
                    <LineChart data={chartData} width={379} height={300}>
                      <CartesianGrid strokeDasharray="3 3" />
                      <XAxis dataKey="month" />
                      <YAxis />
                      <ChartTooltip content={<ChartTooltipContent />} />
                      <Line
                        type="monotone"
                        dataKey="revenue"
                        stroke="var(--color-revenue)"
                        strokeWidth={2}
                        name="Revenue ($)"
                      />
                    </LineChart>
                  </div>
                </ChartContainer>
              </CardContent>
            </Card>
          </div>

          <Card>
            <CardHeader>
              <CardTitle>My Events</CardTitle>
              <CardDescription>
                Events organized by your organization
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
                      <div className="flex space-x-1">
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() =>
                            router.push(`/organizer/events/${event.event_id}`)
                          }
                        >
                          <Eye className="h-4 w-4" />
                        </Button>
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() =>
                            router.push(
                              `/organizer/edit-event?id=${event.event_id}`
                            )
                          }
                        >
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

      {/* Event Details Modal - Compact Version */}
      {isViewDialogOpen && selectedEvent && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-3">
          <div className="bg-white rounded-2xl w-full max-w-md max-h-[75vh] overflow-hidden flex flex-col shadow-2xl border border-gray-100">
            {/* Header with Gradient */}
            <div className="relative bg-gradient-to-r from-blue-600 to-purple-600 p-3">
              <h3 className="text-base font-bold text-white pr-8 line-clamp-2">
                {selectedEvent.title}
              </h3>
              <button
                onClick={closeModal}
                className="absolute top-3 right-3 text-white/80 hover:text-white hover:bg-white/20 rounded-full p-1 transition-all"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            {/* Content - Scrollable */}
            <div className="overflow-y-auto flex-1 custom-scrollbar">
              <div className="p-3 space-y-2.5">
                {/* Event Image */}
                <div className="relative group">
                  <img
                    src={selectedEvent.cover_image_url}
                    alt={selectedEvent.title}
                    className="w-full h-28 object-cover rounded-xl shadow-md"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent rounded-xl"></div>
                </div>

                {/* Description Card */}
                <div className="bg-gradient-to-br from-blue-50 to-purple-50 p-2.5 rounded-xl border border-blue-100">
                  <p className="text-xs text-gray-700 leading-relaxed">
                    {selectedEvent.description}
                  </p>
                </div>

                {/* Info Grid with Cards */}
                <div className="grid grid-cols-2 gap-2">
                  <div className="bg-white border border-gray-200 p-2.5 rounded-xl hover:shadow-md transition-shadow">
                    <div className="flex items-center gap-1.5 mb-1">
                      <div className="bg-blue-100 p-1 rounded-lg">
                        <Building2 className="h-3 w-3 text-blue-600" />
                      </div>
                      <span className="font-semibold text-xs text-gray-700">
                        Category
                      </span>
                    </div>
                    <p className="text-xs text-gray-600 font-medium">
                      {selectedEvent.category}
                    </p>
                  </div>

                  <div className="bg-white border border-gray-200 p-2.5 rounded-xl hover:shadow-md transition-shadow">
                    <div className="flex items-center gap-1.5 mb-1">
                      <div className="bg-purple-100 p-1 rounded-lg">
                        <Users className="h-3 w-3 text-purple-600" />
                      </div>
                      <span className="font-semibold text-xs text-gray-700">
                        Capacity
                      </span>
                    </div>
                    <p className="text-xs text-gray-600 font-medium">
                      {selectedEvent.capacity}
                    </p>
                  </div>
                </div>

                {/* Venue Card */}
                <div className="bg-white border border-gray-200 p-2.5 rounded-xl hover:shadow-md transition-shadow">
                  <div className="flex items-center gap-1.5 mb-1.5">
                    <div className="bg-green-100 p-1 rounded-lg">
                      <MapPin className="h-3 w-3 text-green-600" />
                    </div>
                    <span className="font-semibold text-xs text-gray-700">
                      Venue & Location
                    </span>
                  </div>
                  <p className="text-xs text-gray-700 font-medium">
                    {selectedEvent.venue}
                  </p>
                  {selectedEvent.location && (
                    <p className="text-xs text-gray-500 mt-1">
                      {selectedEvent.location}
                    </p>
                  )}
                </div>

                {/* Date & Time Card */}
                <div className="bg-white border border-gray-200 p-2.5 rounded-xl hover:shadow-md transition-shadow">
                  <div className="flex items-center gap-1.5 mb-1.5">
                    <div className="bg-orange-100 p-1 rounded-lg">
                      <Clock className="h-3 w-3 text-orange-600" />
                    </div>
                    <span className="font-semibold text-xs text-gray-700">
                      Date & Time
                    </span>
                  </div>
                  <div className="space-y-1">
                    <div className="flex items-start gap-1.5">
                      <span className="text-xs font-semibold text-green-600 min-w-[32px]">
                        Start:
                      </span>
                      <span className="text-xs text-gray-700">
                        {new Date(selectedEvent.start_time).toLocaleString(
                          "en-US",
                          {
                            month: "short",
                            day: "numeric",
                            year: "numeric",
                            hour: "2-digit",
                            minute: "2-digit",
                          }
                        )}
                      </span>
                    </div>
                    <div className="flex items-start gap-1.5">
                      <span className="text-xs font-semibold text-red-600 min-w-[35px]">
                        End:
                      </span>
                      <span className="text-xs text-gray-700">
                        {new Date(selectedEvent.end_time).toLocaleString(
                          "en-US",
                          {
                            month: "short",
                            day: "numeric",
                            year: "numeric",
                            hour: "2-digit",
                            minute: "2-digit",
                          }
                        )}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Video Link Card */}
                {selectedEvent.video_url && (
                  <div className="bg-gradient-to-br from-pink-50 to-rose-50 border border-pink-200 p-2.5 rounded-xl hover:shadow-md transition-shadow">
                    <div className="flex items-center gap-1.5 mb-1">
                      <div className="bg-pink-100 p-1 rounded-lg">
                        <Video className="h-3 w-3 text-pink-600" />
                      </div>
                      <span className="font-semibold text-xs text-gray-700">
                        Video
                      </span>
                    </div>
                    <a
                      href={selectedEvent.video_url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-xs text-pink-600 hover:text-pink-700 font-medium flex items-center gap-1 hover:underline"
                    >
                      <span>Watch promotional video</span>
                      <ExternalLink className="h-3 w-3" />
                    </a>
                  </div>
                )}
              </div>
            </div>

            {/* Footer with Action Buttons */}
            <div className="flex justify-end gap-2 p-3 border-t bg-gradient-to-r from-gray-50 to-gray-100">
              <Button
                variant="outline"
                size="sm"
                onClick={() => {
                  router.push(
                    `/organizer/edit-event?id=${selectedEvent.event_id}`
                  );
                }}
                className="h-8 text-xs border-gray-300 hover:bg-blue-50 hover:border-blue-400 hover:text-blue-700 transition-all"
              >
                <Edit className="h-3.5 w-3.5 mr-1.5" />
                Edit Event
              </Button>
              <Button
                size="sm"
                onClick={closeModal}
                className="h-8 text-xs bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 shadow-md"
              >
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

      {/* Error Popup for Delete Failures */}
      {deleteError && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md shadow-xl border-2 border-red-500">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-bold text-red-600">
                Cannot Delete Event
              </h2>
              <Button variant="ghost" onClick={() => setDeleteError(null)}>
                <X className="h-4 w-4" />
              </Button>
            </div>
            <div className="mb-4">
              <div className="flex items-start space-x-3">
                <div className="flex-shrink-0">
                  <svg
                    className="h-6 w-6 text-red-600"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                    />
                  </svg>
                </div>
                <div className="flex-1">
                  <p className="text-sm text-gray-700 leading-relaxed">
                    {deleteError}
                  </p>
                </div>
              </div>
            </div>
            <div className="flex justify-end">
              <Button
                variant="default"
                size="sm"
                onClick={() => setDeleteError(null)}
                className="bg-red-600 hover:bg-red-700"
              >
                OK
              </Button>
            </div>
          </div>
        </div>
      )}

      {eventToEdit && (
        <Dialog open={!!eventToEdit} onOpenChange={handleCloseEditModal}>
          <DialogContent className="sm:max-w-[425px] z-[100]">
            <DialogHeader>
              <DialogTitle>Edit Event</DialogTitle>
              <DialogDescription>
                Update the event details below.
              </DialogDescription>
            </DialogHeader>
            <div className="grid gap-4 py-4">
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="title" className="text-right">
                  Title
                </Label>
                <Input
                  id="title"
                  name="title"
                  value={formData.title || ""}
                  onChange={handleInputChange}
                  className="col-span-3"
                />
              </div>
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="description" className="text-right">
                  Description
                </Label>
                <Textarea
                  id="description"
                  name="description"
                  value={formData.description || ""}
                  onChange={handleInputChange}
                  className="col-span-3"
                />
              </div>
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="category" className="text-right">
                  Category
                </Label>
                <Input
                  id="category"
                  name="category"
                  value={formData.category || ""}
                  onChange={handleInputChange}
                  className="col-span-3"
                />
              </div>
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="venue" className="text-right">
                  Venue
                </Label>
                <Input
                  id="venue"
                  name="venue"
                  value={formData.venue || ""}
                  onChange={handleInputChange}
                  className="col-span-3"
                />
              </div>
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="location" className="text-right">
                  Location
                </Label>
                <Input
                  id="location"
                  name="location"
                  value={formData.location || ""}
                  onChange={handleInputChange}
                  className="col-span-3"
                />
              </div>
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="start_time" className="text-right">
                  Start Time
                </Label>
                <Input
                  id="start_time"
                  name="start_time"
                  type="datetime-local"
                  value={
                    formData.start_time
                      ? new Date(formData.start_time).toISOString().slice(0, 16)
                      : ""
                  }
                  onChange={handleInputChange}
                  className="col-span-3"
                />
              </div>
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="end_time" className="text-right">
                  End Time
                </Label>
                <Input
                  id="end_time"
                  name="end_time"
                  type="datetime-local"
                  value={
                    formData.end_time
                      ? new Date(formData.end_time).toISOString().slice(0, 16)
                      : ""
                  }
                  onChange={handleInputChange}
                  className="col-span-3"
                />
              </div>
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="capacity" className="text-right">
                  Capacity
                </Label>
                <Input
                  id="capacity"
                  name="capacity"
                  type="number"
                  value={formData.capacity || ""}
                  onChange={handleInputChange}
                  className="col-span-3"
                />
              </div>
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="cover_image_url" className="text-right">
                  Cover Image URL
                </Label>
                <Input
                  id="cover_image_url"
                  name="cover_image_url"
                  value={formData.cover_image_url || ""}
                  onChange={handleInputChange}
                  className="col-span-3"
                />
              </div>
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="other_images_url" className="text-right">
                  Other Images URL
                </Label>
                <Textarea
                  id="other_images_url"
                  name="other_images_url"
                  value={formData.other_images_url || ""}
                  onChange={handleInputChange}
                  className="col-span-3"
                />
              </div>
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="video_url" className="text-right">
                  Video URL
                </Label>
                <Input
                  id="video_url"
                  name="video_url"
                  value={formData.video_url || ""}
                  onChange={handleInputChange}
                  className="col-span-3"
                />
              </div>
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="status" className="text-right">
                  Status
                </Label>
                <Input
                  id="status"
                  name="status"
                  value={formData.status || ""}
                  onChange={handleInputChange}
                  className="col-span-3"
                />
              </div>
              <div className="grid grid-cols-4 items-center gap-4">
                <Label htmlFor="organization_id" className="text-right">
                  Organization ID
                </Label>
                <Input
                  id="organization_id"
                  name="organization_id"
                  type="number"
                  value={formData.organization_id || ""}
                  onChange={handleInputChange}
                  className="col-span-3"
                />
              </div>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={handleCloseEditModal}>
                Cancel
              </Button>
              <Button onClick={handleSaveEdit}>Save</Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}
    </div>
  );
};

export default AdminDashboardPage;
