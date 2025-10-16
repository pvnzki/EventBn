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
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Search,
  Plus,
  Eye,
  Edit,
  Trash2,
  Ticket,
  DollarSign,
  Users,
  TrendingUp,
  Mail,
  Calendar,
  MapPin,
  User,
  Phone,
  CreditCard,
  Check,
  X,
  RefreshCw,
  ArrowLeft,
  BarChart3,
  PieChart,
  Target,
  Clock,
  Star,
  Filter,
  ArrowUpRight,
  TrendingDown,
  Activity,
} from "lucide-react";

interface User {
  role: "admin" | "organizer";
  name: string;
  user_id?: number;
}

interface EventData {
  event_id: number;
  title: string;
  start_time: string;
  end_time: string;
  venue: string;
  location: string;
  capacity: number;
  cover_image_url?: string;
}

interface TicketUser {
  name: string;
  email: string;
  phone_number?: string;
}

interface Payment {
  payment_id: string;
  status: string;
  payment_method: string;
  payment_date: string;
}

interface TicketPurchase {
  ticket_id: string;
  event_id: number;
  user_id: number;
  seat_id?: number;
  seat_label?: string;
  purchase_date: string;
  price: number;
  attended: boolean;
  qr_code?: string;
  user: TicketUser;
  event: EventData;
  payment: Payment;
}

interface EventWithTickets {
  event_id: number;
  title: string;
  description: string;
  start_time: string;
  end_time: string;
  venue: string;
  location: string;
  cover_image_url?: string;
  capacity: number;
  category: string;
  ticket_types: TicketType[];
  tickets: TicketPurchase[];
  ticketCount: number;
  attendedCount: number;
  eventRevenue: number;
  ticketCategoryBreakdown: TicketCategoryData[];
  averageTicketPrice: number;
  attendanceRate: number;
}

interface TicketType {
  name: string;
  price: number;
  description: string;
}

interface TicketCategoryData {
  name: string;
  price: number;
  description: string;
  ticketsSold: number;
  revenue: number;
  attendedCount: number;
}

interface RevenueByCategory {
  category: string;
  revenue: number;
  ticketsSold: number;
  eventsCount: number;
}

interface TopSellingEvent {
  event_id: number;
  title: string;
  ticketsSold: number;
  revenue: number;
}

interface Statistics {
  totalTicketsSold: number;
  totalRevenue: number;
  totalEvents: number;
  averageTicketPrice: number;
  totalAttended: number;
  attendanceRate: number;
  recentSales: {
    ticketsSold: number;
    revenue: number;
    period: string;
  };
  revenueByCategory: RevenueByCategory[];
  topSellingEvents: TopSellingEvent[];
}

interface ApiResponse {
  success: boolean;
  tickets: TicketPurchase[];
  events: EventData[];
  ticketsByEvent: EventWithTickets[];
  statistics: Statistics;
  message?: string;
}

export default function TicketsPage() {
  const [user, setUser] = useState<User | null>(null);
  const [tickets, setTickets] = useState<TicketPurchase[]>([]);
  const [ticketsByEvent, setTicketsByEvent] = useState<EventWithTickets[]>([]);
  const [statistics, setStatistics] = useState<Statistics>({
    totalTicketsSold: 0,
    totalRevenue: 0,
    totalEvents: 0,
    averageTicketPrice: 0,
    totalAttended: 0,
    attendanceRate: 0,
    recentSales: {
      ticketsSold: 0,
      revenue: 0,
      period: "30 days",
    },
    revenueByCategory: [],
    topSellingEvents: [],
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [eventFilter, setEventFilter] = useState("all");
  const [attendanceFilter, setAttendanceFilter] = useState("all");
  const [selectedEvent, setSelectedEvent] = useState<EventWithTickets | null>(
    null
  );
  const [viewMode, setViewMode] = useState<"overview" | "event-details">(
    "overview"
  );

  useEffect(() => {
    const userData = localStorage.getItem("user");
    if (userData) {
      const parsedUser = JSON.parse(userData);
      setUser(parsedUser);
      fetchTicketsData(parsedUser);
    }
  }, []);

  const fetchTicketsData = async (currentUser: User) => {
    try {
      setLoading(true);
      setError(null);

      const token = localStorage.getItem("token");
      if (!token) {
        setError("No authentication token found");
        return;
      }

      const response = await fetch(
        "http://localhost:3001/api/tickets/my-events-tickets",
        {
          method: "GET",
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
          },
        }
      );

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data: ApiResponse = await response.json();
      console.log("API Response Data:", data);

      if (data.success) {
        console.log("Tickets:", data.tickets);
        console.log("TicketsByEvent:", data.ticketsByEvent);
        console.log("Statistics:", data.statistics);

        // Debug event titles specifically
        if (data.ticketsByEvent) {
          console.log("Event titles debug:");
          data.ticketsByEvent.forEach((event, index) => {
            console.log(`Event ${index}:`, {
              event_id: event.event_id,
              title: event.title,
              hasTitle: !!event.title,
              titleType: typeof event.title,
              titleLength: event.title ? event.title.length : 0,
            });
          });
        }

        setTickets(data.tickets);
        setTicketsByEvent(data.ticketsByEvent);
        setStatistics(data.statistics);
      } else {
        setError(data.message || "Failed to fetch tickets data");
      }
    } catch (error) {
      console.error("Error fetching tickets:", error);
      setError(
        error instanceof Error ? error.message : "Failed to fetch tickets"
      );
    } finally {
      setLoading(false);
    }
  };

  const refreshData = () => {
    if (user) {
      fetchTicketsData(user);
    }
  };

  const markAsAttended = async (ticketId: string) => {
    try {
      const token = localStorage.getItem("token");
      if (!token) return;

      const response = await fetch(
        `http://localhost:3001/api/tickets/${ticketId}/attend`,
        {
          method: "PUT",
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
          },
        }
      );

      if (response.ok) {
        // Refresh data after successful update
        refreshData();
      }
    } catch (error) {
      console.error("Error marking attendance:", error);
    }
  };

  const isAdmin = user?.role === "admin";

  // Determine which tickets to show based on view mode
  const ticketsToFilter =
    viewMode === "event-details" && selectedEvent
      ? selectedEvent.tickets
      : tickets;

  const filteredTickets = ticketsToFilter.filter((ticket) => {
    const matchesSearch =
      ticket.user?.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      ticket.user?.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      ticket.event?.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (ticket.seat_label &&
        ticket.seat_label.toLowerCase().includes(searchTerm.toLowerCase()));

    const matchesStatus =
      statusFilter === "all" || ticket.payment?.status === statusFilter;

    const matchesEvent =
      eventFilter === "all" ||
      viewMode === "event-details" || // Don't filter by event in event details view
      ticket.event?.title === eventFilter;

    const matchesAttendance =
      attendanceFilter === "all" ||
      (attendanceFilter === "attended" && ticket.attended) ||
      (attendanceFilter === "not-attended" && !ticket.attended);

    return matchesSearch && matchesStatus && matchesEvent && matchesAttendance;
  });

  if (loading) {
    return (
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <div className="flex-1 lg:ml-64">
          <div className="p-6 lg:p-8">
            <div className="flex items-center justify-center h-64">
              <RefreshCw className="h-8 w-8 animate-spin text-gray-400" />
              <span className="ml-2 text-gray-600">
                Loading tickets data...
              </span>
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
          <div className="p-6 lg:p-8">
            <Card className="text-center py-12">
              <CardContent>
                <X className="h-12 w-12 mx-auto text-red-400 mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">
                  Error Loading Data
                </h3>
                <p className="text-gray-600 mb-4">{error}</p>
                <Button onClick={refreshData}>
                  <RefreshCw className="h-4 w-4 mr-2" />
                  Try Again
                </Button>
              </CardContent>
            </Card>
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
            <div className="flex items-center">
              {viewMode === "event-details" && (
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => {
                    setViewMode("overview");
                    setSelectedEvent(null);
                  }}
                  className="mr-4"
                >
                  <ArrowLeft className="h-4 w-4 mr-2" />
                  Back to Overview
                </Button>
              )}
              <div>
                <h1 className="text-3xl font-bold text-gray-900">
                  {viewMode === "overview"
                    ? "Ticket Management"
                    : `${selectedEvent?.title} - Tickets`}
                </h1>
                <p className="text-gray-600 mt-2">
                  {viewMode === "overview"
                    ? isAdmin
                      ? "Manage all tickets across the platform"
                      : "Manage tickets for your events"
                    : `Detailed view for ${selectedEvent?.title}`}
                </p>
              </div>
            </div>
            <div className="flex gap-2">
              <Button onClick={refreshData}>
                <RefreshCw className="h-4 w-4 mr-2" />
                Refresh Data
              </Button>
            </div>
          </div>

          {viewMode === "overview" ? (
            <>
              {/* Enhanced Stats Cards */}
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
                      ${statistics.totalRevenue.toLocaleString()}
                    </div>
                    <p className="text-xs text-muted-foreground">
                      From {statistics.totalTicketsSold} tickets
                    </p>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">
                      Tickets Sold
                    </CardTitle>
                    <Ticket className="h-4 w-4 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">
                      {statistics.totalTicketsSold}
                    </div>
                    <p className="text-xs text-muted-foreground">
                      Across {statistics.totalEvents} events
                    </p>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">
                      Attendance Rate
                    </CardTitle>
                    <Target className="h-4 w-4 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">
                      {(statistics.attendanceRate || 0).toFixed(1)}%
                    </div>
                    <p className="text-xs text-muted-foreground">
                      {statistics.totalAttended || 0} of{" "}
                      {statistics.totalTicketsSold || 0} attended
                    </p>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">
                      Recent Sales
                    </CardTitle>
                    <TrendingUp className="h-4 w-4 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">
                      ${(statistics.recentSales?.revenue || 0).toLocaleString()}
                    </div>
                    <p className="text-xs text-muted-foreground">
                      {statistics.recentSales?.ticketsSold || 0} tickets in{" "}
                      {statistics.recentSales?.period || "30 days"}
                    </p>
                  </CardContent>
                </Card>
              </div>

              {/* Revenue by Category */}
              {statistics.revenueByCategory &&
                statistics.revenueByCategory.length > 0 && (
                  <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
                    <Card>
                      <CardHeader>
                        <CardTitle className="flex items-center">
                          <PieChart className="h-5 w-5 mr-2" />
                          Revenue by Category
                        </CardTitle>
                      </CardHeader>
                      <CardContent>
                        <div className="space-y-4">
                          {(statistics.revenueByCategory || []).map(
                            (category, index) => (
                              <div
                                key={category.category}
                                className="flex items-center justify-between"
                              >
                                <div className="flex items-center">
                                  <div
                                    className="w-3 h-3 rounded-full mr-3"
                                    style={{
                                      backgroundColor: `hsl(${
                                        index * 45
                                      }, 70%, 50%)`,
                                    }}
                                  />
                                  <div>
                                    <p className="font-medium">
                                      {category.category}
                                    </p>
                                    <p className="text-sm text-gray-500">
                                      {category.ticketsSold} tickets,{" "}
                                      {category.eventsCount} events
                                    </p>
                                  </div>
                                </div>
                                <div className="text-right">
                                  <p className="font-bold">
                                    ${category.revenue.toLocaleString()}
                                  </p>
                                  <p className="text-sm text-gray-500">
                                    {(
                                      ((category.revenue || 0) /
                                        (statistics.totalRevenue || 1)) *
                                      100
                                    ).toFixed(1)}
                                    %
                                  </p>
                                </div>
                              </div>
                            )
                          )}
                        </div>
                      </CardContent>
                    </Card>

                    <Card>
                      <CardHeader>
                        <CardTitle className="flex items-center">
                          <Star className="h-5 w-5 mr-2" />
                          Top Selling Events
                        </CardTitle>
                      </CardHeader>
                      <CardContent>
                        <div className="space-y-4">
                          {(statistics.topSellingEvents || []).map(
                            (event, index) => (
                              <div
                                key={event.event_id}
                                className="flex items-center justify-between"
                              >
                                <div className="flex items-center">
                                  <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center mr-3">
                                    <span className="text-blue-600 font-bold text-sm">
                                      {index + 1}
                                    </span>
                                  </div>
                                  <div>
                                    <p className="font-medium">{event.title}</p>
                                    <p className="text-sm text-gray-500">
                                      {event.ticketsSold} tickets sold
                                    </p>
                                  </div>
                                </div>
                                <div className="text-right">
                                  <p className="font-bold">
                                    ${event.revenue.toLocaleString()}
                                  </p>
                                  <Button
                                    variant="outline"
                                    size="sm"
                                    onClick={() => {
                                      const eventData = ticketsByEvent.find(
                                        (e) => e.event_id === event.event_id
                                      );
                                      if (eventData) {
                                        setSelectedEvent(eventData);
                                        setViewMode("event-details");
                                      }
                                    }}
                                  >
                                    View Details
                                  </Button>
                                </div>
                              </div>
                            )
                          )}
                        </div>
                      </CardContent>
                    </Card>
                  </div>
                )}

              {/* Events Overview */}
              <Card className="mb-6">
                <CardHeader>
                  <CardTitle className="flex items-center">
                    <BarChart3 className="h-5 w-5 mr-2" />
                    Events Overview ({ticketsByEvent?.length || 0} events)
                  </CardTitle>
                  <CardDescription>
                    Click on any event to view detailed ticket information
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  {ticketsByEvent && ticketsByEvent.length > 0 ? (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                      {ticketsByEvent.map((eventData) => (
                        <Card
                          key={eventData.event_id}
                          className="cursor-pointer hover:shadow-lg transition-shadow"
                          onClick={() => {
                            setSelectedEvent(eventData);
                            setViewMode("event-details");
                          }}
                        >
                          <CardHeader>
                            <div className="flex justify-between items-start">
                              <div className="flex-1">
                                <CardTitle className="text-lg">
                                  {eventData.title && eventData.title.trim()
                                    ? eventData.title
                                    : "Untitled Event"}
                                </CardTitle>
                                {/* Debug info - remove after fixing */}
                                {process.env.NODE_ENV === "development" && (
                                  <div className="text-xs text-gray-400 mt-1">
                                    Debug: title="{eventData.title}", type=
                                    {typeof eventData.title}, id=
                                    {eventData.event_id}
                                  </div>
                                )}
                                <CardDescription className="mt-1 flex items-center">
                                  <Calendar className="h-4 w-4 mr-1" />
                                  {eventData.start_time
                                    ? new Date(
                                        eventData.start_time
                                      ).toLocaleDateString()
                                    : "Date TBD"}
                                </CardDescription>
                              </div>
                              <ArrowUpRight className="h-4 w-4 text-gray-400" />
                            </div>
                          </CardHeader>
                          <CardContent>
                            <div className="space-y-2">
                              <div className="flex justify-between">
                                <span className="text-sm text-gray-600">
                                  Tickets Sold:
                                </span>
                                <span className="font-medium">
                                  {eventData.ticketCount || 0}
                                </span>
                              </div>
                              <div className="flex justify-between">
                                <span className="text-sm text-gray-600">
                                  Revenue:
                                </span>
                                <span className="font-medium">
                                  $
                                  {(
                                    eventData.eventRevenue || 0
                                  ).toLocaleString()}
                                </span>
                              </div>
                              <div className="flex justify-between">
                                <span className="text-sm text-gray-600">
                                  Attendance:
                                </span>
                                <span className="font-medium">
                                  {(eventData.attendanceRate || 0).toFixed(1)}%
                                </span>
                              </div>
                              {eventData.ticketCategoryBreakdown &&
                                eventData.ticketCategoryBreakdown.length >
                                  0 && (
                                  <div className="mt-3 pt-3 border-t">
                                    <p className="text-sm font-medium mb-2">
                                      Ticket Categories:
                                    </p>
                                    {eventData.ticketCategoryBreakdown
                                      .slice(0, 2)
                                      .map((category) => (
                                        <div
                                          key={category.name}
                                          className="flex justify-between text-xs"
                                        >
                                          <span>{category.name}:</span>
                                          <span>
                                            {category.ticketsSold} sold
                                          </span>
                                        </div>
                                      ))}
                                    {eventData.ticketCategoryBreakdown.length >
                                      2 && (
                                      <p className="text-xs text-gray-500 mt-1">
                                        +
                                        {eventData.ticketCategoryBreakdown
                                          .length - 2}{" "}
                                        more categories
                                      </p>
                                    )}
                                  </div>
                                )}
                            </div>
                          </CardContent>
                        </Card>
                      ))}
                    </div>
                  ) : (
                    <div className="text-center py-8">
                      <Calendar className="h-12 w-12 mx-auto text-gray-400 mb-4" />
                      <h3 className="text-lg font-medium text-gray-900 mb-2">
                        No Events Found
                      </h3>
                      <p className="text-gray-600">
                        {loading
                          ? "Loading events..."
                          : "You haven't created any events yet or there are no ticket sales to display."}
                      </p>
                    </div>
                  )}
                </CardContent>
              </Card>
            </>
          ) : (
            selectedEvent && (
              <>
                {/* Event Details View */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
                  <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                      <CardTitle className="text-sm font-medium">
                        Event Revenue
                      </CardTitle>
                      <DollarSign className="h-4 w-4 text-muted-foreground" />
                    </CardHeader>
                    <CardContent>
                      <div className="text-2xl font-bold">
                        ${selectedEvent.eventRevenue.toLocaleString()}
                      </div>
                      <p className="text-xs text-muted-foreground">
                        From {selectedEvent.ticketCount} tickets
                      </p>
                    </CardContent>
                  </Card>

                  <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                      <CardTitle className="text-sm font-medium">
                        Attendance Rate
                      </CardTitle>
                      <Users className="h-4 w-4 text-muted-foreground" />
                    </CardHeader>
                    <CardContent>
                      <div className="text-2xl font-bold">
                        {(selectedEvent.attendanceRate || 0).toFixed(1)}%
                      </div>
                      <p className="text-xs text-muted-foreground">
                        {selectedEvent.attendedCount || 0} of{" "}
                        {selectedEvent.ticketCount || 0} attended
                      </p>
                    </CardContent>
                  </Card>

                  <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                      <CardTitle className="text-sm font-medium">
                        Avg Ticket Price
                      </CardTitle>
                      <TrendingUp className="h-4 w-4 text-muted-foreground" />
                    </CardHeader>
                    <CardContent>
                      <div className="text-2xl font-bold">
                        ${(selectedEvent.averageTicketPrice || 0).toFixed(2)}
                      </div>
                      <p className="text-xs text-muted-foreground">
                        Average price per ticket
                      </p>
                    </CardContent>
                  </Card>
                </div>

                {/* Ticket Categories Breakdown */}
                {selectedEvent.ticketCategoryBreakdown &&
                  selectedEvent.ticketCategoryBreakdown.length > 0 && (
                    <Card className="mb-6">
                      <CardHeader>
                        <CardTitle className="flex items-center">
                          <PieChart className="h-5 w-5 mr-2" />
                          Ticket Categories Performance
                        </CardTitle>
                      </CardHeader>
                      <CardContent>
                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                          {(selectedEvent.ticketCategoryBreakdown || []).map(
                            (category) => (
                              <Card
                                key={category.name}
                                className="border-l-4 border-l-blue-500"
                              >
                                <CardHeader className="pb-2">
                                  <CardTitle className="text-lg">
                                    {category.name}
                                  </CardTitle>
                                  <CardDescription className="text-lg font-bold text-green-600">
                                    ${(category.price || 0).toFixed(2)}
                                  </CardDescription>
                                </CardHeader>
                                <CardContent>
                                  <div className="space-y-2">
                                    <div className="flex justify-between">
                                      <span className="text-sm text-gray-600">
                                        Sold:
                                      </span>
                                      <span className="font-medium">
                                        {category.ticketsSold}
                                      </span>
                                    </div>
                                    <div className="flex justify-between">
                                      <span className="text-sm text-gray-600">
                                        Revenue:
                                      </span>
                                      <span className="font-medium">
                                        ${category.revenue.toLocaleString()}
                                      </span>
                                    </div>
                                    <div className="flex justify-between">
                                      <span className="text-sm text-gray-600">
                                        Attended:
                                      </span>
                                      <span className="font-medium">
                                        {category.attendedCount}
                                      </span>
                                    </div>
                                    {category.description && (
                                      <p className="text-xs text-gray-500 mt-2">
                                        {category.description}
                                      </p>
                                    )}
                                  </div>
                                </CardContent>
                              </Card>
                            )
                          )}
                        </div>
                      </CardContent>
                    </Card>
                  )}
              </>
            )
          )}

          {/* Filters - Show only in overview mode or when viewing event details */}
          <Card className="mb-6">
            <CardContent className="pt-6">
              <div className="flex flex-col md:flex-row gap-4">
                <div className="flex-1">
                  <div className="relative">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                    <Input
                      placeholder="Search by customer name, email, event, or seat..."
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="pl-10"
                    />
                  </div>
                </div>
                {viewMode === "overview" && (
                  <Select value={eventFilter} onValueChange={setEventFilter}>
                    <SelectTrigger className="w-48">
                      <SelectValue placeholder="Filter by event" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Events</SelectItem>
                      {ticketsByEvent.map((eventData) => (
                        <SelectItem
                          key={eventData.event_id}
                          value={eventData.title}
                        >
                          {eventData.title}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                )}
                <Select value={statusFilter} onValueChange={setStatusFilter}>
                  <SelectTrigger className="w-48">
                    <SelectValue placeholder="Filter by status" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Status</SelectItem>
                    <SelectItem value="completed">Completed</SelectItem>
                    <SelectItem value="pending">Pending</SelectItem>
                    <SelectItem value="failed">Failed</SelectItem>
                  </SelectContent>
                </Select>
                <Select
                  value={attendanceFilter}
                  onValueChange={setAttendanceFilter}
                >
                  <SelectTrigger className="w-48">
                    <SelectValue placeholder="Filter by attendance" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All</SelectItem>
                    <SelectItem value="attended">Attended</SelectItem>
                    <SelectItem value="not-attended">Not Attended</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </CardContent>
          </Card>

          {/* Tickets List */}
          <div className="space-y-6">
            {filteredTickets.map((ticket) => (
              <Card
                key={ticket.ticket_id}
                className="hover:shadow-lg transition-shadow"
              >
                <CardHeader>
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <CardTitle className="text-lg flex items-center">
                        <Ticket className="h-5 w-5 mr-2 text-blue-600" />
                        {ticket.event?.title || "Unknown Event"}
                      </CardTitle>
                      <CardDescription className="mt-1 flex items-center">
                        <Calendar className="h-4 w-4 mr-1" />
                        {ticket.event?.start_time ? (
                          <>
                            {new Date(
                              ticket.event.start_time
                            ).toLocaleDateString()}{" "}
                            at{" "}
                            {new Date(
                              ticket.event.start_time
                            ).toLocaleTimeString()}
                          </>
                        ) : (
                          "Date TBD"
                        )}
                      </CardDescription>
                    </div>
                    <div className="flex flex-col items-end space-y-2">
                      <Badge
                        variant={
                          ticket.payment?.status === "completed"
                            ? "default"
                            : "destructive"
                        }
                      >
                        {ticket.payment?.status || "Unknown"}
                      </Badge>
                      {ticket.attended && (
                        <Badge variant="default" className="bg-green-600">
                          <Check className="h-3 w-3 mr-1" />
                          Attended
                        </Badge>
                      )}
                    </div>
                  </div>
                </CardHeader>
                <CardContent className="space-y-4">
                  {/* Customer Information */}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <h4 className="font-semibold text-sm text-gray-700">
                        Customer Details
                      </h4>
                      <div className="space-y-1">
                        <div className="flex items-center text-sm">
                          <User className="h-4 w-4 mr-2 text-gray-500" />
                          {ticket.user?.name || "Unknown"}
                        </div>
                        <div className="flex items-center text-sm text-gray-600">
                          <Mail className="h-4 w-4 mr-2 text-gray-500" />
                          {ticket.user?.email || "No email"}
                        </div>
                        {ticket.user?.phone_number && (
                          <div className="flex items-center text-sm text-gray-600">
                            <Phone className="h-4 w-4 mr-2 text-gray-500" />
                            {ticket.user.phone_number}
                          </div>
                        )}
                      </div>
                    </div>

                    <div className="space-y-2">
                      <h4 className="font-semibold text-sm text-gray-700">
                        Ticket Details
                      </h4>
                      <div className="space-y-1">
                        <div className="flex items-center text-sm">
                          <DollarSign className="h-4 w-4 mr-2 text-gray-500" />$
                          {ticket.price?.toFixed(2) || "0.00"}
                        </div>
                        {ticket.seat_label && (
                          <div className="flex items-center text-sm text-gray-600">
                            <MapPin className="h-4 w-4 mr-2 text-gray-500" />
                            Seat: {ticket.seat_label}
                          </div>
                        )}
                        <div className="flex items-center text-sm text-gray-600">
                          <CreditCard className="h-4 w-4 mr-2 text-gray-500" />
                          {ticket.payment?.payment_method || "N/A"}
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Purchase Information */}
                  <div className="p-3 bg-gray-50 rounded-lg">
                    <div className="flex justify-between items-center">
                      <div>
                        <span className="text-sm font-medium">
                          Purchase Date:
                        </span>
                        <p className="text-sm text-gray-600">
                          {new Date(ticket.purchase_date).toLocaleDateString()}{" "}
                          at{" "}
                          {new Date(ticket.purchase_date).toLocaleTimeString()}
                        </p>
                      </div>
                      <div className="text-right">
                        <span className="text-sm font-medium">Payment ID:</span>
                        <p className="text-sm text-gray-600 font-mono">
                          {ticket.payment?.payment_id?.slice(0, 8) || "N/A"}...
                        </p>
                      </div>
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="flex justify-between items-center pt-2 border-t">
                    <div className="flex space-x-2">
                      {!ticket.attended && (
                        <Button
                          size="sm"
                          variant="default"
                          onClick={() => markAsAttended(ticket.ticket_id)}
                        >
                          <Check className="h-4 w-4 mr-1" />
                          Mark Attended
                        </Button>
                      )}
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* Empty State */}
          {filteredTickets.length === 0 && (
            <Card className="text-center py-12">
              <CardContent>
                <Ticket className="h-12 w-12 mx-auto text-gray-400 mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">
                  No tickets found
                </h3>
                <p className="text-gray-600 mb-4">
                  {searchTerm ||
                  statusFilter !== "all" ||
                  eventFilter !== "all" ||
                  attendanceFilter !== "all"
                    ? "Try adjusting your filters to see more tickets."
                    : viewMode === "event-details"
                    ? "No tickets have been sold for this event yet."
                    : "No tickets have been sold for your events yet."}
                </p>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}
