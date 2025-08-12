"use client"

import { useState, useEffect } from "react"
import { Sidebar } from "@/components/layout/sidebar"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Search, Plus, Eye, Edit, Trash2, Calendar, MapPin, Users, DollarSign } from "lucide-react"
import Link from "next/link"

interface User {
  role: "admin" | "organizer"
  name: string
}

const mockEvents = [
  {
    id: 1,
    title: "Tech Conference 2024",
    description: "Annual technology conference featuring the latest innovations",
    category: "Conference",
    date: "2024-03-15",
    time: "09:00",
    venue: "Convention Center",
    location: "New York, NY",
    capacity: 500,
    ticketsSold: 350,
    revenue: 17500,
    status: "active",
    organizer: "John Doe",
  },
  {
    id: 2,
    title: "Music Festival Summer",
    description: "Three-day music festival with top artists",
    category: "Festival",
    date: "2024-06-20",
    time: "14:00",
    venue: "Central Park",
    location: "New York, NY",
    capacity: 1000,
    ticketsSold: 1000,
    revenue: 50000,
    status: "sold-out",
    organizer: "Jane Smith",
  },
  {
    id: 3,
    title: "Business Workshop",
    description: "Professional development workshop for entrepreneurs",
    category: "Workshop",
    date: "2024-04-10",
    time: "10:00",
    venue: "Business Center",
    location: "San Francisco, CA",
    capacity: 100,
    ticketsSold: 75,
    revenue: 3750,
    status: "active",
    organizer: "Mike Johnson",
  },
  {
    id: 4,
    title: "Art Exhibition Opening",
    description: "Contemporary art exhibition featuring local artists",
    category: "Exhibition",
    date: "2024-05-05",
    time: "18:00",
    venue: "Art Gallery",
    location: "Los Angeles, CA",
    capacity: 200,
    ticketsSold: 0,
    revenue: 0,
    status: "draft",
    organizer: "Sarah Wilson",
  },
  {
    id: 5,
    title: "Sports Tournament",
    description: "Annual basketball tournament championship",
    category: "Sports",
    date: "2024-07-15",
    time: "15:00",
    venue: "Sports Arena",
    location: "Chicago, IL",
    capacity: 800,
    ticketsSold: 600,
    revenue: 30000,
    status: "active",
    organizer: "David Brown",
  },
]

export default function EventsPage() {
  const [user, setUser] = useState<User | null>(null)
  const [events, setEvents] = useState(mockEvents)
  const [searchTerm, setSearchTerm] = useState("")
  const [statusFilter, setStatusFilter] = useState("all")
  const [categoryFilter, setCategoryFilter] = useState("all")

  useEffect(() => {
    const userData = localStorage.getItem("user")
    if (userData) {
      setUser(JSON.parse(userData))
    }
  }, [])

  const isAdmin = user?.role === "admin"

  const filteredEvents = events.filter((event) => {
    const matchesSearch =
      event.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      event.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
      event.venue.toLowerCase().includes(searchTerm.toLowerCase())

    const matchesStatus = statusFilter === "all" || event.status === statusFilter
    const matchesCategory = categoryFilter === "all" || event.category.toLowerCase() === categoryFilter

    // If organizer, only show their events (simplified - in real app would filter by user ID)
    const matchesUser = isAdmin || event.organizer === user?.name

    return matchesSearch && matchesStatus && matchesCategory && matchesUser
  })

  const getStatusColor = (status: string) => {
    switch (status) {
      case "active":
        return "default"
      case "sold-out":
        return "destructive"
      case "draft":
        return "secondary"
      case "cancelled":
        return "outline"
      default:
        return "secondary"
    }
  }

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />

      <div className="flex-1 lg:ml-64">
        <div className="p-6 lg:p-8">
          {/* Header */}
          <div className="flex justify-between items-center mb-8">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">{isAdmin ? "All Events" : "My Events"}</h1>
              <p className="text-gray-600 mt-2">
                {isAdmin ? "Manage all events across the platform" : "Manage your created events"}
              </p>
            </div>
            <Link href="/create-event">
              <Button>
                <Plus className="h-4 w-4 mr-2" />
                Create Event
              </Button>
            </Link>
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
                    <SelectItem value="sold-out">Sold Out</SelectItem>
                    <SelectItem value="draft">Draft</SelectItem>
                    <SelectItem value="cancelled">Cancelled</SelectItem>
                  </SelectContent>
                </Select>
                <Select value={categoryFilter} onValueChange={setCategoryFilter}>
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

          {/* Events Grid */}
          <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
            {filteredEvents.map((event) => (
              <Card key={event.id} className="hover:shadow-lg transition-shadow">
                <CardHeader>
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <CardTitle className="text-lg">{event.title}</CardTitle>
                      <CardDescription className="mt-1">{event.description}</CardDescription>
                    </div>
                    <Badge variant={getStatusColor(event.status)}>{event.status}</Badge>
                  </div>
                </CardHeader>
                <CardContent className="space-y-4">
                  {/* Event Details */}
                  <div className="space-y-2">
                    <div className="flex items-center text-sm text-gray-600">
                      <Calendar className="h-4 w-4 mr-2" />
                      {event.date} at {event.time}
                    </div>
                    <div className="flex items-center text-sm text-gray-600">
                      <MapPin className="h-4 w-4 mr-2" />
                      {event.venue}, {event.location}
                    </div>
                    <div className="flex items-center text-sm text-gray-600">
                      <Users className="h-4 w-4 mr-2" />
                      {event.ticketsSold} / {event.capacity} attendees
                    </div>
                    <div className="flex items-center text-sm text-gray-600">
                      <DollarSign className="h-4 w-4 mr-2" />${event.revenue.toLocaleString()} revenue
                    </div>
                    {isAdmin && <div className="text-sm text-gray-600">Organizer: {event.organizer}</div>}
                  </div>

                  {/* Progress Bar */}
                  <div className="space-y-1">
                    <div className="flex justify-between text-sm">
                      <span>Tickets Sold</span>
                      <span>{Math.round((event.ticketsSold / event.capacity) * 100)}%</span>
                    </div>
                    <div className="w-full bg-gray-200 rounded-full h-2">
                      <div
                        className="bg-blue-600 h-2 rounded-full"
                        style={{ width: `${(event.ticketsSold / event.capacity) * 100}%` }}
                      />
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="flex justify-end space-x-2 pt-2">
                    <Button size="sm" variant="ghost">
                      <Eye className="h-4 w-4" />
                    </Button>
                    <Button size="sm" variant="ghost">
                      <Edit className="h-4 w-4" />
                    </Button>
                    {(isAdmin || event.organizer === user?.name) && (
                      <Button size="sm" variant="ghost">
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    )}
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* Empty State */}
          {filteredEvents.length === 0 && (
            <Card className="text-center py-12">
              <CardContent>
                <Calendar className="h-12 w-12 mx-auto text-gray-400 mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">No events found</h3>
                <p className="text-gray-600 mb-4">
                  {searchTerm || statusFilter !== "all" || categoryFilter !== "all"
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
    </div>
  )
}
