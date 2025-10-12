"use client";

import { useState, useEffect } from "react";
import { useRouter, useParams } from "next/navigation";
import { Sidebar } from "@/components/layout/sidebar";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  ArrowLeft,
  Calendar,
  MapPin,
  Users,
  Edit,
  Trash2,
  Clock,
  DollarSign,
  Tag,
  Building,
  Image as ImageIcon,
  Video,
} from "lucide-react";
import { useToast } from "@/components/ui/use-toast";

interface Seat {
  id: number;
  label: string;
  price: number;
  available: boolean;
  booked?: boolean;
  ticketType: string;
}

interface TicketType {
  ticket_type_id: string;
  name: string;
  price: number;
  quantity: number;
}

interface Event {
  event_id: number;
  organization_id: number | null;
  title: string;
  description: string | null;
  category: string | null;
  venue: string | null;
  location: string | null;
  start_time: string;
  end_time: string;
  capacity: number | null;
  cover_image_url: string | null;
  other_images_url: string | null;
  video_url: string | null;
  seat_map: string | null;
  created_at: string;
  updated_at: string;
  status: string | null;
  organization?: {
    name: string;
    organization_id: number;
    logo_url: string;
  } | null;
  ticketsSold?: number;
  revenue?: number;
  ticket_types?: TicketType[];
}

export default function EventDetailsPage() {
  const router = useRouter();
  const params = useParams();
  const { toast } = useToast();
  const eventId = params?.id as string;

  const [event, setEvent] = useState<Event | null>(null);
  const [ticketTypes, setTicketTypes] = useState<TicketType[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchEventDetails = async () => {
      try {
        const token = localStorage.getItem("token");
        console.log("Fetching event details for ID:", eventId);

        const response = await fetch(
          `http://localhost:3001/api/events/${eventId}`,
          {
            headers: {
              Authorization: `Bearer ${token}`,
            },
          }
        );

        console.log("Response status:", response.status);

        if (response.ok) {
          const data = await response.json();
          console.log("Event data received:", data);
          const eventData = data.event || data.data || data;
          console.log("Extracted event data:", eventData);
          setEvent(eventData);

          // Check if event data already includes ticket_types
          if (eventData.ticket_types && Array.isArray(eventData.ticket_types)) {
            console.log(
              "Ticket types from event data:",
              eventData.ticket_types
            );
            setTicketTypes(eventData.ticket_types);
          } else {
            // Fetch ticket types for this event
            try {
              const ticketResponse = await fetch(
                `http://localhost:3001/api/events/${eventId}/ticket-types`,
                {
                  headers: {
                    Authorization: `Bearer ${token}`,
                  },
                }
              );

              console.log("Ticket response status:", ticketResponse.status);

              if (ticketResponse.ok) {
                const ticketData = await ticketResponse.json();
                console.log("Ticket types API response:", ticketData);
                const types =
                  ticketData.ticketTypes || ticketData.data || ticketData || [];
                console.log("Extracted ticket types:", types);
                setTicketTypes(Array.isArray(types) ? types : []);
              } else {
                const errorText = await ticketResponse.text();
                console.error("Ticket types API error:", errorText);
              }
            } catch (ticketError) {
              console.error("Error fetching ticket types:", ticketError);
            }
          }
        } else {
          const errorText = await response.text();
          console.error("Error response:", errorText);
          toast({
            title: "Error",
            description: "Failed to load event details",
            variant: "destructive",
          });
        }
      } catch (error) {
        console.error("Error fetching event:", error);
        toast({
          title: "Error",
          description: "Failed to load event details",
          variant: "destructive",
        });
      } finally {
        setIsLoading(false);
      }
    };

    if (eventId) {
      fetchEventDetails();
    }
  }, [eventId, toast]);

  const getEventStatus = (event: Event) => {
    const now = new Date();
    const startTime = new Date(event.start_time);
    const endTime = new Date(event.end_time);

    // Check if event has ended
    if (endTime < now) {
      return {
        status: "COMPLETED",
        variant: "secondary" as const,
        color: "#6b7280",
      };
    }

    // Check if all tickets are sold (sold out)
    if (
      event.capacity &&
      event.ticketsSold &&
      event.ticketsSold >= event.capacity
    ) {
      return {
        status: "SOLD OUT",
        variant: "destructive" as const,
        color: "#ef4444",
      };
    }

    // Check if event is upcoming/active
    if (startTime > now) {
      return {
        status: "UPCOMING",
        variant: "default" as const,
        color: "#3b82f6",
      };
    }

    // Event is currently happening
    if (startTime <= now && endTime >= now) {
      return {
        status: "ONGOING",
        variant: "default" as const,
        color: "#22c55e",
      };
    }

    // Default to active
    return { status: "ACTIVE", variant: "default" as const, color: "#22c55e" };
  };

  const formatDate = (dateString: string) => {
    try {
      return new Date(dateString).toLocaleString("en-US", {
        dateStyle: "medium",
        timeStyle: "short",
      });
    } catch (error) {
      console.error("Error formatting date:", dateString, error);
      return dateString;
    }
  };

  if (isLoading) {
    return (
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <main className="flex-1 p-8">
          <div className="flex items-center justify-center h-full">
            <div className="text-lg">Loading event details...</div>
          </div>
        </main>
      </div>
    );
  }

  if (!event) {
    return (
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <main className="flex-1 p-6">
          <div className="flex items-center justify-center h-full">
            <div className="text-lg">Event not found</div>
          </div>
        </main>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />
      <main className="flex-1 p-4 overflow-auto lg:ml-64">
        {/* Header */}
        <div className="mb-4">
          <Button
            variant="ghost"
            onClick={() => router.back()}
            className="mb-3"
          >
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back
          </Button>
          <div className="flex justify-between items-start">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">
                {event.title}
              </h1>
              <p className="text-gray-500 text-sm mt-1">Event Details</p>
            </div>
            <div className="flex space-x-2">
              <Button
                onClick={() =>
                  router.push(`/organizer/edit-event?id=${event.event_id}`)
                }
                size="sm"
              >
                <Edit className="h-4 w-4 mr-2" />
                Edit Event
              </Button>
            </div>
          </div>
        </div>

        {/* Cover Image */}
        {event.cover_image_url && (
          <Card className="mb-4 overflow-hidden">
            <div className="relative h-64 w-full">
              <img
                src={event.cover_image_url}
                alt={event.title}
                className="w-full h-full object-cover"
              />
            </div>
          </Card>
        )}

        <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
          {/* Main Information */}
          <div className="md:col-span-3 space-y-4">
            {/* Basic Info */}
            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-lg">Event Information</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div>
                  <h3 className="font-semibold text-gray-700 mb-1 text-sm">
                    Description
                  </h3>
                  <p className="text-gray-600 text-sm whitespace-pre-wrap line-clamp-4">
                    {event.description || "No description provided"}
                  </p>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <h3 className="font-semibold text-gray-700 mb-1 flex items-center text-sm">
                      <Tag className="h-3 w-3 mr-1" />
                      Category
                    </h3>
                    <Badge variant="secondary" className="text-xs">
                      {event.category || "N/A"}
                    </Badge>
                  </div>

                  <div>
                    <h3 className="font-semibold text-gray-700 mb-1 flex items-center text-sm">
                      <Users className="h-3 w-3 mr-1" />
                      Capacity
                    </h3>
                    <p className="text-gray-600 text-sm">
                      {event.capacity || "Unlimited"}
                    </p>
                  </div>

                  <div>
                    <h3 className="font-semibold text-gray-700 mb-1 flex items-center text-sm">
                      <Calendar className="h-3 w-3 mr-1" />
                      Start Time
                    </h3>
                    <p className="text-gray-600 text-sm">
                      {formatDate(event.start_time)}
                    </p>
                  </div>

                  <div>
                    <h3 className="font-semibold text-gray-700 mb-1 flex items-center text-sm">
                      <Clock className="h-3 w-3 mr-1" />
                      End Time
                    </h3>
                    <p className="text-gray-600 text-sm">
                      {formatDate(event.end_time)}
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Location */}
            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="flex items-center text-lg">
                  <MapPin className="h-4 w-4 mr-2" />
                  Location
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2">
                  <div>
                    <h3 className="font-semibold text-gray-700 text-sm">
                      Venue
                    </h3>
                    <p className="text-gray-600 text-sm">
                      {event.venue || "N/A"}
                    </p>
                  </div>
                  <div>
                    <h3 className="font-semibold text-gray-700 text-sm">
                      Address
                    </h3>
                    <p className="text-gray-600 text-sm">
                      {event.location || "N/A"}
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Media */}
            {(event.other_images_url || event.video_url) && (
              <Card>
                <CardHeader className="pb-3">
                  <CardTitle className="flex items-center text-lg">
                    <ImageIcon className="h-4 w-4 mr-2" />
                    Media
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-3">
                  {event.other_images_url && (
                    <div>
                      <h3 className="font-semibold text-gray-700 mb-2 text-sm">
                        Additional Images
                      </h3>
                      <div className="grid grid-cols-3 gap-2">
                        {(() => {
                          let urls: string[] = [];

                          // Parse the other_images_url - it could be a JSON string array or comma-separated
                          if (typeof event.other_images_url === "string") {
                            try {
                              // Try parsing as JSON array first
                              const parsed = JSON.parse(event.other_images_url);
                              if (Array.isArray(parsed)) {
                                urls = parsed;
                              } else {
                                urls = [parsed];
                              }
                            } catch {
                              // If not JSON, treat as comma-separated
                              urls = event.other_images_url
                                .split(",")
                                .map((u) => u.trim());
                            }
                          } else if (Array.isArray(event.other_images_url)) {
                            urls = event.other_images_url;
                          } else {
                            urls = [String(event.other_images_url)];
                          }

                          return urls.map((url, index) => (
                            <div
                              key={index}
                              className="relative h-24 rounded-lg overflow-hidden bg-gray-100"
                            >
                              <img
                                src={url}
                                alt={`Additional image ${index + 1}`}
                                className="w-full h-full object-cover"
                                onError={(e) => {
                                  console.error("Image failed to load:", url);
                                }}
                              />
                            </div>
                          ));
                        })()}
                      </div>
                    </div>
                  )}

                  {event.video_url && (
                    <div>
                      <h3 className="font-semibold text-gray-700 mb-2 flex items-center text-sm">
                        <Video className="h-3 w-3 mr-1" />
                        Video
                      </h3>
                      <video
                        controls
                        className="w-full rounded-lg max-h-48"
                        src={event.video_url}
                      >
                        Your browser does not support the video tag.
                      </video>
                    </div>
                  )}
                </CardContent>
              </Card>
            )}

            {/* Seat Map */}
            {event.seat_map && (
              <Card>
                <CardHeader className="pb-3">
                  <CardTitle className="flex items-center text-lg">
                    <Users className="h-4 w-4 mr-2" />
                    Seat Map
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  {(() => {
                    let seats: Seat[] = [];
                    try {
                      seats =
                        typeof event.seat_map === "string"
                          ? JSON.parse(event.seat_map)
                          : event.seat_map;
                    } catch (error) {
                      console.error("Failed to parse seat map:", error);
                      return (
                        <p className="text-sm text-gray-500">
                          Invalid seat map data
                        </p>
                      );
                    }

                    if (!Array.isArray(seats) || seats.length === 0) {
                      return (
                        <p className="text-sm text-gray-500">
                          No seats configured
                        </p>
                      );
                    }

                    console.log("All seats data:", seats);
                    console.log("Sample seats:", seats.slice(0, 5));

                    // Group seats by row (first letter of label)
                    const rowMap = new Map<string, Seat[]>();
                    seats.forEach((seat) => {
                      const row = seat.label.charAt(0);
                      if (!rowMap.has(row)) {
                        rowMap.set(row, []);
                      }
                      rowMap.get(row)!.push(seat);
                    });

                    // Sort rows alphabetically
                    const sortedRows = Array.from(rowMap.keys()).sort();

                    // Group seats by ticket type/category to get unique categories
                    const categoryMap = new Map<
                      string,
                      { price: number; count: number; available: number }
                    >();
                    seats.forEach((seat) => {
                      const key = `${seat.ticketType}-${seat.price}`;
                      if (!categoryMap.has(key)) {
                        categoryMap.set(key, {
                          price: seat.price,
                          count: 0,
                          available: 0,
                        });
                      }
                      const cat = categoryMap.get(key)!;
                      cat.count++;
                      if (seat.available && !seat.booked) cat.available++;
                    });

                    // Generate colors for each category
                    const categoryColors = [
                      { bg: "#3b82f6", border: "#1e40af", name: "Premium" }, // blue
                      { bg: "#8b5cf6", border: "#6d28d9", name: "Standard" }, // purple
                      { bg: "#ec4899", border: "#be185d", name: "Economy" }, // pink
                      { bg: "#f59e0b", border: "#d97706", name: "VIP" }, // amber
                      { bg: "#14b8a6", border: "#0f766e", name: "Balcony" }, // teal
                    ];

                    const ticketTypeColors = new Map<
                      string,
                      { bg: string; border: string; name: string }
                    >();
                    Array.from(categoryMap.keys()).forEach((key, index) => {
                      ticketTypeColors.set(
                        key,
                        categoryColors[index % categoryColors.length]
                      );
                    });

                    // Calculate statistics
                    const totalSeats = seats.length;
                    const availableSeats = seats.filter(
                      (s) => s.available && !s.booked
                    ).length;
                    const bookedSeats = seats.filter(
                      (s) => s.booked || !s.available
                    ).length;

                    return (
                      <div className="space-y-4">
                        {/* Statistics */}
                        <div className="grid grid-cols-3 gap-2 p-3 bg-gray-50 rounded-lg">
                          <div className="text-center">
                            <div
                              className="text-lg font-bold"
                              style={{ color: "#111827" }}
                            >
                              {totalSeats}
                            </div>
                            <div className="text-xs text-gray-600">Total</div>
                          </div>
                          <div className="text-center">
                            <div
                              className="text-lg font-bold"
                              style={{ color: "#22c55e" }}
                            >
                              {availableSeats}
                            </div>
                            <div className="text-xs text-gray-600">
                              Available
                            </div>
                          </div>
                          <div className="text-center">
                            <div
                              className="text-lg font-bold"
                              style={{ color: "#ef4444" }}
                            >
                              {bookedSeats}
                            </div>
                            <div className="text-xs text-gray-600">Booked</div>
                          </div>
                        </div>

                        {/* Legend - Categories */}
                        <div className="space-y-2">
                          <h4 className="text-xs font-semibold text-gray-700">
                            Seat Categories:
                          </h4>
                          <div className="flex flex-wrap gap-3 text-xs">
                            {(() => {
                              console.log("All ticket types:", ticketTypes);
                              console.log(
                                "Category map keys:",
                                Array.from(categoryMap.keys())
                              );
                              return null;
                            })()}
                            {Array.from(categoryMap.entries()).map(
                              ([key, data], index) => {
                                const colors = ticketTypeColors.get(key)!;
                                const [ticketTypeId] = key.split("-");

                                console.log(
                                  `Looking for ticket type: ${ticketTypeId}`
                                );
                                console.log(
                                  "Available ticket types:",
                                  ticketTypes
                                );

                                // Find the ticket type name - try different matching strategies
                                let ticketType = ticketTypes.find(
                                  (tt) => tt.ticket_type_id === ticketTypeId
                                );

                                // If not found, try matching by price
                                if (!ticketType) {
                                  ticketType = ticketTypes.find(
                                    (tt) => tt.price === data.price
                                  );
                                }

                                console.log(`Found ticket type:`, ticketType);
                                const categoryName =
                                  ticketType?.name || `Category ${index + 1}`;
                                console.log(
                                  `Using category name: ${categoryName}`
                                );

                                return (
                                  <div
                                    key={key}
                                    className="flex items-center gap-1"
                                  >
                                    <div
                                      className="w-5 h-5 rounded border-2"
                                      style={{
                                        backgroundColor: colors.bg,
                                        borderColor: colors.border,
                                      }}
                                    ></div>
                                    <span className="font-medium">
                                      {categoryName} - ${data.price} (
                                      {data.available}/{data.count})
                                    </span>
                                  </div>
                                );
                              }
                            )}
                          </div>
                        </div>

                        {/* Legend - Status */}
                        <div className="space-y-2">
                          <h4 className="text-xs font-semibold text-gray-700">
                            Seat Status:
                          </h4>
                          <div className="flex gap-4 text-xs">
                            <div className="flex items-center gap-1">
                              <div
                                className="w-5 h-5 rounded border-2"
                                style={{
                                  backgroundColor: "#ef4444",
                                  borderColor: "#b91c1c",
                                }}
                              ></div>
                              <span className="font-medium">Booked</span>
                            </div>
                          </div>
                        </div>

                        {/* Seat Grid */}
                        <div className="space-y-3">
                          {sortedRows.map((row) => {
                            const rowSeats = rowMap
                              .get(row)!
                              .sort((a, b) => a.label.localeCompare(b.label));

                            return (
                              <div
                                key={row}
                                className="flex items-center gap-3"
                              >
                                <div className="w-8 text-sm font-semibold text-gray-700 flex-shrink-0">
                                  {row}
                                </div>
                                <div className="flex gap-2 flex-wrap">
                                  {rowSeats.map((seat) => {
                                    console.log(`Seat ${seat.label}:`, {
                                      booked: seat.booked,
                                      available: seat.available,
                                      id: seat.id,
                                    });

                                    // Determine status and colors
                                    const isBooked =
                                      seat.booked === true ||
                                      (seat.available === false &&
                                        seat.booked !== false);
                                    const isAvailable =
                                      seat.available === true && !seat.booked;

                                    // Get category color
                                    const categoryKey = `${seat.ticketType}-${seat.price}`;
                                    const categoryColor =
                                      ticketTypeColors.get(categoryKey);

                                    let bgColor, textColor, borderColor;
                                    if (isBooked) {
                                      // Booked seats are always red
                                      bgColor = "#ef4444"; // red-500
                                      textColor = "#ffffff";
                                      borderColor = "#b91c1c"; // red-700
                                    } else if (isAvailable && categoryColor) {
                                      // Available seats use category color
                                      bgColor = categoryColor.bg;
                                      textColor = "#ffffff";
                                      borderColor = categoryColor.border;
                                    } else {
                                      // Unavailable/unknown
                                      bgColor = "#ffffff";
                                      textColor = "#374151";
                                      borderColor = "#d1d5db";
                                    }

                                    return (
                                      <div
                                        key={seat.id}
                                        className="w-10 h-10 rounded-lg text-xs font-bold flex items-center justify-center transition-all cursor-pointer border-2 shadow-md hover:shadow-lg"
                                        style={{
                                          backgroundColor: bgColor,
                                          color: textColor,
                                          borderColor: borderColor,
                                        }}
                                        title={`${seat.label} - $${
                                          seat.price
                                        } - ${
                                          isBooked
                                            ? "Booked"
                                            : isAvailable
                                            ? "Available"
                                            : "Unavailable"
                                        }`}
                                      >
                                        {seat.label.substring(1)}
                                      </div>
                                    );
                                  })}
                                </div>
                              </div>
                            );
                          })}
                        </div>

                        {/* Stage indicator */}
                        <div className="mt-4 pt-2 border-t-4 border-gray-400 text-center">
                          <div className="text-xs text-gray-500 font-medium">
                            STAGE
                          </div>
                        </div>
                      </div>
                    );
                  })()}
                </CardContent>
              </Card>
            )}
          </div>

          {/* Sidebar */}
          <div className="md:col-span-2 space-y-4">
            {/* Status */}
            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-lg">Status</CardTitle>
              </CardHeader>
              <CardContent>
                {(() => {
                  const statusInfo = getEventStatus(event);
                  return (
                    <Badge
                      variant={statusInfo.variant}
                      className="text-sm py-1 px-2 font-semibold"
                      style={{
                        backgroundColor: statusInfo.color,
                        color: "#ffffff",
                        borderColor: statusInfo.color,
                      }}
                    >
                      {statusInfo.status}
                    </Badge>
                  );
                })()}
              </CardContent>
            </Card>

            {/* Organization */}
            {event.organization && (
              <Card>
                <CardHeader className="pb-3">
                  <CardTitle className="flex items-center text-lg">
                    <Building className="h-4 w-4 mr-2" />
                    Organizer
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="flex items-center space-x-2">
                    {event.organization.logo_url && (
                      <div className="h-10 w-10 rounded-full overflow-hidden flex-shrink-0">
                        <img
                          src={event.organization.logo_url}
                          alt={event.organization.name}
                          className="w-full h-full object-cover"
                        />
                      </div>
                    )}
                    <div>
                      <p className="font-semibold text-sm">
                        {event.organization.name}
                      </p>
                    </div>
                  </div>
                </CardContent>
              </Card>
            )}

            {/* Statistics */}
            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-lg">Statistics</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                {(() => {
                  let totalSeats = 0;
                  let bookedSeats = 0;
                  let totalRevenue = 0;

                  // Calculate from seat map if available
                  if (event.seat_map) {
                    try {
                      const seats: Seat[] =
                        typeof event.seat_map === "string"
                          ? JSON.parse(event.seat_map)
                          : event.seat_map;

                      if (Array.isArray(seats)) {
                        totalSeats = seats.length;
                        bookedSeats = seats.filter(
                          (s) => s.booked || !s.available
                        ).length;

                        // Calculate revenue from booked seats
                        seats.forEach((seat) => {
                          if (
                            seat.booked ||
                            (seat.available === false && seat.booked !== false)
                          ) {
                            totalRevenue += seat.price || 0;
                          }
                        });
                      }
                    } catch (error) {
                      console.error(
                        "Failed to parse seat map for statistics:",
                        error
                      );
                    }
                  }

                  // Fallback to capacity if no seat map
                  if (totalSeats === 0 && event.capacity) {
                    totalSeats = event.capacity;
                  }

                  const remainingSeats = totalSeats - bookedSeats;

                  return (
                    <>
                      <div className="flex justify-between items-center">
                        <span className="text-gray-600 text-sm">
                          Total Seats
                        </span>
                        <span className="font-semibold text-sm">
                          {totalSeats}
                        </span>
                      </div>
                      <div className="flex justify-between items-center">
                        <span className="text-gray-600 text-sm">
                          Tickets Sold
                        </span>
                        <span className="font-semibold text-sm">
                          {bookedSeats}
                        </span>
                      </div>
                      <div className="flex justify-between items-center">
                        <span className="text-gray-600 text-sm">Remaining</span>
                        <span className="font-semibold text-sm">
                          {remainingSeats}
                        </span>
                      </div>
                      <div className="flex justify-between items-center pt-2 border-t border-gray-200">
                        <span className="text-gray-600 text-sm">Revenue</span>
                        <span className="font-semibold text-sm text-green-600">
                          ${totalRevenue.toFixed(2)}
                        </span>
                      </div>
                    </>
                  );
                })()}
              </CardContent>
            </Card>

            {/* Metadata */}
            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-lg">Metadata</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2 text-xs">
                <div>
                  <span className="text-gray-600">Created:</span>
                  <p className="font-medium">{formatDate(event.created_at)}</p>
                </div>
                <div>
                  <span className="text-gray-600">Last Updated:</span>
                  <p className="font-medium">{formatDate(event.updated_at)}</p>
                </div>
                <div>
                  <span className="text-gray-600">Event ID:</span>
                  <p className="font-medium">{event.event_id}</p>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </main>
    </div>
  );
}
