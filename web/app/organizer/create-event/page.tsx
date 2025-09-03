"use client";

import type React from "react";

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
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import {
  MapPin,
  Plus,
  X,
  Calendar,
  DollarSign,
  Upload,
  Video,
  Users,
  Clock,
  Save,
  AlertCircle,
} from "lucide-react";

interface TicketType {
  id: string;
  name: string;
  price: number;
  quantity: number;
  description?: string;
}

interface SeatMap {
  layout: string;
  sections: Array<{
    id: string;
    name: string;
    rows: number;
    seatsPerRow: number;
    price?: number;
  }>;
}

export default function CreateEventPage() {
  const [eventData, setEventData] = useState({
    title: "",
    description: "",
    category: "",
    venue: "",
    location: "",
    startDate: "",
    startTime: "",
    endDate: "",
    endTime: "",
    capacity: "",
    coverImage: null as File | null,
    coverImageUrl: "",
    otherImages: [] as File[],
    otherImagesUrl: [] as string[],
    videoUrl: "",
    status: "ACTIVE",
  });

  const [ticketTypes, setTicketTypes] = useState<TicketType[]>([]);

  const [newTicket, setNewTicket] = useState({
    name: "",
    price: "",
    quantity: "",
    description: "",
  });

  const [seatMap, setSeatMap] = useState<SeatMap | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [hasDraft, setHasDraft] = useState(false);

  // Load draft on component mount
  useEffect(() => {
    const savedDraft = localStorage.getItem("eventDraft");
    if (savedDraft) {
      try {
        const draft = JSON.parse(savedDraft);
        setHasDraft(true);
        // Could automatically load draft or show a prompt
      } catch (error) {
        console.error("Error loading draft:", error);
      }
    }
  }, []);

  const loadDraft = () => {
    const savedDraft = localStorage.getItem("eventDraft");
    if (savedDraft) {
      try {
        const draft = JSON.parse(savedDraft);
        setEventData(draft.eventData || eventData);
        setTicketTypes(draft.ticketTypes || []);
        setSeatMap(draft.seatMap || null);
        setHasDraft(false);
        alert("Draft loaded successfully!");
      } catch (error) {
        console.error("Error loading draft:", error);
        alert("Failed to load draft.");
      }
    }
  };

  const validateForm = () => {
    const errors: string[] = [];

    if (!eventData.title.trim()) errors.push("Event title is required");
    if (!eventData.description.trim())
      errors.push("Event description is required");
    if (!eventData.category) errors.push("Event category is required");
    if (!eventData.venue.trim()) errors.push("Venue name is required");
    if (!eventData.location.trim()) errors.push("Location address is required");
    if (!eventData.startDate) errors.push("Start date is required");
    if (!eventData.startTime) errors.push("Start time is required");
    if (!eventData.endDate) errors.push("End date is required");
    if (!eventData.endTime) errors.push("End time is required");
    if (!eventData.capacity || parseInt(eventData.capacity) <= 0) {
      errors.push("Valid capacity is required");
    }

    // Validate dates
    if (eventData.startDate && eventData.endDate) {
      const startDateTime = new Date(
        `${eventData.startDate}T${eventData.startTime}`
      );
      const endDateTime = new Date(`${eventData.endDate}T${eventData.endTime}`);

      if (endDateTime <= startDateTime) {
        errors.push("End date/time must be after start date/time");
      }

      if (startDateTime <= new Date()) {
        errors.push("Start date/time must be in the future");
      }
    }

    // Validate ticket types
    if (ticketTypes.length === 0) {
      errors.push("At least one ticket type is required");
    }

    const totalTickets = ticketTypes.reduce(
      (sum, ticket) => sum + ticket.quantity,
      0
    );
    if (totalTickets > parseInt(eventData.capacity || "0")) {
      errors.push("Total ticket quantity cannot exceed event capacity");
    }

    return errors;
  };

  const addTicketType = () => {
    if (newTicket.name && newTicket.price && newTicket.quantity) {
      const ticket: TicketType = {
        id: Date.now().toString(),
        name: newTicket.name,
        price: Number.parseFloat(newTicket.price),
        quantity: Number.parseInt(newTicket.quantity),
        description: newTicket.description,
      };
      setTicketTypes([...ticketTypes, ticket]);
      setNewTicket({ name: "", price: "", quantity: "", description: "" });
    }
  };

  const removeTicketType = (id: string) => {
    setTicketTypes(ticketTypes.filter((ticket) => ticket.id !== id));
  };

  const handleCoverImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setEventData({ ...eventData, coverImage: file });
      // Create preview URL
      const url = URL.createObjectURL(file);
      setEventData((prev) => ({ ...prev, coverImageUrl: url }));
    }
  };

  const handleOtherImagesUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);
    if (files.length > 0) {
      setEventData((prev) => ({
        ...prev,
        otherImages: [...prev.otherImages, ...files],
        otherImagesUrl: [
          ...prev.otherImagesUrl,
          ...files.map((file) => URL.createObjectURL(file)),
        ],
      }));
    }
  };

  const removeOtherImage = (index: number) => {
    setEventData((prev) => ({
      ...prev,
      otherImages: prev.otherImages.filter((_, i) => i !== index),
      otherImagesUrl: prev.otherImagesUrl.filter((_, i) => i !== index),
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Validate form
    const validationErrors = validateForm();
    if (validationErrors.length > 0) {
      alert(
        "Please fix the following errors:\n\n" + validationErrors.join("\n")
      );
      return;
    }

    setIsLoading(true);

    try {
      // Combine start date and time
      const startDateTime = new Date(
        `${eventData.startDate}T${eventData.startTime}`
      );
      const endDateTime = new Date(`${eventData.endDate}T${eventData.endTime}`);

      const formData = new FormData();

      // Basic event data
      formData.append("title", eventData.title);
      formData.append("description", eventData.description);
      formData.append("category", eventData.category);
      formData.append("venue", eventData.venue);
      formData.append("location", eventData.location);
      formData.append("start_time", startDateTime.toISOString());
      formData.append("end_time", endDateTime.toISOString());
      formData.append("capacity", eventData.capacity);
      formData.append("video_url", eventData.videoUrl);
      formData.append("status", eventData.status);

      // Add ticket types
      formData.append("ticket_types", JSON.stringify(ticketTypes));

      // Add seat map if exists
      if (seatMap) {
        formData.append("seat_map", JSON.stringify(seatMap));
      }

      // Add cover image
      if (eventData.coverImage) {
        formData.append("cover_image", eventData.coverImage);
      }

      // Add other images
      eventData.otherImages.forEach((image, index) => {
        formData.append(`other_image_${index}`, image);
      });

      // Send to API
      const response = await fetch("/api/events", {
        method: "POST",
        body: formData,
      });

      const result = await response.json();

      if (result.success) {
        // Clear draft
        localStorage.removeItem("eventDraft");
        alert("Event created successfully!");
        // Reset form or redirect
        window.location.href = "/organizer/events";
      } else {
        throw new Error(result.message || "Failed to create event");
      }
    } catch (error) {
      console.error("Error creating event:", error);
      alert("Failed to create event. Please try again.");
    } finally {
      setIsLoading(false);
    }
  };

  const saveDraft = () => {
    // Save to localStorage or send to API as draft
    localStorage.setItem(
      "eventDraft",
      JSON.stringify({
        eventData,
        ticketTypes,
        seatMap,
      })
    );
    alert("Draft saved successfully!");
  };

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />

      <div className="flex-1 lg:ml-64">
        <div className="p-6 lg:p-8">
          {/* Header */}
          <div className="mb-8">
            <h1 className="text-3xl font-bold text-gray-900">
              Create New Event
            </h1>
            <p className="text-gray-600 mt-2">
              Set up your event details, location, and ticket types
            </p>
          </div>

          {/* Draft Notice */}
          {hasDraft && (
            <div className="mb-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
              <div className="flex items-center justify-between">
                <div className="flex items-center">
                  <AlertCircle className="h-5 w-5 text-blue-600 mr-2" />
                  <div>
                    <h4 className="font-medium text-blue-800">
                      Draft Available
                    </h4>
                    <p className="text-sm text-blue-600">
                      You have a saved draft of an event. Would you like to
                      continue where you left off?
                    </p>
                  </div>
                </div>
                <div className="space-x-2">
                  <Button
                    type="button"
                    size="sm"
                    variant="outline"
                    onClick={() => setHasDraft(false)}
                  >
                    Ignore
                  </Button>
                  <Button type="button" size="sm" onClick={loadDraft}>
                    Load Draft
                  </Button>
                </div>
              </div>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-8">
            {/* Basic Information */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Calendar className="h-5 w-5 mr-2" />
                  Event Information
                </CardTitle>
                <CardDescription>
                  Basic details about your event
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="title">Event Title *</Label>
                    <Input
                      id="title"
                      placeholder="Enter event title"
                      value={eventData.title}
                      onChange={(e) =>
                        setEventData({ ...eventData, title: e.target.value })
                      }
                      required
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="category">Category *</Label>
                    <Select
                      value={eventData.category}
                      onValueChange={(value) =>
                        setEventData({ ...eventData, category: value })
                      }
                    >
                      <SelectTrigger>
                        <SelectValue placeholder="Select category" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="conference">Conference</SelectItem>
                        <SelectItem value="workshop">Workshop</SelectItem>
                        <SelectItem value="concert">Concert</SelectItem>
                        <SelectItem value="festival">Festival</SelectItem>
                        <SelectItem value="sports">Sports</SelectItem>
                        <SelectItem value="exhibition">Exhibition</SelectItem>
                        <SelectItem value="networking">Networking</SelectItem>
                        <SelectItem value="seminar">Seminar</SelectItem>
                        <SelectItem value="party">Party</SelectItem>
                        <SelectItem value="other">Other</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="description">Description *</Label>
                  <Textarea
                    id="description"
                    placeholder="Describe your event..."
                    rows={4}
                    value={eventData.description}
                    onChange={(e) =>
                      setEventData({
                        ...eventData,
                        description: e.target.value,
                      })
                    }
                    required
                  />
                </div>

                {/* Date and Time Section */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-4">
                    <h4 className="font-medium flex items-center">
                      <Clock className="h-4 w-4 mr-2" />
                      Start Date & Time
                    </h4>
                    <div className="grid grid-cols-2 gap-2">
                      <div className="space-y-2">
                        <Label htmlFor="startDate">Date *</Label>
                        <Input
                          id="startDate"
                          type="date"
                          value={eventData.startDate}
                          onChange={(e) =>
                            setEventData({
                              ...eventData,
                              startDate: e.target.value,
                            })
                          }
                          required
                        />
                      </div>
                      <div className="space-y-2">
                        <Label htmlFor="startTime">Time *</Label>
                        <Input
                          id="startTime"
                          type="time"
                          value={eventData.startTime}
                          onChange={(e) =>
                            setEventData({
                              ...eventData,
                              startTime: e.target.value,
                            })
                          }
                          required
                        />
                      </div>
                    </div>
                  </div>
                  <div className="space-y-4">
                    <h4 className="font-medium">End Date & Time</h4>
                    <div className="grid grid-cols-2 gap-2">
                      <div className="space-y-2">
                        <Label htmlFor="endDate">Date *</Label>
                        <Input
                          id="endDate"
                          type="date"
                          value={eventData.endDate}
                          onChange={(e) =>
                            setEventData({
                              ...eventData,
                              endDate: e.target.value,
                            })
                          }
                          required
                        />
                      </div>
                      <div className="space-y-2">
                        <Label htmlFor="endTime">Time *</Label>
                        <Input
                          id="endTime"
                          type="time"
                          value={eventData.endTime}
                          onChange={(e) =>
                            setEventData({
                              ...eventData,
                              endTime: e.target.value,
                            })
                          }
                          required
                        />
                      </div>
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="capacity">Capacity *</Label>
                    <Input
                      id="capacity"
                      type="number"
                      placeholder="Max attendees"
                      value={eventData.capacity}
                      onChange={(e) =>
                        setEventData({ ...eventData, capacity: e.target.value })
                      }
                      required
                      min="1"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="status">Status</Label>
                    <Select
                      value={eventData.status}
                      onValueChange={(value) =>
                        setEventData({ ...eventData, status: value })
                      }
                    >
                      <SelectTrigger>
                        <SelectValue placeholder="Select status" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="ACTIVE">Active</SelectItem>
                        <SelectItem value="DRAFT">Draft</SelectItem>
                        <SelectItem value="CANCELLED">Cancelled</SelectItem>
                        <SelectItem value="COMPLETED">Completed</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Location & Venue */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <MapPin className="h-5 w-5 mr-2" />
                  Location & Venue
                </CardTitle>
                <CardDescription>
                  Set the event location and venue details
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="venue">Venue Name *</Label>
                    <Input
                      id="venue"
                      placeholder="Enter venue name"
                      value={eventData.venue}
                      onChange={(e) =>
                        setEventData({ ...eventData, venue: e.target.value })
                      }
                      required
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="location">Location Address *</Label>
                    <Input
                      id="location"
                      placeholder="Enter full address"
                      value={eventData.location}
                      onChange={(e) =>
                        setEventData({ ...eventData, location: e.target.value })
                      }
                      required
                    />
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Media Upload */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Upload className="h-5 w-5 mr-2" />
                  Event Media
                </CardTitle>
                <CardDescription>
                  Upload images and videos for your event
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                {/* Cover Image */}
                <div className="space-y-4">
                  <Label>Cover Image</Label>
                  <div className="border-2 border-dashed border-gray-300 rounded-lg p-6">
                    {eventData.coverImageUrl ? (
                      <div className="text-center">
                        <img
                          src={eventData.coverImageUrl}
                          alt="Cover preview"
                          className="max-h-48 mx-auto rounded-lg mb-4"
                        />
                        <Button
                          type="button"
                          variant="outline"
                          onClick={() =>
                            setEventData((prev) => ({
                              ...prev,
                              coverImage: null,
                              coverImageUrl: "",
                            }))
                          }
                        >
                          Remove Image
                        </Button>
                      </div>
                    ) : (
                      <div className="text-center">
                        <Upload className="h-12 w-12 mx-auto text-gray-400 mb-4" />
                        <Label htmlFor="coverImage" className="cursor-pointer">
                          <span className="text-blue-600 hover:text-blue-500">
                            Upload a cover image
                          </span>
                          <Input
                            id="coverImage"
                            type="file"
                            accept="image/*"
                            onChange={handleCoverImageUpload}
                            className="hidden"
                          />
                        </Label>
                        <p className="text-gray-500 text-sm mt-2">
                          PNG, JPG, GIF up to 10MB
                        </p>
                      </div>
                    )}
                  </div>
                </div>

                {/* Other Images */}
                <div className="space-y-4">
                  <Label>Additional Images</Label>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    {eventData.otherImagesUrl.map((url, index) => (
                      <div key={index} className="relative group">
                        <img
                          src={url}
                          alt={`Additional image ${index + 1}`}
                          className="w-full h-24 object-cover rounded-lg"
                        />
                        <Button
                          type="button"
                          size="sm"
                          variant="destructive"
                          className="absolute top-1 right-1 h-6 w-6 p-0"
                          onClick={() => removeOtherImage(index)}
                        >
                          <X className="h-3 w-3" />
                        </Button>
                      </div>
                    ))}
                    <Label htmlFor="otherImages" className="cursor-pointer">
                      <div className="w-full h-24 border-2 border-dashed border-gray-300 rounded-lg flex items-center justify-center hover:border-blue-400">
                        <Plus className="h-6 w-6 text-gray-400" />
                      </div>
                      <Input
                        id="otherImages"
                        type="file"
                        accept="image/*"
                        multiple
                        onChange={handleOtherImagesUpload}
                        className="hidden"
                      />
                    </Label>
                  </div>
                </div>

                {/* Video URL */}
                <div className="space-y-2">
                  <Label htmlFor="videoUrl" className="flex items-center">
                    <Video className="h-4 w-4 mr-2" />
                    Video URL (Optional)
                  </Label>
                  <Input
                    id="videoUrl"
                    type="url"
                    placeholder="https://youtube.com/watch?v=..."
                    value={eventData.videoUrl}
                    onChange={(e) =>
                      setEventData({ ...eventData, videoUrl: e.target.value })
                    }
                  />
                  <p className="text-sm text-gray-500">
                    Add a YouTube, Vimeo, or other video URL to showcase your
                    event
                  </p>
                </div>
              </CardContent>
            </Card>

            {/* Ticket Types */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <DollarSign className="h-5 w-5 mr-2" />
                  Ticket Types & Pricing
                </CardTitle>
                <CardDescription>
                  Configure different ticket types and pricing options
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                {/* Existing Ticket Types */}
                {ticketTypes.length > 0 && (
                  <div className="space-y-4">
                    <h4 className="font-medium">Current Ticket Types</h4>
                    {ticketTypes.map((ticket) => (
                      <div
                        key={ticket.id}
                        className="flex items-center justify-between p-4 border rounded-lg"
                      >
                        <div className="flex-1">
                          <div className="flex items-center space-x-3">
                            <h3 className="font-semibold">{ticket.name}</h3>
                            <Badge variant="secondary">${ticket.price}</Badge>
                            <Badge variant="outline">
                              {ticket.quantity} available
                            </Badge>
                          </div>
                          {ticket.description && (
                            <p className="text-sm text-gray-600 mt-1">
                              {ticket.description}
                            </p>
                          )}
                        </div>
                        <Button
                          type="button"
                          variant="ghost"
                          size="sm"
                          onClick={() => removeTicketType(ticket.id)}
                        >
                          <X className="h-4 w-4" />
                        </Button>
                      </div>
                    ))}
                  </div>
                )}

                {/* Add New Ticket Type */}
                <div className={ticketTypes.length > 0 ? "border-t pt-6" : ""}>
                  <h4 className="font-medium mb-4">Add New Ticket Type</h4>
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                    <div className="space-y-2">
                      <Label htmlFor="ticket-name">Ticket Name *</Label>
                      <Input
                        id="ticket-name"
                        placeholder="e.g., VIP, Early Bird"
                        value={newTicket.name}
                        onChange={(e) =>
                          setNewTicket({ ...newTicket, name: e.target.value })
                        }
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="ticket-price">Price ($) *</Label>
                      <Input
                        id="ticket-price"
                        type="number"
                        step="0.01"
                        placeholder="0.00"
                        value={newTicket.price}
                        onChange={(e) =>
                          setNewTicket({ ...newTicket, price: e.target.value })
                        }
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="ticket-quantity">Quantity *</Label>
                      <Input
                        id="ticket-quantity"
                        type="number"
                        placeholder="100"
                        value={newTicket.quantity}
                        onChange={(e) =>
                          setNewTicket({
                            ...newTicket,
                            quantity: e.target.value,
                          })
                        }
                      />
                    </div>
                    <div className="space-y-2">
                      <Label>&nbsp;</Label>
                      <Button
                        type="button"
                        onClick={addTicketType}
                        className="w-full"
                        disabled={
                          !newTicket.name ||
                          !newTicket.price ||
                          !newTicket.quantity
                        }
                      >
                        <Plus className="h-4 w-4 mr-2" />
                        Add Ticket
                      </Button>
                    </div>
                  </div>
                  <div className="mt-4">
                    <Label htmlFor="ticket-description">
                      Description (Optional)
                    </Label>
                    <Input
                      id="ticket-description"
                      placeholder="Brief description of this ticket type"
                      value={newTicket.description}
                      onChange={(e) =>
                        setNewTicket({
                          ...newTicket,
                          description: e.target.value,
                        })
                      }
                    />
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Seat Map (Optional) */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Users className="h-5 w-5 mr-2" />
                  Seating Arrangement (Optional)
                </CardTitle>
                <CardDescription>
                  Configure seating layout for your event
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {!seatMap ? (
                  <div className="text-center py-8">
                    <Users className="h-12 w-12 mx-auto text-gray-400 mb-4" />
                    <p className="text-gray-600 mb-4">
                      Add a custom seating layout for better organization
                    </p>
                    <div className="space-x-2">
                      <Button
                        type="button"
                        variant="outline"
                        onClick={() =>
                          setSeatMap({
                            layout: "theater",
                            sections: [
                              {
                                id: "1",
                                name: "Front",
                                rows: 5,
                                seatsPerRow: 10,
                                price: 100,
                              },
                              {
                                id: "2",
                                name: "Middle",
                                rows: 8,
                                seatsPerRow: 12,
                                price: 75,
                              },
                              {
                                id: "3",
                                name: "Back",
                                rows: 6,
                                seatsPerRow: 14,
                                price: 50,
                              },
                            ],
                          })
                        }
                      >
                        Theater Style
                      </Button>
                      <Button
                        type="button"
                        variant="outline"
                        onClick={() =>
                          setSeatMap({
                            layout: "conference",
                            sections: [
                              {
                                id: "1",
                                name: "Round Tables",
                                rows: 10,
                                seatsPerRow: 8,
                                price: 80,
                              },
                            ],
                          })
                        }
                      >
                        Conference Style
                      </Button>
                      <Button
                        type="button"
                        variant="outline"
                        onClick={() =>
                          setSeatMap({
                            layout: "concert",
                            sections: [
                              {
                                id: "1",
                                name: "VIP",
                                rows: 3,
                                seatsPerRow: 20,
                                price: 150,
                              },
                              {
                                id: "2",
                                name: "General",
                                rows: 15,
                                seatsPerRow: 25,
                                price: 80,
                              },
                            ],
                          })
                        }
                      >
                        Concert Style
                      </Button>
                    </div>
                  </div>
                ) : (
                  <div className="space-y-4">
                    <div className="flex justify-between items-center">
                      <h4 className="font-medium capitalize">
                        {seatMap.layout} Layout
                      </h4>
                      <Button
                        type="button"
                        variant="ghost"
                        size="sm"
                        onClick={() => setSeatMap(null)}
                      >
                        <X className="h-4 w-4" />
                        Remove Layout
                      </Button>
                    </div>
                    <div className="grid gap-4">
                      {seatMap.sections.map((section, index) => (
                        <div key={section.id} className="border rounded-lg p-4">
                          <div className="flex items-center justify-between mb-2">
                            <h5 className="font-medium">{section.name}</h5>
                            <Badge variant="outline">
                              ${section.price || "Free"}
                            </Badge>
                          </div>
                          <div className="text-sm text-gray-600">
                            {section.rows} rows × {section.seatsPerRow} seats ={" "}
                            {section.rows * section.seatsPerRow} total seats
                          </div>
                        </div>
                      ))}
                    </div>
                    <p className="text-sm text-gray-500">
                      Total capacity:{" "}
                      {seatMap.sections.reduce(
                        (sum, section) =>
                          sum + section.rows * section.seatsPerRow,
                        0
                      )}{" "}
                      seats
                    </p>
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Submit Buttons */}
            <div className="flex justify-end space-x-4 pb-8">
              <Button
                type="button"
                variant="outline"
                onClick={saveDraft}
                disabled={isLoading}
                className="flex items-center"
              >
                <Save className="h-4 w-4 mr-2" />
                Save as Draft
              </Button>
              <Button
                type="submit"
                disabled={
                  isLoading ||
                  !eventData.title ||
                  !eventData.description ||
                  !eventData.venue ||
                  !eventData.startDate
                }
                className="flex items-center"
              >
                {isLoading ? (
                  <>
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                    Creating...
                  </>
                ) : (
                  <>
                    <Calendar className="h-4 w-4 mr-2" />
                    Create Event
                  </>
                )}
              </Button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
