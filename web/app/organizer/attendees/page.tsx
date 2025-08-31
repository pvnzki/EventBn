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
} from "lucide-react";

interface User {
  role: "admin" | "organizer";
  name: string;
}

interface Attendee {
  id: string;
  eventId: string;
  eventName: string;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  ticketType: string;
  ticketPrice: number;
  purchaseDate: string;
  checkInStatus: "checked-in" | "not-checked-in" | "no-show";
  checkInTime?: string;
  company?: string;
  jobTitle?: string;
  dietaryRestrictions?: string;
  specialRequests?: string;
  avatar?: string;
  qrCode: string;
}

const mockAttendees: Attendee[] = [
  {
    id: "1",
    eventId: "1",
    eventName: "Tech Conference 2024",
    firstName: "John",
    lastName: "Smith",
    email: "john.smith@example.com",
    phone: "+1 (555) 123-4567",
    ticketType: "General Admission",
    ticketPrice: 99,
    purchaseDate: "2024-01-15",
    checkInStatus: "checked-in",
    checkInTime: "2024-03-15 09:30:00",
    company: "Tech Corp",
    jobTitle: "Software Engineer",
    qrCode: "QR123456789",
    avatar: "/placeholder.svg?height=40&width=40",
  },
  {
    id: "2",
    eventId: "1",
    eventName: "Tech Conference 2024",
    firstName: "Sarah",
    lastName: "Johnson",
    email: "sarah.johnson@example.com",
    phone: "+1 (555) 987-6543",
    ticketType: "VIP Pass",
    ticketPrice: 299,
    purchaseDate: "2024-01-20",
    checkInStatus: "not-checked-in",
    company: "StartupXYZ",
    jobTitle: "Product Manager",
    dietaryRestrictions: "Vegetarian",
    qrCode: "QR987654321",
    avatar: "/placeholder.svg?height=40&width=40",
  },
  {
    id: "3",
    eventId: "2",
    eventName: "Music Festival Summer",
    firstName: "Mike",
    lastName: "Davis",
    email: "mike.davis@example.com",
    phone: "+1 (555) 456-7890",
    ticketType: "Regular Admission",
    ticketPrice: 120,
    purchaseDate: "2024-02-10",
    checkInStatus: "checked-in",
    checkInTime: "2024-06-20 14:15:00",
    specialRequests: "Wheelchair accessible seating",
    qrCode: "QR456789123",
    avatar: "/placeholder.svg?height=40&width=40",
  },
  {
    id: "4",
    eventId: "1",
    eventName: "Tech Conference 2024",
    firstName: "Emily",
    lastName: "Brown",
    email: "emily.brown@example.com",
    phone: "+1 (555) 321-0987",
    ticketType: "General Admission",
    ticketPrice: 99,
    purchaseDate: "2024-02-05",
    checkInStatus: "no-show",
    company: "Design Studio",
    jobTitle: "UX Designer",
    qrCode: "QR321098765",
    avatar: "/placeholder.svg?height=40&width=40",
  },
  {
    id: "5",
    eventId: "3",
    eventName: "Business Workshop",
    firstName: "David",
    lastName: "Wilson",
    email: "david.wilson@example.com",
    phone: "+1 (555) 654-3210",
    ticketType: "Workshop Access",
    ticketPrice: 150,
    purchaseDate: "2024-03-01",
    checkInStatus: "not-checked-in",
    company: "Consulting Firm",
    jobTitle: "Business Analyst",
    dietaryRestrictions: "Gluten-free",
    qrCode: "QR654321098",
    avatar: "/placeholder.svg?height=40&width=40",
  },
];

export default function AttendeesPage() {
  const [user, setUser] = useState<User | null>(null);
  const [attendees, setAttendees] = useState<Attendee[]>(mockAttendees);
  const [searchTerm, setSearchTerm] = useState("");
  const [eventFilter, setEventFilter] = useState("all");
  const [statusFilter, setStatusFilter] = useState("all");
  const [ticketFilter, setTicketFilter] = useState("all");
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

  const isAdmin = user?.role === "admin";

  const filteredAttendees = attendees.filter((attendee) => {
    const matchesSearch =
      attendee.firstName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      attendee.lastName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      attendee.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
      attendee.company?.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesEvent =
      eventFilter === "all" || attendee.eventName === eventFilter;
    const matchesStatus =
      statusFilter === "all" || attendee.checkInStatus === statusFilter;
    const matchesTicket =
      ticketFilter === "all" || attendee.ticketType === ticketFilter;

    return matchesSearch && matchesEvent && matchesStatus && matchesTicket;
  });

  const getStatusColor = (status: string) => {
    switch (status) {
      case "checked-in":
        return "default";
      case "not-checked-in":
        return "secondary";
      case "no-show":
        return "destructive";
      default:
        return "secondary";
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case "checked-in":
        return CheckCircle;
      case "not-checked-in":
        return Clock;
      case "no-show":
        return XCircle;
      default:
        return Clock;
    }
  };

  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      setSelectedAttendees(filteredAttendees.map((attendee) => attendee.id));
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

  const handleCheckIn = (attendeeId: string) => {
    setAttendees(
      attendees.map((attendee) =>
        attendee.id === attendeeId
          ? {
              ...attendee,
              checkInStatus: "checked-in" as const,
              checkInTime: new Date().toISOString(),
            }
          : attendee
      )
    );
  };

  const handleBulkEmail = () => {
    console.log("Sending email to:", selectedAttendees);
    console.log("Email data:", emailData);
    setIsEmailDialogOpen(false);
    setEmailData({ subject: "", message: "" });
  };

  const totalAttendees = attendees.length;
  const checkedInCount = attendees.filter(
    (a) => a.checkInStatus === "checked-in"
  ).length;
  const noShowCount = attendees.filter(
    (a) => a.checkInStatus === "no-show"
  ).length;
  const totalRevenue = attendees.reduce(
    (sum, attendee) => sum + attendee.ticketPrice,
    0
  );

  const uniqueEvents = [
    ...new Set(attendees.map((attendee) => attendee.eventName)),
  ];
  const uniqueTicketTypes = [
    ...new Set(attendees.map((attendee) => attendee.ticketType)),
  ];

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
                <CardTitle className="text-sm font-medium">No Shows</CardTitle>
                <XCircle className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{noShowCount}</div>
                <p className="text-xs text-muted-foreground">
                  {totalAttendees > 0
                    ? Math.round((noShowCount / totalAttendees) * 100)
                    : 0}
                  % no-show rate
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
                  ${totalRevenue.toLocaleString()}
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
                    <SelectItem value="no-show">No Show</SelectItem>
                  </SelectContent>
                </Select>
                <Select value={ticketFilter} onValueChange={setTicketFilter}>
                  <SelectTrigger className="w-40">
                    <SelectValue placeholder="Ticket Type" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Tickets</SelectItem>
                    {uniqueTicketTypes.map((ticket) => (
                      <SelectItem key={ticket} value={ticket}>
                        {ticket}
                      </SelectItem>
                    ))}
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
                  const StatusIcon = getStatusIcon(attendee.checkInStatus);

                  return (
                    <div
                      key={attendee.id}
                      className="flex items-center justify-between p-4 border rounded-lg hover:bg-gray-50"
                    >
                      <div className="flex items-center space-x-4">
                        <Checkbox
                          checked={selectedAttendees.includes(attendee.id)}
                          onCheckedChange={(checked) =>
                            handleSelectAttendee(
                              attendee.id,
                              checked as boolean
                            )
                          }
                        />

                        <Avatar>
                          <AvatarImage
                            src={attendee.avatar || "/placeholder.svg"}
                            alt={attendee.firstName}
                          />
                          <AvatarFallback>
                            {attendee.firstName[0]}
                            {attendee.lastName[0]}
                          </AvatarFallback>
                        </Avatar>

                        <div className="flex-1">
                          <div className="flex items-center space-x-3">
                            <h3 className="font-semibold text-gray-900">
                              {attendee.firstName} {attendee.lastName}
                            </h3>
                            <Badge
                              variant={getStatusColor(attendee.checkInStatus)}
                            >
                              <StatusIcon className="h-3 w-3 mr-1" />
                              {attendee.checkInStatus.replace("-", " ")}
                            </Badge>
                            <Badge variant="outline">
                              {attendee.ticketType}
                            </Badge>
                          </div>

                          <div className="flex items-center space-x-6 mt-1 text-sm text-gray-600">
                            <div className="flex items-center">
                              <Mail className="h-3 w-3 mr-1" />
                              {attendee.email}
                            </div>
                            <div className="flex items-center">
                              <Phone className="h-3 w-3 mr-1" />
                              {attendee.phone}
                            </div>
                            <div className="flex items-center">
                              <Calendar className="h-3 w-3 mr-1" />
                              {attendee.eventName}
                            </div>
                          </div>

                          {(attendee.company || attendee.jobTitle) && (
                            <div className="flex items-center space-x-4 mt-1 text-sm text-gray-600">
                              {attendee.company && (
                                <span>{attendee.company}</span>
                              )}
                              {attendee.jobTitle && (
                                <span>• {attendee.jobTitle}</span>
                              )}
                            </div>
                          )}

                          {attendee.checkInTime && (
                            <div className="text-sm text-green-600 mt-1">
                              Checked in:{" "}
                              {new Date(attendee.checkInTime).toLocaleString()}
                            </div>
                          )}

                          {(attendee.dietaryRestrictions ||
                            attendee.specialRequests) && (
                            <div className="text-sm text-orange-600 mt-1">
                              {attendee.dietaryRestrictions &&
                                `Dietary: ${attendee.dietaryRestrictions}`}
                              {attendee.specialRequests &&
                                ` • Special: ${attendee.specialRequests}`}
                            </div>
                          )}
                        </div>
                      </div>

                      <div className="flex items-center space-x-2">
                        <div className="text-right mr-4">
                          <div className="font-semibold">
                            ${attendee.ticketPrice}
                          </div>
                          <div className="text-sm text-gray-600">
                            Purchased:{" "}
                            {new Date(
                              attendee.purchaseDate
                            ).toLocaleDateString()}
                          </div>
                        </div>

                        <div className="flex space-x-1">
                          {attendee.checkInStatus === "not-checked-in" && (
                            <Button
                              size="sm"
                              onClick={() => handleCheckIn(attendee.id)}
                            >
                              <CheckCircle className="h-4 w-4 mr-1" />
                              Check In
                            </Button>
                          )}
                          <Button size="sm" variant="ghost">
                            <QrCode className="h-4 w-4" />
                          </Button>
                          <Button size="sm" variant="ghost">
                            <Eye className="h-4 w-4" />
                          </Button>
                          <Button size="sm" variant="ghost">
                            <Edit className="h-4 w-4" />
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
                    statusFilter !== "all" ||
                    ticketFilter !== "all"
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
