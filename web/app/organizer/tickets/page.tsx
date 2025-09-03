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
  Download,
  Mail,
  Calendar,
  MapPin,
  User,
  Phone,
  CreditCard,
  Check,
  X,
  RefreshCw,
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
  event: EventData;
  tickets: TicketPurchase[];
  ticketCount: number;
  eventRevenue: number;
  attendedCount: number;
}

interface Statistics {
  totalTicketsSold: number;
  totalRevenue: number;
  totalEvents: number;
  averageTicketPrice: number;
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
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [eventFilter, setEventFilter] = useState("all");
  const [attendanceFilter, setAttendanceFilter] = useState("all");

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
        "http://localhost:3000/api/tickets/my-events-tickets",
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

      if (data.success) {
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
        `http://localhost:3000/api/tickets/${ticketId}/attend`,
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

  const filteredTickets = tickets.filter((ticket) => {
    const matchesSearch =
      ticket.user?.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      ticket.user?.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      ticket.event?.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (ticket.seat_label &&
        ticket.seat_label.toLowerCase().includes(searchTerm.toLowerCase()));

    const matchesStatus =
      statusFilter === "all" || ticket.payment?.status === statusFilter;

    const matchesEvent =
      eventFilter === "all" || ticket.event?.title === eventFilter;

    const matchesAttendance =
      attendanceFilter === "all" ||
      (attendanceFilter === "attended" && ticket.attended) ||
      (attendanceFilter === "not-attended" && !ticket.attended);

    return matchesSearch && matchesStatus && matchesEvent && matchesAttendance;
  });

  const uniqueEvents = [
    ...new Set(tickets.map((ticket) => ticket.event?.title).filter(Boolean)),
  ];
  const uniqueStatuses = [
    ...new Set(tickets.map((ticket) => ticket.payment?.status).filter(Boolean)),
  ];

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
            <div>
              <h1 className="text-3xl font-bold text-gray-900">
                Ticket Management
              </h1>
              <p className="text-gray-600 mt-2">
                {isAdmin
                  ? "Manage all tickets across the platform"
                  : "Manage tickets for your events"}
              </p>
            </div>
            <Button onClick={refreshData}>
              <RefreshCw className="h-4 w-4 mr-2" />
              Refresh Data
            </Button>
          </div>

          {/* Stats Cards */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
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
                  Active Events
                </CardTitle>
                <Calendar className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {statistics.totalEvents}
                </div>
                <p className="text-xs text-muted-foreground">
                  Events with tickets sold
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
                  ${statistics.averageTicketPrice.toFixed(2)}
                </div>
                <p className="text-xs text-muted-foreground">
                  Average per ticket
                </p>
              </CardContent>
            </Card>
          </div>

          {/* Filters */}
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
                <Select value={eventFilter} onValueChange={setEventFilter}>
                  <SelectTrigger className="w-48">
                    <SelectValue placeholder="Filter by event" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Events</SelectItem>
                    {uniqueEvents.map((event) => (
                      <SelectItem key={event} value={event}>
                        {event}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <Select value={statusFilter} onValueChange={setStatusFilter}>
                  <SelectTrigger className="w-48">
                    <SelectValue placeholder="Filter by status" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Status</SelectItem>
                    {uniqueStatuses.map((status) => (
                      <SelectItem key={status} value={status}>
                        {status.charAt(0).toUpperCase() + status.slice(1)}
                      </SelectItem>
                    ))}
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
                    <div className="flex space-x-2">
                      <Button size="sm" variant="outline">
                        <Download className="h-4 w-4 mr-1" />
                        Export
                      </Button>
                      <Button size="sm" variant="outline">
                        <Mail className="h-4 w-4 mr-1" />
                        Email Customer
                      </Button>
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
