"use client";

import { useState, useEffect } from "react";
import { Sidebar } from "@/components/layout/sidebar";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
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
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { useToast } from "@/components/ui/use-toast";
import {
  Search,
  Plus,
  Eye,
  Edit,
  Trash2,
  Users,
  Mail,
  Calendar,
  UserCheck,
  UserX,
  X,
  Shield,
} from "lucide-react";

interface Organizer {
  id: number;
  name: string;
  email: string;
  role: string;
  status: string;
  eventsCreated: number;
  totalRevenue: number;
  joinDate: string;
  lastActive: string;
  avatar: string | null;
}

interface ApiUser {
  user_id: number;
  name: string;
  email: string;
  phone_number: string | null;
  profile_picture: string | null;
  is_active: boolean;
  is_email_verified: boolean;
  role: string;
  created_at: string;
}

export default function OrganizersPage() {
  const [organizers, setOrganizers] = useState<Organizer[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [organizerToDelete, setOrganizerToDelete] = useState<Organizer | null>(
    null
  );
  const [selectedOrganizer, setSelectedOrganizer] = useState<Organizer | null>(
    null
  );
  const { toast } = useToast();

  useEffect(() => {
    // Fetch organizers from API
    const fetchOrganizers = async () => {
      try {
        setIsLoading(true);
        const response = await fetch("http://localhost:3000/api/users");
        const data = await response.json();

        if (data.success && Array.isArray(data.data)) {
          const mappedOrganizers: Organizer[] = data.data
            .filter(
              (apiUser: ApiUser) => apiUser.role.toLowerCase() === "organizer"
            )
            .map((apiUser: ApiUser) => ({
              id: apiUser.user_id,
              name: apiUser.name,
              email: apiUser.email,
              role: "organizer",
              status: apiUser.is_active ? "active" : "inactive",
              eventsCreated: Math.floor(Math.random() * 20),
              totalRevenue: Math.floor(Math.random() * 50000),
              joinDate: new Date(apiUser.created_at)
                .toISOString()
                .split("T")[0],
              lastActive: new Date().toISOString().split("T")[0],
              avatar:
                apiUser.profile_picture ||
                "/placeholder.svg?height=40&width=40",
            }));
          setOrganizers(mappedOrganizers);
        } else {
          throw new Error("Invalid API response format");
        }
      } catch (err) {
        setError("Failed to fetch organizers. Please try again later.");
        console.error(err);
      } finally {
        setIsLoading(false);
      }
    };

    fetchOrganizers();
  }, []);

  // Function to handle organizer deletion
  const handleDeleteOrganizer = async (organizer: Organizer) => {
    try {
      const response = await fetch(
        `http://localhost:3000/api/users/${organizer.id}`,
        {
          method: "DELETE",
        }
      );

      if (response.ok) {
        setOrganizers(organizers.filter((o) => o.id !== organizer.id));
        setOrganizerToDelete(null);
        toast({
          title: "Success",
          description: "Organizer deleted successfully.",
        });
      } else {
        throw new Error("Failed to delete organizer");
      }
    } catch (err) {
      console.error("Error deleting organizer:", err);
      toast({
        title: "Error",
        description: "Failed to delete organizer. Please try again.",
        variant: "destructive",
      });
    }
  };

  // Function to open delete modal
  const handleOpenDeleteModal = (organizer: Organizer) => {
    setOrganizerToDelete(organizer);
  };

  // Function to close delete modal
  const handleCloseDeleteModal = () => {
    setOrganizerToDelete(null);
  };

  // Function to handle view organizer
  const handleViewOrganizer = (organizer: Organizer) => {
    setSelectedOrganizer(organizer);
  };

  // Function to close view modal
  const closeViewModal = () => {
    setSelectedOrganizer(null);
  };

  const filteredOrganizers = organizers.filter((organizer) => {
    const matchesSearch =
      organizer.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      organizer.email.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesStatus =
      statusFilter === "all" || organizer.status === statusFilter;

    return matchesSearch && matchesStatus;
  });

  const getStatusColor = (status: string) => {
    switch (status) {
      case "active":
        return "default";
      case "inactive":
        return "secondary";
      case "pending":
        return "outline";
      case "suspended":
        return "destructive";
      default:
        return "secondary";
    }
  };

  if (isLoading) {
    return (
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <div className="flex-1 lg:ml-64 flex items-center justify-center">
          <Card className="max-w-md">
            <CardContent className="pt-6 text-center">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-gray-900 mx-auto mb-4" />
              <h2 className="text-xl font-semibold mb-2">Loading...</h2>
              <p className="text-gray-600">Fetching organizer data</p>
            </CardContent>
          </Card>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <div className="flex-1 lg:ml-64 flex items-center justify-center">
          <Card className="max-w-md">
            <CardContent className="pt-6 text-center">
              <Shield className="h-12 w-12 mx-auto text-gray-400 mb-4" />
              <h2 className="text-xl font-semibold mb-2">Error</h2>
              <p className="text-gray-600">{error}</p>
            </CardContent>
          </Card>
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
                Organizer Management
              </h1>
              <p className="text-gray-600 mt-2">
                Manage all organizers on the platform
              </p>
            </div>
          </div>

          {/* Stats Cards */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  Total Organizers
                </CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{organizers.length}</div>
                <p className="text-xs text-muted-foreground">
                  +
                  {
                    organizers.filter(
                      (o) =>
                        new Date(o.joinDate) >
                        new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
                    ).length
                  }{" "}
                  from last month
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  Active Organizers
                </CardTitle>
                <UserCheck className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {organizers.filter((o) => o.status === "active").length}
                </div>
                <p className="text-xs text-muted-foreground">
                  {organizers.length > 0
                    ? Math.round(
                        (organizers.filter((o) => o.status === "active")
                          .length /
                          organizers.length) *
                          100
                      )
                    : 0}
                  % of total
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  Inactive Organizers
                </CardTitle>
                <UserX className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {organizers.filter((o) => o.status === "inactive").length}
                </div>
                <p className="text-xs text-muted-foreground">Need attention</p>
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
                      placeholder="Search organizers..."
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
                    <SelectItem value="inactive">Inactive</SelectItem>
                    <SelectItem value="pending">Pending</SelectItem>
                    <SelectItem value="suspended">Suspended</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </CardContent>
          </Card>

          {/* Organizers Table */}
          <Card>
            <CardHeader>
              <CardTitle>Organizers</CardTitle>
              <CardDescription>
                Manage organizer accounts and permissions
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {filteredOrganizers.map((organizer) => {
                  return (
                    <div
                      key={organizer.id}
                      className="flex items-center justify-between p-4 border rounded-lg hover:bg-gray-50"
                    >
                      <div className="flex items-center space-x-4">
                        <Avatar>
                          <AvatarImage
                            src={organizer.avatar || "/placeholder.svg"}
                            alt={organizer.name}
                          />
                          <AvatarFallback>
                            {organizer.name
                              .split(" ")
                              .map((n) => n[0])
                              .join("")}
                          </AvatarFallback>
                        </Avatar>

                        <div className="flex-1">
                          <div className="flex items-center space-x-2">
                            <h3 className="font-semibold text-gray-900">
                              {organizer.name}
                            </h3>
                            <Users className="h-4 w-4 text-gray-500" />
                            <Badge variant="secondary">organizer</Badge>
                            <Badge variant={getStatusColor(organizer.status)}>
                              {organizer.status}
                            </Badge>
                          </div>

                          <div className="flex items-center space-x-4 mt-1 text-sm text-gray-600">
                            <div className="flex items-center">
                              <Mail className="h-3 w-3 mr-1" />
                              {organizer.email}
                            </div>
                            <div className="flex items-center">
                              <Calendar className="h-3 w-3 mr-1" />
                              Joined {organizer.joinDate}
                            </div>
                          </div>

                          <div className="flex items-center space-x-4 mt-1 text-sm text-gray-600">
                            <span>
                              {organizer.eventsCreated} events created
                            </span>
                            <span>
                              ${organizer.totalRevenue.toLocaleString()} total
                              revenue
                            </span>
                            <span>Last active: {organizer.lastActive}</span>
                          </div>
                        </div>
                      </div>

                      <div className="flex items-center space-x-2">
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => handleViewOrganizer(organizer)}
                        >
                          <Eye className="h-4 w-4" />
                        </Button>
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => handleOpenDeleteModal(organizer)}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>
                  );
                })}
              </div>

              {/* Empty State */}
              {filteredOrganizers.length === 0 && (
                <div className="text-center py-12">
                  <Users className="h-12 w-12 mx-auto text-gray-400 mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 mb-2">
                    No organizers found
                  </h3>
                  <p className="text-gray-600">
                    Try adjusting your filters to see more organizers.
                  </p>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Delete Confirmation Modal */}
          {organizerToDelete && (
            <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
              <div className="bg-white rounded-lg p-6 w-full max-w-md">
                <div className="flex justify-between items-center mb-4">
                  <h2 className="text-lg font-bold">Confirm Delete</h2>
                  <Button variant="ghost" onClick={handleCloseDeleteModal}>
                    <X className="h-4 w-4" />
                  </Button>
                </div>
                <p className="text-sm text-gray-600 mb-4">
                  Are you sure you want to delete the organizer "
                  {organizerToDelete.name}"?
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
                    onClick={() => handleDeleteOrganizer(organizerToDelete)}
                  >
                    Yes
                  </Button>
                </div>
              </div>
            </div>
          )}

          {/* View Organizer Modal */}
          {selectedOrganizer && (
            <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
              <div className="bg-white rounded-lg p-4 w-full max-w-md max-h-[80vh] overflow-y-auto">
                <div className="flex justify-between items-center mb-3">
                  <h2 className="text-lg font-bold">
                    {selectedOrganizer.name}
                  </h2>
                  <Button variant="ghost" onClick={closeViewModal}>
                    <X className="h-4 w-4" />
                  </Button>
                </div>
                <div className="space-y-2">
                  <Avatar className="w-16 h-16">
                    <AvatarImage
                      src={selectedOrganizer.avatar || "/placeholder.svg"}
                      alt={selectedOrganizer.name}
                    />
                    <AvatarFallback>
                      {selectedOrganizer.name
                        .split(" ")
                        .map((n) => n[0])
                        .join("")}
                    </AvatarFallback>
                  </Avatar>
                  <p className="text-sm">
                    <strong>User ID:</strong> {selectedOrganizer.id}
                  </p>
                  <p className="text-sm">
                    <strong>Name:</strong> {selectedOrganizer.name}
                  </p>
                  <p className="text-sm">
                    <strong>Email:</strong> {selectedOrganizer.email}
                  </p>
                  <p className="text-sm">
                    <strong>Role:</strong> {selectedOrganizer.role}
                  </p>
                  <p className="text-sm">
                    <strong>Status:</strong> {selectedOrganizer.status}
                  </p>
                  <p className="text-sm">
                    <strong>Join Date:</strong> {selectedOrganizer.joinDate}
                  </p>
                  <p className="text-sm">
                    <strong>Last Active:</strong> {selectedOrganizer.lastActive}
                  </p>
                  <p className="text-sm">
                    <strong>Events Created:</strong>{" "}
                    {selectedOrganizer.eventsCreated}
                  </p>
                  <p className="text-sm">
                    <strong>Total Revenue:</strong> $
                    {selectedOrganizer.totalRevenue.toLocaleString()}
                  </p>
                  <p className="text-sm">
                    <strong>Avatar URL:</strong>{" "}
                    {selectedOrganizer.avatar ? (
                      <a
                        href={selectedOrganizer.avatar}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-blue-600 hover:underline"
                      >
                        View Avatar
                      </a>
                    ) : (
                      "N/A"
                    )}
                  </p>
                </div>
                <div className="mt-3 flex justify-end">
                  <Button onClick={closeViewModal} size="sm">
                    Close
                  </Button>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
