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
import { Search, Plus, Eye, Edit, Trash2, Calendar, X } from "lucide-react";
import Link from "next/link";

interface Event {
  event_id: number;
  organization_id: number | null;
  title: string | null;
  description: string | null;
  category: string | null;
  venue: string | null;
  location: string | null;
  start_time: string | null;
  end_time: string | null;
  capacity: number | null;
  cover_image_url: string | null;
  other_images_url: string | null;
  video_url: string | null;
  created_at: string | null;
  updated_at: string | null;
  status: string | null;
  organization?: {
    name: string;
    organization_id: number;
    logo_url: string;
  } | null;
  ticketsSold?: number;
  revenue?: number;
}

export default function AdminEventsPage() {
  const [events, setEvents] = useState<Event[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [categoryFilter, setCategoryFilter] = useState("all");
  const [selectedEvent, setSelectedEvent] = useState<Event | null>(null);
  const [eventToDelete, setEventToDelete] = useState<Event | null>(null);

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

  const filteredEvents = events.filter((event) => {
    const matchesSearch =
      (event.title?.toLowerCase().includes(searchTerm.toLowerCase()) ??
        false) ||
      (event.description?.toLowerCase().includes(searchTerm.toLowerCase()) ??
        false) ||
      (event.venue?.toLowerCase().includes(searchTerm.toLowerCase()) ?? false);

    const matchesStatus =
      statusFilter === "all" || event.status?.toLowerCase() === statusFilter;
    const matchesCategory =
      categoryFilter === "all" ||
      event.category?.toLowerCase() === categoryFilter;

    return matchesSearch && matchesStatus && matchesCategory;
  });

  const getStatusColor = (status: string | null) => {
    switch (status?.toLowerCase()) {
      case "active":
        return "default";
      case "sold_out":
        return "destructive";
      case "draft":
        return "secondary";
      case "cancelled":
        return "outline";
      default:
        return "secondary";
    }
  };

  const formatDate = (dateString: string | null) => {
    if (!dateString) return "N/A";
    const date = new Date(dateString);
    return date.toISOString().split("T")[0];
  };

  const formatDateTime = (dateString: string | null) => {
    if (!dateString) return "N/A";
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
          <div className="flex justify-between items-center mb-8">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">All Events</h1>
              <p className="text-gray-600 mt-2">
                Manage all events across the platform
              </p>
            </div>
            {/* Create Event button removed */}
          </div>

          {/* Filters */}
          <Card className="mb-6">
            <CardContent className="pt-6">
              <div className="flex flex-col md:flex-row gap-4">
                <div className="flex-1">
                  <div className="relative">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                    <Input
                      placeholder="Search events..."
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="pl-10"
                    />
                  </div>
                </div>
                <Select value={statusFilter} onValueChange={setStatusFilter}>
                  <SelectTrigger className="w-40">
                    <SelectValue placeholder="Status" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Status</SelectItem>
                    <SelectItem value="active">Active</SelectItem>
                    <SelectItem value="sold_out">Sold Out</SelectItem>
                    <SelectItem value="draft">Draft</SelectItem>
                    <SelectItem value="cancelled">Cancelled</SelectItem>
                  </SelectContent>
                </Select>
                <Select
                  value={categoryFilter}
                  onValueChange={setCategoryFilter}
                >
                  <SelectTrigger className="w-40">
                    <SelectValue placeholder="Category" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Categories</SelectItem>
                    <SelectItem value="conference">Conference</SelectItem>
                    <SelectItem value="workshop">Workshop</SelectItem>
                    <SelectItem value="festival">Festival</SelectItem>
                    <SelectItem value="exhibition">Exhibition</SelectItem>
                    <SelectItem value="sports">Sports</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader>
              <CardTitle>Recent Events</CardTitle>
              <CardDescription>
                Latest events across the platform
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {filteredEvents.map((event) => (
                  <div
                    key={event.event_id}
                    className="flex items-center justify-between p-4 border rounded-lg"
                  >
                    <div className="flex items-center space-x-4">
                      <img
                        src={event.cover_image_url || "/placeholder.jpg"}
                        alt={event.title || "Event"}
                        className="w-16 h-16 object-cover rounded-md"
                      />
                      <div className="flex-1">
                        <h3 className="font-semibold text-gray-900">
                          {event.title || "Untitled Event"}
                        </h3>
                        <p className="text-sm text-gray-600">
                          Category: {event.category || "N/A"}
                        </p>
                        <p className="text-sm text-gray-600">
                          Venue: {event.venue || "N/A"}
                        </p>
                        <p className="text-sm text-gray-600">
                          Date: {formatDate(event.start_time)}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center space-x-3">
                      <Badge variant={getStatusColor(event.status)}>
                        {event.status?.toLowerCase() || "N/A"}
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
          {filteredEvents.length === 0 && (
            <Card className="text-center py-12">
              <CardContent>
                <Calendar className="h-12 w-12 mx-auto text-gray-400 mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">
                  No events found
                </h3>
                <p className="text-gray-600 mb-4">
                  {searchTerm ||
                  statusFilter !== "all" ||
                  categoryFilter !== "all"
                    ? "Try adjusting your filters to see more events."
                    : "Get started by creating your first event."}
                </p>
                <Link href="/create-event">
                  <Button>
                    <Plus className="h-4 w-4 mr-2" />
                    Create Event
                  </Button>
                </Link>
              </CardContent>
            </Card>
          )}
        </div>
      </div>

      {selectedEvent && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-4 w-full max-w-md max-h-[80vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-3">
              <h2 className="text-lg font-bold">
                {selectedEvent.title || "Untitled Event"}
              </h2>
              <Button variant="ghost" onClick={closeModal}>
                <X className="h-4 w-4" />
              </Button>
            </div>
            <div className="space-y-2">
              <img
                src={selectedEvent.cover_image_url || "/placeholder.jpg"}
                alt={selectedEvent.title || "Event"}
                className="w-32 h-16 object-cover rounded-md"
              />
              <p className="text-sm">
                <strong>Event ID:</strong> {selectedEvent.event_id}
              </p>
              <p className="text-sm">
                <strong>Title:</strong> {selectedEvent.title || "N/A"}
              </p>
              <p className="text-sm">
                <strong>Description:</strong>{" "}
                {selectedEvent.description || "N/A"}
              </p>
              <p className="text-sm">
                <strong>Category:</strong> {selectedEvent.category || "N/A"}
              </p>
              <p className="text-sm">
                <strong>Venue:</strong> {selectedEvent.venue || "N/A"}
              </p>
              <p className="text-sm">
                <strong>Location:</strong> {selectedEvent.location || "N/A"}
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
                <strong>Capacity:</strong> {selectedEvent.capacity ?? "N/A"}
              </p>
              <p className="text-sm">
                <strong>Status:</strong>{" "}
                {selectedEvent.status?.toLowerCase() || "N/A"}
              </p>
              <p className="text-sm">
                <strong>Cover Image URL:</strong>{" "}
                {selectedEvent.cover_image_url ? (
                  <a
                    href={selectedEvent.cover_image_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-blue-600 hover:underline"
                  >
                    View Image
                  </a>
                ) : (
                  "N/A"
                )}
              </p>
              <p className="text-sm">
                <strong>Other Images URL:</strong>{" "}
                {selectedEvent.other_images_url
                  ? selectedEvent.other_images_url
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
                      ))
                  : "N/A"}
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
                  {selectedEvent.organization.name || "N/A"}
                </p>
              )}
              <p className="text-sm">
                <strong>Organization ID:</strong>{" "}
                {selectedEvent.organization_id ?? "N/A"}
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
            <div className="flex justifying-between items-center mb-4">
              <h2 className="text-lg font-bold">Confirm Delete</h2>
              <Button variant="ghost" onClick={handleCloseDeleteModal}>
                <X className="h-4 w-4" />
              </Button>
            </div>
            <p className="text-sm text-gray-600 mb-4">
              Are you sure you want to delete the event "
              {eventToDelete.title || "Untitled Event"}"?
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
}
