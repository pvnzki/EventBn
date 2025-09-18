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
import dynamic from "next/dynamic";

const SeatingArrangementSection = dynamic(
  () => import("./SeatingArrangementSection"),
  { ssr: false }
);

interface TicketType {
  id: string;
  name: string;
  price: number;
  quantity: number;
  description?: string;
}

interface Seat {
  id: number;
  label: string;
  price: number;
  available: boolean;
  ticketType: string;
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
    videoFile: null as File | null,
    status: "ACTIVE",
    organization_id: "", // Added for organization
  });

  const [ticketTypes, setTicketTypes] = useState<TicketType[]>([]);

  const [newTicket, setNewTicket] = useState({
    name: "",
    price: "",
    quantity: "",
    description: "",
  });

  const [seatMap, setSeatMap] = useState<Seat[] | null>(null);

  // Video file upload handler (function declaration, hoisted)
  function handleVideoUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files && e.target.files[0];
    if (file) {
      setEventData((prev) => ({ ...prev, videoFile: file }));
    }
  }

  const [isLoading, setIsLoading] = useState(false);
  const [hasDraft, setHasDraft] = useState(false);

  // Load draft and set organization_id on component mount
  useEffect(() => {
    // Set organization_id from user in localStorage
    const userStr = localStorage.getItem("user");
    if (userStr) {
      try {
        const user = JSON.parse(userStr);
        if (user && user.organization_id) {
          setEventData((prev) => ({
            ...prev,
            organization_id: user.organization_id,
          }));
        }
      } catch (err) {
        console.error("Error parsing user from localStorage:", err);
      }
    }
    // Load draft
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
      // Add organization_id
      if (eventData.organization_id) {
        formData.append(
          "organization_id",
          eventData.organization_id.toString()
        );
      }

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

      // Add other images as array
      eventData.otherImages.forEach((image) => {
        formData.append("other_images", image);
      });

      // Add video file if present
      if (eventData.videoFile) {
        formData.append("video", eventData.videoFile);
      }

      // No conversion needed, seatMap is already an array of seat objects

      // Send to API
      const response = await fetch(
        `${
          process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000"
        }/api/events`,
        {
          method: "POST",
          body: formData,
        }
      );

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
            {eventData.organization_id && (
              <div className="mt-2 text-sm text-gray-500">
                <span className="font-semibold">Organization ID:</span>{" "}
                {eventData.organization_id}
              </div>
            )}
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

                {/* Video Upload */}
                <div className="space-y-2">
                  <Label htmlFor="videoFile" className="flex items-center">
                    <Video className="h-4 w-4 mr-2" />
                    Event Video (Optional)
                  </Label>
                  <Input
                    id="videoFile"
                    type="file"
                    accept="video/*"
                    onChange={handleVideoUpload}
                  />
                  <p className="text-sm text-gray-500">
                    Upload a short promo or highlight video for your event (mp4,
                    mov, etc.)
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

            {/* Seat Map (New Implementation) */}
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
                <SeatingArrangementSection
                  ticketTypes={ticketTypes}
                  onGenerate={(seatArr) => setSeatMap(seatArr)}
                />
                {seatMap &&
                  Array.isArray(seatMap) &&
                  seatMap.length > 0 &&
                  (() => {
                    // Color palette and ticketTypeColors mapping
                    const ticketTypeColors: Record<string, string> = {};
                    const palette = [
                      "bg-blue-200",
                      "bg-green-200",
                      "bg-yellow-200",
                      "bg-pink-200",
                      "bg-purple-200",
                      "bg-orange-200",
                      "bg-teal-200",
                      "bg-red-200",
                    ];
                    let colorIdx = 0;
                    seatMap.forEach((seat) => {
                      if (!ticketTypeColors[seat.ticketType]) {
                        ticketTypeColors[seat.ticketType] =
                          palette[colorIdx % palette.length];
                        colorIdx++;
                      }
                    });
                    // Group seats by row label
                    const rows: Record<string, Seat[]> = {};
                    seatMap.forEach((seat) => {
                      const row = seat.label.match(/^[A-Z]+/i)?.[0] || "";
                      if (!rows[row]) rows[row] = [];
                      rows[row].push(seat);
                    });
                    return (
                      <div className="mt-4">
                        <h4 className="font-medium mb-2">Seating Preview</h4>
                        <div className="inline-block rounded-lg border bg-white shadow p-4">
                          <div className="flex flex-col gap-2">
                            {Object.entries(rows).map(
                              ([rowLabel, seats], i) => (
                                <div
                                  key={rowLabel}
                                  className="flex items-center gap-2"
                                >
                                  <span className="font-semibold text-gray-700 w-6 text-right mr-2 select-none">
                                    {rowLabel}
                                  </span>
                                  <div className="flex gap-2">
                                    {seats.map((seat) => (
                                      <div
                                        key={seat.id}
                                        className={`relative border rounded-full w-8 h-8 flex items-center justify-center text-xs font-semibold shadow-sm transition-all duration-150
                                      ${
                                        seat.available
                                          ? ticketTypeColors[seat.ticketType]
                                          : "bg-gray-300 text-gray-400"
                                      }
                                      ${
                                        seat.available
                                          ? "hover:scale-110 cursor-pointer"
                                          : "opacity-60"
                                      }
                                    `}
                                        title={`Seat: ${seat.label}\nType: ${seat.ticketType}\nPrice: $${seat.price}`}
                                      >
                                        {seat.label.replace(/^[A-Z]+/i, "")}
                                      </div>
                                    ))}
                                  </div>
                                </div>
                              )
                            )}
                          </div>
                          {/* Legend */}
                          <div className="flex flex-wrap gap-4 mt-4 items-center">
                            {(() => {
                              const ticketTypesShown: Record<string, boolean> =
                                {};
                              return seatMap
                                .filter((seat) => {
                                  if (ticketTypesShown[seat.ticketType])
                                    return false;
                                  ticketTypesShown[seat.ticketType] = true;
                                  return true;
                                })
                                .map((seat) => (
                                  <div
                                    key={seat.ticketType}
                                    className="flex items-center gap-2"
                                  >
                                    <span
                                      className={`inline-block w-4 h-4 rounded-full border ${
                                        ticketTypeColors[seat.ticketType]
                                      }`}
                                    ></span>
                                    <span className="text-xs text-gray-700">
                                      {seat.ticketType}
                                    </span>
                                  </div>
                                ));
                            })()}
                            <span className="inline-block w-4 h-4 rounded-full border bg-gray-300 ml-4"></span>
                            <span className="text-xs text-gray-500">
                              Unavailable
                            </span>
                          </div>
                        </div>
                        <p className="text-sm text-gray-500 mt-2">
                          Total seats: {seatMap.length}
                        </p>
                      </div>
                    );
                  })()}
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
