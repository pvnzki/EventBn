"use client"

import { useState, useEffect } from "react"
import { Sidebar } from "@/components/layout/sidebar"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Search, Plus, Eye, Edit, Trash2, Ticket, DollarSign, Users, TrendingUp, Download, Mail } from "lucide-react"

interface User {
  role: "admin" | "organizer"
  name: string
}

interface TicketType {
  id: string
  eventId: string
  eventName: string
  name: string
  description: string
  price: number
  quantity: number
  sold: number
  status: "active" | "paused" | "sold-out"
  salesStart: string
  salesEnd: string
  category: string
}

const mockTickets: TicketType[] = [
  {
    id: "1",
    eventId: "1",
    eventName: "Tech Conference 2024",
    name: "General Admission",
    description: "Standard entry ticket with access to all sessions",
    price: 99,
    quantity: 500,
    sold: 350,
    status: "active",
    salesStart: "2024-01-01",
    salesEnd: "2024-03-14",
    category: "standard",
  },
  {
    id: "2",
    eventId: "1",
    eventName: "Tech Conference 2024",
    name: "VIP Pass",
    description: "Premium access with networking dinner and priority seating",
    price: 299,
    quantity: 100,
    sold: 85,
    status: "active",
    salesStart: "2024-01-01",
    salesEnd: "2024-03-14",
    category: "premium",
  },
  {
    id: "3",
    eventId: "2",
    eventName: "Music Festival Summer",
    name: "Early Bird",
    description: "Limited time early bird pricing",
    price: 75,
    quantity: 200,
    sold: 200,
    status: "sold-out",
    salesStart: "2023-12-01",
    salesEnd: "2024-01-31",
    category: "early-bird",
  },
  {
    id: "4",
    eventId: "2",
    eventName: "Music Festival Summer",
    name: "Regular Admission",
    description: "Standard festival pass",
    price: 120,
    quantity: 800,
    sold: 650,
    status: "active",
    salesStart: "2024-02-01",
    salesEnd: "2024-06-19",
    category: "standard",
  },
  {
    id: "5",
    eventId: "3",
    eventName: "Business Workshop",
    name: "Workshop Access",
    description: "Full day workshop with materials included",
    price: 150,
    quantity: 50,
    sold: 0,
    status: "paused",
    salesStart: "2024-03-01",
    salesEnd: "2024-04-09",
    category: "workshop",
  },
]

export default function TicketsPage() {
  const [user, setUser] = useState<User | null>(null)
  const [tickets, setTickets] = useState<TicketType[]>(mockTickets)
  const [searchTerm, setSearchTerm] = useState("")
  const [statusFilter, setStatusFilter] = useState("all")
  const [eventFilter, setEventFilter] = useState("all")
  const [isCreateDialogOpen, setIsCreateDialogOpen] = useState(false)
  const [newTicket, setNewTicket] = useState({
    eventName: "",
    name: "",
    description: "",
    price: "",
    quantity: "",
    salesStart: "",
    salesEnd: "",
    category: "standard",
  })

  useEffect(() => {
    const userData = localStorage.getItem("user")
    if (userData) {
      setUser(JSON.parse(userData))
    }
  }, [])

  const isAdmin = user?.role === "admin"

  const filteredTickets = tickets.filter((ticket) => {
    const matchesSearch =
      ticket.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      ticket.eventName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      ticket.description.toLowerCase().includes(searchTerm.toLowerCase())

    const matchesStatus = statusFilter === "all" || ticket.status === statusFilter
    const matchesEvent = eventFilter === "all" || ticket.eventName === eventFilter

    return matchesSearch && matchesStatus && matchesEvent
  })

  const getStatusColor = (status: string) => {
    switch (status) {
      case "active":
        return "default"
      case "sold-out":
        return "destructive"
      case "paused":
        return "secondary"
      default:
        return "secondary"
    }
  }

  const getCategoryColor = (category: string) => {
    switch (category) {
      case "premium":
        return "default"
      case "early-bird":
        return "secondary"
      case "workshop":
        return "outline"
      default:
        return "secondary"
    }
  }

  const handleCreateTicket = () => {
    const ticket: TicketType = {
      id: Date.now().toString(),
      eventId: Date.now().toString(),
      eventName: newTicket.eventName,
      name: newTicket.name,
      description: newTicket.description,
      price: Number.parseFloat(newTicket.price),
      quantity: Number.parseInt(newTicket.quantity),
      sold: 0,
      status: "active",
      salesStart: newTicket.salesStart,
      salesEnd: newTicket.salesEnd,
      category: newTicket.category,
    }

    setTickets([...tickets, ticket])
    setIsCreateDialogOpen(false)
    setNewTicket({
      eventName: "",
      name: "",
      description: "",
      price: "",
      quantity: "",
      salesStart: "",
      salesEnd: "",
      category: "standard",
    })
  }

  const totalRevenue = tickets.reduce((sum, ticket) => sum + ticket.price * ticket.sold, 0)
  const totalSold = tickets.reduce((sum, ticket) => sum + ticket.sold, 0)
  const totalAvailable = tickets.reduce((sum, ticket) => sum + ticket.quantity, 0)

  const uniqueEvents = [...new Set(tickets.map((ticket) => ticket.eventName))]

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />

      <div className="flex-1 lg:ml-64">
        <div className="p-6 lg:p-8">
          {/* Header */}
          <div className="flex justify-between items-center mb-8">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Ticket Management</h1>
              <p className="text-gray-600 mt-2">
                {isAdmin ? "Manage all tickets across the platform" : "Manage your event tickets and sales"}
              </p>
            </div>
            <Dialog open={isCreateDialogOpen} onOpenChange={setIsCreateDialogOpen}>
              <DialogTrigger asChild>
                <Button>
                  <Plus className="h-4 w-4 mr-2" />
                  Create Ticket Type
                </Button>
              </DialogTrigger>
              <DialogContent className="max-w-2xl">
                <DialogHeader>
                  <DialogTitle>Create New Ticket Type</DialogTitle>
                  <DialogDescription>
                    Add a new ticket type for your event with pricing and availability details.
                  </DialogDescription>
                </DialogHeader>
                <div className="space-y-4">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label htmlFor="event-name">Event Name</Label>
                      <Input
                        id="event-name"
                        placeholder="Select or enter event name"
                        value={newTicket.eventName}
                        onChange={(e) => setNewTicket({ ...newTicket, eventName: e.target.value })}
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="ticket-name">Ticket Name</Label>
                      <Input
                        id="ticket-name"
                        placeholder="e.g., General Admission, VIP"
                        value={newTicket.name}
                        onChange={(e) => setNewTicket({ ...newTicket, name: e.target.value })}
                      />
                    </div>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="description">Description</Label>
                    <Textarea
                      id="description"
                      placeholder="Describe what's included with this ticket..."
                      value={newTicket.description}
                      onChange={(e) => setNewTicket({ ...newTicket, description: e.target.value })}
                    />
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div className="space-y-2">
                      <Label htmlFor="price">Price ($)</Label>
                      <Input
                        id="price"
                        type="number"
                        step="0.01"
                        placeholder="0.00"
                        value={newTicket.price}
                        onChange={(e) => setNewTicket({ ...newTicket, price: e.target.value })}
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="quantity">Quantity</Label>
                      <Input
                        id="quantity"
                        type="number"
                        placeholder="100"
                        value={newTicket.quantity}
                        onChange={(e) => setNewTicket({ ...newTicket, quantity: e.target.value })}
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="category">Category</Label>
                      <Select
                        value={newTicket.category}
                        onValueChange={(value) => setNewTicket({ ...newTicket, category: value })}
                      >
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="standard">Standard</SelectItem>
                          <SelectItem value="premium">Premium</SelectItem>
                          <SelectItem value="early-bird">Early Bird</SelectItem>
                          <SelectItem value="workshop">Workshop</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label htmlFor="sales-start">Sales Start Date</Label>
                      <Input
                        id="sales-start"
                        type="date"
                        value={newTicket.salesStart}
                        onChange={(e) => setNewTicket({ ...newTicket, salesStart: e.target.value })}
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="sales-end">Sales End Date</Label>
                      <Input
                        id="sales-end"
                        type="date"
                        value={newTicket.salesEnd}
                        onChange={(e) => setNewTicket({ ...newTicket, salesEnd: e.target.value })}
                      />
                    </div>
                  </div>

                  <div className="flex justify-end space-x-2 pt-4">
                    <Button variant="outline" onClick={() => setIsCreateDialogOpen(false)}>
                      Cancel
                    </Button>
                    <Button onClick={handleCreateTicket}>Create Ticket Type</Button>
                  </div>
                </div>
              </DialogContent>
            </Dialog>
          </div>

          {/* Stats Cards */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Total Revenue</CardTitle>
                <DollarSign className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">${totalRevenue.toLocaleString()}</div>
                <p className="text-xs text-muted-foreground">From ticket sales</p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Tickets Sold</CardTitle>
                <Ticket className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{totalSold.toLocaleString()}</div>
                <p className="text-xs text-muted-foreground">
                  {Math.round((totalSold / totalAvailable) * 100)}% of total available
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Available Tickets</CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{(totalAvailable - totalSold).toLocaleString()}</div>
                <p className="text-xs text-muted-foreground">Remaining inventory</p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Avg. Ticket Price</CardTitle>
                <TrendingUp className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">${totalSold > 0 ? Math.round(totalRevenue / totalSold) : 0}</div>
                <p className="text-xs text-muted-foreground">Average selling price</p>
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
                      placeholder="Search tickets..."
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
                    <SelectItem value="active">Active</SelectItem>
                    <SelectItem value="sold-out">Sold Out</SelectItem>
                    <SelectItem value="paused">Paused</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </CardContent>
          </Card>

          {/* Tickets Grid */}
          <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
            {filteredTickets.map((ticket) => (
              <Card key={ticket.id} className="hover:shadow-lg transition-shadow">
                <CardHeader>
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <CardTitle className="text-lg">{ticket.name}</CardTitle>
                      <CardDescription className="mt-1">{ticket.eventName}</CardDescription>
                    </div>
                    <div className="flex flex-col items-end space-y-1">
                      <Badge variant={getStatusColor(ticket.status)}>{ticket.status}</Badge>
                      <Badge variant={getCategoryColor(ticket.category)}>{ticket.category}</Badge>
                    </div>
                  </div>
                </CardHeader>
                <CardContent className="space-y-4">
                  {/* Ticket Details */}
                  <div className="space-y-2">
                    <p className="text-sm text-gray-600">{ticket.description}</p>
                    <div className="flex items-center justify-between">
                      <div className="flex items-center text-sm text-gray-600">
                        <DollarSign className="h-4 w-4 mr-1" />${ticket.price}
                      </div>
                      <div className="flex items-center text-sm text-gray-600">
                        <Users className="h-4 w-4 mr-1" />
                        {ticket.sold} / {ticket.quantity} sold
                      </div>
                    </div>
                    <div className="text-sm text-gray-600">
                      Sales: {ticket.salesStart} to {ticket.salesEnd}
                    </div>
                  </div>

                  {/* Progress Bar */}
                  <div className="space-y-1">
                    <div className="flex justify-between text-sm">
                      <span>Sales Progress</span>
                      <span>{Math.round((ticket.sold / ticket.quantity) * 100)}%</span>
                    </div>
                    <div className="w-full bg-gray-200 rounded-full h-2">
                      <div
                        className={`h-2 rounded-full ${
                          ticket.status === "sold-out"
                            ? "bg-red-600"
                            : ticket.status === "active"
                              ? "bg-blue-600"
                              : "bg-gray-400"
                        }`}
                        style={{ width: `${(ticket.sold / ticket.quantity) * 100}%` }}
                      />
                    </div>
                  </div>

                  {/* Revenue */}
                  <div className="p-3 bg-gray-50 rounded-lg">
                    <div className="flex justify-between items-center">
                      <span className="text-sm font-medium">Revenue Generated</span>
                      <span className="text-lg font-bold text-green-600">
                        ${(ticket.price * ticket.sold).toLocaleString()}
                      </span>
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="flex justify-between items-center pt-2">
                    <div className="flex space-x-1">
                      <Button size="sm" variant="ghost">
                        <Eye className="h-4 w-4" />
                      </Button>
                      <Button size="sm" variant="ghost">
                        <Edit className="h-4 w-4" />
                      </Button>
                      <Button size="sm" variant="ghost">
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                    <div className="flex space-x-1">
                      <Button size="sm" variant="outline">
                        <Download className="h-4 w-4 mr-1" />
                        Export
                      </Button>
                      <Button size="sm" variant="outline">
                        <Mail className="h-4 w-4 mr-1" />
                        Email
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
                <h3 className="text-lg font-medium text-gray-900 mb-2">No tickets found</h3>
                <p className="text-gray-600 mb-4">
                  {searchTerm || statusFilter !== "all" || eventFilter !== "all"
                    ? "Try adjusting your filters to see more tickets."
                    : "Get started by creating your first ticket type."}
                </p>
                <Button onClick={() => setIsCreateDialogOpen(true)}>
                  <Plus className="h-4 w-4 mr-2" />
                  Create Ticket Type
                </Button>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  )
}
