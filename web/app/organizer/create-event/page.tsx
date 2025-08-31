"use client";

import type React from "react";

import { useState } from "react";
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
import { MapPin, Plus, X, Calendar, DollarSign } from "lucide-react";

interface TicketType {
  id: string;
  name: string;
  price: number;
  quantity: number;
  description: string;
}

export default function CreateEventPage() {
  const [eventData, setEventData] = useState({
    title: "",
    description: "",
    category: "",
    date: "",
    time: "",
    venue: "",
    capacity: "",
    location: { lat: 40.7128, lng: -74.006 }, // Default to NYC
  });

  const [ticketTypes, setTicketTypes] = useState<TicketType[]>([
    {
      id: "1",
      name: "General Admission",
      price: 50,
      quantity: 100,
      description: "Standard entry ticket",
    },
  ]);

  const [newTicket, setNewTicket] = useState({
    name: "",
    price: "",
    quantity: "",
    description: "",
  });

  const [showMap, setShowMap] = useState(false);

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

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    console.log("Event Data:", eventData);
    console.log("Ticket Types:", ticketTypes);
    // Handle form submission
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
                    <Label htmlFor="title">Event Title</Label>
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
                    <Label htmlFor="category">Category</Label>
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
                      </SelectContent>
                    </Select>
                  </div>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="description">Description</Label>
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

                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="date">Date</Label>
                    <Input
                      id="date"
                      type="date"
                      value={eventData.date}
                      onChange={(e) =>
                        setEventData({ ...eventData, date: e.target.value })
                      }
                      required
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="time">Time</Label>
                    <Input
                      id="time"
                      type="time"
                      value={eventData.time}
                      onChange={(e) =>
                        setEventData({ ...eventData, time: e.target.value })
                      }
                      required
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="capacity">Capacity</Label>
                    <Input
                      id="capacity"
                      type="number"
                      placeholder="Max attendees"
                      value={eventData.capacity}
                      onChange={(e) =>
                        setEventData({ ...eventData, capacity: e.target.value })
                      }
                      required
                    />
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Location */}
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
                <div className="space-y-2">
                  <Label htmlFor="venue">Venue Name</Label>
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
                  <Label>Location on Map</Label>
                  <div className="border rounded-lg p-4">
                    {!showMap ? (
                      <div className="text-center py-8">
                        <MapPin className="h-12 w-12 mx-auto text-gray-400 mb-4" />
                        <p className="text-gray-600 mb-4">
                          Click to select location on map
                        </p>
                        <Button type="button" onClick={() => setShowMap(true)}>
                          Open Map
                        </Button>
                      </div>
                    ) : (
                      <div className="space-y-4">
                        {/* Mock Map Interface */}
                        <div className="bg-green-100 border-2 border-dashed border-green-300 rounded-lg p-8 text-center">
                          <MapPin className="h-16 w-16 mx-auto text-green-600 mb-4" />
                          <p className="text-green-800 font-medium">
                            Interactive Map Component
                          </p>
                          <p className="text-green-600 text-sm mt-2">
                            Selected: {eventData.location.lat.toFixed(4)},{" "}
                            {eventData.location.lng.toFixed(4)}
                          </p>
                          <div className="mt-4 space-x-2">
                            <Button type="button" size="sm" variant="outline">
                              Search Address
                            </Button>
                            <Button type="button" size="sm" variant="outline">
                              Use Current Location
                            </Button>
                            <Button
                              type="button"
                              size="sm"
                              variant="ghost"
                              onClick={() => setShowMap(false)}
                            >
                              Close Map
                            </Button>
                          </div>
                        </div>
                        <p className="text-sm text-gray-600">
                          Click on the map to set the exact location of your
                          event. This will help attendees find your venue
                          easily.
                        </p>
                      </div>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Ticket Types */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center">
                  <DollarSign className="h-5 w-5 mr-2" />
                  Ticket Types
                </CardTitle>
                <CardDescription>
                  Configure different ticket types and pricing
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                {/* Existing Ticket Types */}
                <div className="space-y-4">
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

                {/* Add New Ticket Type */}
                <div className="border-t pt-6">
                  <h4 className="font-medium mb-4">Add New Ticket Type</h4>
                  <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                    <div className="space-y-2">
                      <Label htmlFor="ticket-name">Ticket Name</Label>
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
                      <Label htmlFor="ticket-price">Price ($)</Label>
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
                      <Label htmlFor="ticket-quantity">Quantity</Label>
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

            {/* Submit Buttons */}
            <div className="flex justify-end space-x-4">
              <Button type="button" variant="outline">
                Save as Draft
              </Button>
              <Button type="submit">Create Event</Button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
