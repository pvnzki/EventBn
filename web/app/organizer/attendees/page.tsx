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
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Checkbox } from "@/components/ui/checkbox";
import {
  Search,
  Eye,
  Edit,
  Users,
  Mail,
  Phone,
  Calendar,
  Download,
  Upload,
  QrCode,
  CheckCircle,
  XCircle,
  Clock,
  Send,
  Loader2,
} from "lucide-react";

interface User {
  role: "admin" | "organizer";
  name: string;
}

interface Attendee {
  ticket_id: string;
  event_id: number;
  user_id: number;
  seat_id?: number;
  seat_label?: string;
  purchase_date: string;
  price: number;
  attended: boolean;
  qr_code?: string;
  user: {
    name: string;
    email: string;
    phone_number?: string;
  };
  event: {
    title: string;
    start_time: string;
    venue?: string;
    location?: string;
    cover_image_url?: string;
  };
  payment?: {
    payment_id: string;
    status: string;
    payment_method?: string;
    payment_date: string;
  };
}

interface EventTickets {
  event: {
    event_id: number;
    title: string;
    start_time: string;
    end_time: string;
    venue?: string;
    location?: string;
    capacity?: number;
    cover_image_url?: string;
  };
  tickets: Attendee[];
  ticketCount: number;
  eventRevenue: number;
  attendedCount: number;
}

interface ApiResponse {
  success: boolean;
  tickets: Attendee[];
  events: any[];
  ticketsByEvent: EventTickets[];
  statistics: {
    totalTicketsSold: number;
    totalRevenue: number;
    totalEvents: number;
    averageTicketPrice: number;
  };
}

const mockAttendees: Attendee[] = [];

export default function AttendeesPage() {
  const [user, setUser] = useState<User | null>(null);
  const [attendees, setAttendees] = useState<Attendee[]>([]);
  const [ticketsByEvent, setTicketsByEvent] = useState<EventTickets[]>([]);
  const [statistics, setStatistics] = useState({
    totalTicketsSold: 0,
    totalRevenue: 0,
    totalEvents: 0,
    averageTicketPrice: 0,
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState("");
  const [eventFilter, setEventFilter] = useState("all");
  const [statusFilter, setStatusFilter] = useState("all");
  const [selectedAttendees, setSelectedAttendees] = useState<string[]>([]);
  const [isEmailDialogOpen, setIsEmailDialogOpen] = useState(false);
  const [emailData, setEmailData] = useState({
    subject: "",
    message: "",
  });

  useEffect(() => {
    const userData = localStorage.getItem("user");
    if (userData) {
      setUser(JSON.parse(userData));
    }
  }, []);

  useEffect(() => {
    fetchAttendees();
  }, []);

  const fetchAttendees = async () => {
    try {
      setLoading(true);
      setError(null);

      const token = localStorage.getItem("token");
      if (!token) {
        throw new Error("No authentication token found");
      }

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/api/tickets/my-events-tickets`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
          },
        }
      );

      if (!response.ok) {
        throw new Error(`Failed to fetch attendees: ${response.statusText}`);
      }

      const data: ApiResponse = await response.json();

      if (!data.success) {
        throw new Error("Failed to fetch attendees from server");
      }

      setAttendees(data.tickets || []);
      setTicketsByEvent(data.ticketsByEvent || []);
      setStatistics(
        data.statistics || {
          totalTicketsSold: 0,
          totalRevenue: 0,
          totalEvents: 0,
          averageTicketPrice: 0,
        }
      );
    } catch (error) {
      console.error("Error fetching attendees:", error);
      setError(
        error instanceof Error ? error.message : "Failed to fetch attendees"
      );
    } finally {
      setLoading(false);
    }
  };

  const isAdmin = user?.role === "admin";

  const getCheckInStatus = (
    attended: boolean
  ): "checked-in" | "not-checked-in" => {
    return attended ? "checked-in" : "not-checked-in";
  };

  const filteredAttendees = attendees.filter((attendee) => {
    const matchesSearch =
      attendee.user?.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      attendee.user?.email?.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesEvent =
      eventFilter === "all" || attendee.event?.title === eventFilter;

    const status = getCheckInStatus(attendee.attended);
    const matchesStatus = statusFilter === "all" || status === statusFilter;

    return matchesSearch && matchesEvent && matchesStatus;
  });

  const getStatusColor = (attended: boolean) => {
    return attended ? "default" : "secondary";
  };

  const getStatusIcon = (attended: boolean) => {
    return attended ? CheckCircle : Clock;
  };

  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      setSelectedAttendees(
        filteredAttendees.map((attendee) => attendee.ticket_id)
      );
    } else {
      setSelectedAttendees([]);
    }
  };

  const handleSelectAttendee = (attendeeId: string, checked: boolean) => {
    if (checked) {
      setSelectedAttendees([...selectedAttendees, attendeeId]);
    } else {
      setSelectedAttendees(selectedAttendees.filter((id) => id !== attendeeId));
    }
  };

  const handleCheckIn = async (ticketId: string) => {
    try {
      const token = localStorage.getItem("token");
      if (!token) {
        throw new Error("No authentication token found");
      }

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/api/tickets/${ticketId}/attend`,
        {
          method: "PUT",
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
          },
        }
      );

      if (!response.ok) {
        throw new Error(`Failed to check in attendee: ${response.statusText}`);
      }

      const data = await response.json();

      if (data.success) {
        // Update the local state
        setAttendees((prev) =>
          prev.map((attendee) =>
            attendee.ticket_id === ticketId
              ? { ...attendee, attended: true }
              : attendee
          )
        );

        // Update ticketsByEvent as well
        setTicketsByEvent((prev) =>
          prev.map((eventData) => ({
            ...eventData,
            tickets: eventData.tickets.map((ticket) =>
              ticket.ticket_id === ticketId
                ? { ...ticket, attended: true }
                : ticket
            ),
            attendedCount: eventData.tickets.filter((t) =>
              t.ticket_id === ticketId ? true : t.attended
            ).length,
          }))
        );
      }
    } catch (error) {
      console.error("Error checking in attendee:", error);
      // You could show a toast notification here
    }
  };

  const handleBulkEmail = () => {
    console.log("Sending email to:", selectedAttendees);
    console.log("Email data:", emailData);
    setIsEmailDialogOpen(false);
    setEmailData({ subject: "", message: "" });
  };

  const totalAttendees = statistics.totalTicketsSold;
  const checkedInCount = attendees.filter((a) => a.attended).length;
  const totalRevenue = statistics.totalRevenue;

  const uniqueEvents = [
    ...new Set(
      attendees.map((attendee) => attendee.event?.title).filter(Boolean)
    ),
  ];

  if (loading) {
    return (
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <div className="flex-1 lg:ml-64">
          <div className="flex items-center justify-center h-full">
            <div className="text-center">
              <Loader2 className="h-8 w-8 animate-spin mx-auto mb-4" />
              <p className="text-gray-600">Loading attendees...</p>
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
              <XCircle className="h-8 w-8 text-red-500 mx-auto mb-4" />
              <p className="text-red-600 mb-4">{error}</p>
              <Button onClick={fetchAttendees}>Try Again</Button>
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
                Attendee Management
              </h1>
              <p className="text-gray-600 mt-2">
                {isAdmin
                  ? "Manage all attendees across events"
                  : "Manage your event attendees and check-ins"}
              </p>
            </div>
            <div className="flex space-x-2">
              <Button variant="outline">
                <Upload className="h-4 w-4 mr-2" />
                Import
              </Button>
              <Button variant="outline">
                <Download className="h-4 w-4 mr-2" />
                Export
              </Button>
            </div>
          </div>

          {/* Stats Cards */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  Total Attendees
                </CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{totalAttendees}</div>
                <p className="text-xs text-muted-foreground">
                  Registered attendees
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  Checked In
                </CardTitle>
                <CheckCircle className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{checkedInCount}</div>
                <p className="text-xs text-muted-foreground">
                  {totalAttendees > 0
                    ? Math.round((checkedInCount / totalAttendees) * 100)
                    : 0}
                  % attendance rate
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Pending</CardTitle>
                <Clock className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {totalAttendees - checkedInCount}
                </div>
                <p className="text-xs text-muted-foreground">
                  Not yet checked in
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  Total Revenue
                </CardTitle>
                <Calendar className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  ${totalRevenue.toFixed(2)}
                </div>
                <p className="text-xs text-muted-foreground">
                  From ticket sales
                </p>
              </CardContent>
            </Card>
          </div>

          {/* Filters and Actions */}
          <Card className="mb-6">
            <CardContent className="pt-6">
              <div className="flex flex-col lg:flex-row gap-4">
                <div className="flex-1">
                  <div className="relative">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                    <Input
                      placeholder="Search attendees..."
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
                  <SelectTrigger className="w-40">
                    <SelectValue placeholder="Status" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Status</SelectItem>
                    <SelectItem value="checked-in">Checked In</SelectItem>
                    <SelectItem value="not-checked-in">
                      Not Checked In
                    </SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {/* Bulk Actions */}
              {selectedAttendees.length > 0 && (
                <div className="flex items-center justify-between mt-4 p-3 bg-blue-50 border border-blue-200 rounded-lg">
                  <span className="text-sm font-medium text-blue-800">
                    {selectedAttendees.length} attendee(s) selected
                  </span>
                  <div className="flex space-x-2">
                    <Dialog
                      open={isEmailDialogOpen}
                      onOpenChange={setIsEmailDialogOpen}
                    >
                      <DialogTrigger asChild>
                        <Button size="sm" variant="outline">
                          <Mail className="h-4 w-4 mr-1" />
                          Email Selected
                        </Button>
                      </DialogTrigger>
                      <DialogContent>
                        <DialogHeader>
                          <DialogTitle>
                            Send Email to Selected Attendees
                          </DialogTitle>
                          <DialogDescription>
                            Send an email to {selectedAttendees.length} selected
                            attendee(s).
                          </DialogDescription>
                        </DialogHeader>
                        <div className="space-y-4">
                          <div className="space-y-2">
                            <Label htmlFor="email-subject">Subject</Label>
                            <Input
                              id="email-subject"
                              placeholder="Email subject..."
                              value={emailData.subject}
                              onChange={(e) =>
                                setEmailData({
                                  ...emailData,
                                  subject: e.target.value,
                                })
                              }
                            />
                          </div>
                          <div className="space-y-2">
                            <Label htmlFor="email-message">Message</Label>
                            <Textarea
                              id="email-message"
                              rows={6}
                              placeholder="Your message..."
                              value={emailData.message}
                              onChange={(e) =>
                                setEmailData({
                                  ...emailData,
                                  message: e.target.value,
                                })
                              }
                            />
                          </div>
                          <div className="flex justify-end space-x-2">
                            <Button
                              variant="outline"
                              onClick={() => setIsEmailDialogOpen(false)}
                            >
                              Cancel
                            </Button>
                            <Button onClick={handleBulkEmail}>
                              <Send className="h-4 w-4 mr-2" />
                              Send Email
                            </Button>
                          </div>
                        </div>
                      </DialogContent>
                    </Dialog>
                    <Button size="sm" variant="outline">
                      <Download className="h-4 w-4 mr-1" />
                      Export Selected
                    </Button>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Attendees Table */}
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>Attendees ({filteredAttendees.length})</CardTitle>
                  <CardDescription>
                    Manage attendee information and check-in status
                  </CardDescription>
                </div>
                <div className="flex items-center space-x-2">
                  <Checkbox
                    checked={
                      filteredAttendees.length > 0 &&
                      selectedAttendees.length === filteredAttendees.length
                    }
                    onCheckedChange={handleSelectAll}
                  />
                  <Label className="text-sm">Select All</Label>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {filteredAttendees.map((attendee) => {
                  const attended = attendee.attended;
                  const StatusIcon = getStatusIcon(attended);
                  const status = getCheckInStatus(attended);

                  return (
                    <div
                      key={attendee.ticket_id}
                      className="flex items-center justify-between p-4 border rounded-lg hover:bg-gray-50"
                    >
                      <div className="flex items-center space-x-4">
                        <Checkbox
                          checked={selectedAttendees.includes(
                            attendee.ticket_id
                          )}
                          onCheckedChange={(checked) =>
                            handleSelectAttendee(
                              attendee.ticket_id,
                              checked as boolean
                            )
                          }
                        />

                        <Avatar>
                          <AvatarImage
                            src="/placeholder.svg"
                            alt={attendee.user?.name || "User"}
                          />
                          <AvatarFallback>
                            {attendee.user?.name
                              ?.split(" ")
                              .map((n) => n[0])
                              .join("") || "U"}
                          </AvatarFallback>
                        </Avatar>

                        <div className="flex-1">
                          <div className="flex items-center space-x-3">
                            <h3 className="font-semibold text-gray-900">
                              {attendee.user?.name || "Unknown User"}
                            </h3>
                            <Badge variant={getStatusColor(attended)}>
                              <StatusIcon className="h-3 w-3 mr-1" />
                              {status.replace("-", " ")}
                            </Badge>
                            {attendee.seat_label && (
                              <Badge variant="outline">
                                Seat {attendee.seat_label}
                              </Badge>
                            )}
                          </div>

                          <div className="flex items-center space-x-6 mt-1 text-sm text-gray-600">
                            <div className="flex items-center">
                              <Mail className="h-3 w-3 mr-1" />
                              {attendee.user?.email || "No email"}
                            </div>
                            {attendee.user?.phone_number && (
                              <div className="flex items-center">
                                <Phone className="h-3 w-3 mr-1" />
                                {attendee.user.phone_number}
                              </div>
                            )}
                            <div className="flex items-center">
                              <Calendar className="h-3 w-3 mr-1" />
                              {attendee.event?.title || "Unknown Event"}
                            </div>
                          </div>

                          {(attendee.event?.venue ||
                            attendee.event?.location) && (
                            <div className="flex items-center space-x-4 mt-1 text-sm text-gray-600">
                              {attendee.event?.venue && (
                                <span>{attendee.event.venue}</span>
                              )}
                              {attendee.event?.location && (
                                <span>• {attendee.event.location}</span>
                              )}
                            </div>
                          )}

                          <div className="text-sm text-blue-600 mt-1">
                            Purchased:{" "}
                            {new Date(attendee.purchase_date).toLocaleString()}
                          </div>
                        </div>
                      </div>

                      <div className="flex items-center space-x-2">
                        <div className="text-right mr-4">
                          <div className="font-semibold">
                            ${attendee.price.toFixed(2)}
                          </div>
                          <div className="text-sm text-gray-600">
                            {attendee.payment?.payment_method || "Card"}
                          </div>
                        </div>

                        <div className="flex space-x-1">
                          {!attended && (
                            <Button
                              size="sm"
                              onClick={() => handleCheckIn(attendee.ticket_id)}
                            >
                              <CheckCircle className="h-4 w-4 mr-1" />
                              Check In
                            </Button>
                          )}
                          {attendee.qr_code && (
                            <Button size="sm" variant="ghost">
                              <QrCode className="h-4 w-4" />
                            </Button>
                          )}
                          <Button size="sm" variant="ghost">
                            <Eye className="h-4 w-4" />
                          </Button>
                          <Button size="sm" variant="ghost">
                            <Mail className="h-4 w-4" />
                          </Button>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>

              {/* Empty State */}
              {filteredAttendees.length === 0 && (
                <div className="text-center py-12">
                  <Users className="h-12 w-12 mx-auto text-gray-400 mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 mb-2">
                    No attendees found
                  </h3>
                  <p className="text-gray-600">
                    {searchTerm ||
                    eventFilter !== "all" ||
                    statusFilter !== "all"
                      ? "Try adjusting your filters to see more attendees."
                      : "Attendees will appear here once tickets are purchased."}
                  </p>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
