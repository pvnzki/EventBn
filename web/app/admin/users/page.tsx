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

interface User {
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

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [roleFilter, setRoleFilter] = useState("all");
  const [statusFilter, setStatusFilter] = useState("all");
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [userToDelete, setUserToDelete] = useState<User | null>(null);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const { toast } = useToast();

  useEffect(() => {
    // Fetch users from API
    const fetchUsers = async () => {
      try {
        setIsLoading(true);
        const response = await fetch("http://localhost:3000/api/users");
        const data = await response.json();

        if (data.success && Array.isArray(data.data)) {
          const mappedUsers: User[] = data.data.map((apiUser: ApiUser) => ({
            id: apiUser.user_id,
            name: apiUser.name,
            email: apiUser.email,
            role:
              apiUser.role.toLowerCase() === "organizer"
                ? "organizer"
                : apiUser.role.toLowerCase() === "admin"
                ? "admin"
                : "user",
            status: apiUser.is_active ? "active" : "inactive",
            eventsCreated:
              apiUser.role.toLowerCase() === "organizer"
                ? Math.floor(Math.random() * 20)
                : 0,
            totalRevenue:
              apiUser.role.toLowerCase() === "organizer"
                ? Math.floor(Math.random() * 50000)
                : 0,
            joinDate: new Date(apiUser.created_at).toISOString().split("T")[0],
            lastActive: new Date().toISOString().split("T")[0],
            avatar:
              apiUser.profile_picture || "/placeholder.svg?height=40&width=40",
          }));
          setUsers(mappedUsers);
        } else {
          throw new Error("Invalid API response format");
        }
      } catch (err) {
        setError("Failed to fetch users. Please try again later.");
        console.error(err);
      } finally {
        setIsLoading(false);
      }
    };

    fetchUsers();
  }, []);

  // Function to handle user deletion
  const handleDeleteUser = async (user: User) => {
    try {
      const response = await fetch(
        `http://localhost:3000/api/users/${user.id}`,
        {
          method: "DELETE",
        }
      );

      if (response.ok) {
        setUsers(users.filter((u) => u.id !== user.id));
        setUserToDelete(null);
        toast({
          title: "Success",
          description: "User deleted successfully.",
        });
      } else {
        throw new Error("Failed to delete user");
      }
    } catch (err) {
      console.error("Error deleting user:", err);
      toast({
        title: "Error",
        description: "Failed to delete user. Please try again.",
        variant: "destructive",
      });
    }
  };

  // Function to open delete modal
  const handleOpenDeleteModal = (user: User) => {
    setUserToDelete(user);
  };

  // Function to close delete modal
  const handleCloseDeleteModal = () => {
    setUserToDelete(null);
  };

  // Function to handle view user
  const handleViewUser = (user: User) => {
    setSelectedUser(user);
  };

  // Function to close view modal
  const closeViewModal = () => {
    setSelectedUser(null);
  };

  const filteredUsers = users.filter((user) => {
    const matchesSearch =
      user.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.email.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesRole = roleFilter === "all" || user.role === roleFilter;
    const matchesStatus =
      statusFilter === "all" || user.status === statusFilter;

    return matchesSearch && matchesRole && matchesStatus;
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

  const getRoleIcon = (role: string) => {
    return role === "admin" ? Shield : Users;
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
              <p className="text-gray-600">Fetching user data</p>
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
                User Management
              </h1>
              <p className="text-gray-600 mt-2">
                Manage all users and organizers on the platform
              </p>
            </div>
          </div>

          {/* Stats Cards */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  Total Users
                </CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{users.length}</div>
                <p className="text-xs text-muted-foreground">
                  +
                  {
                    users.filter(
                      (u) =>
                        new Date(u.joinDate) >
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
                  Active Users
                </CardTitle>
                <UserCheck className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {users.filter((u) => u.status === "active").length}
                </div>
                <p className="text-xs text-muted-foreground">
                  {users.length > 0
                    ? Math.round(
                        (users.filter((u) => u.status === "active").length /
                          users.length) *
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
                  Organizers
                </CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {users.filter((u) => u.role === "organizer").length}
                </div>
                <p className="text-xs text-muted-foreground">
                  {users.filter((u) => u.status === "pending").length} pending
                  approval
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">
                  Inactive Users
                </CardTitle>
                <UserX className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">
                  {users.filter((u) => u.status === "inactive").length}
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
                      placeholder="Search users..."
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="pl-10"
                    />
                  </div>
                </div>
                <Select value={roleFilter} onValueChange={setRoleFilter}>
                  <SelectTrigger className="w-40">
                    <SelectValue placeholder="Role" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Roles</SelectItem>
                    <SelectItem value="admin">Admin</SelectItem>
                    <SelectItem value="organizer">Organizer</SelectItem>
                    <SelectItem value="user">User</SelectItem>
                    <SelectItem value="customer">Customer</SelectItem>
                    <SelectItem value="guest">Guest</SelectItem>
                  </SelectContent>
                </Select>
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

          {/* Users Table */}
          <Card>
            <CardHeader>
              <CardTitle>Users</CardTitle>
              <CardDescription>
                Manage user accounts and permissions
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {filteredUsers.map((user) => {
                  const RoleIcon = getRoleIcon(user.role);

                  return (
                    <div
                      key={user.id}
                      className="flex items-center justify-between p-4 border rounded-lg hover:bg-gray-50"
                    >
                      <div className="flex items-center space-x-4">
                        <Avatar>
                          <AvatarImage
                            src={user.avatar || "/placeholder.svg"}
                            alt={user.name}
                          />
                          <AvatarFallback>
                            {user.name
                              .split(" ")
                              .map((n) => n[0])
                              .join("")}
                          </AvatarFallback>
                        </Avatar>

                        <div className="flex-1">
                          <div className="flex items-center space-x-2">
                            <h3 className="font-semibold text-gray-900">
                              {user.name}
                            </h3>
                            <RoleIcon className="h-4 w-4 text-gray-500" />
                            <Badge
                              variant={
                                user.role === "admin" ? "default" : "secondary"
                              }
                            >
                              {user.role}
                            </Badge>
                            <Badge variant={getStatusColor(user.status)}>
                              {user.status}
                            </Badge>
                          </div>

                          <div className="flex items-center space-x-4 mt-1 text-sm text-gray-600">
                            <div className="flex items-center">
                              <Mail className="h-3 w-3 mr-1" />
                              {user.email}
                            </div>
                            <div className="flex items-center">
                              <Calendar className="h-3 w-3 mr-1" />
                              Joined {user.joinDate}
                            </div>
                          </div>

                          {user.role === "organizer" && (
                            <div className="flex items-center space-x-4 mt-1 text-sm text-gray-600">
                              <span>{user.eventsCreated} events created</span>
                              <span>
                                ${user.totalRevenue.toLocaleString()} total
                                revenue
                              </span>
                              <span>Last active: {user.lastActive}</span>
                            </div>
                          )}
                        </div>
                      </div>

                      <div className="flex items-center space-x-2">
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => handleViewUser(user)}
                        >
                          <Eye className="h-4 w-4" />
                        </Button>
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => handleOpenDeleteModal(user)}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>
                  );
                })}
              </div>

              {/* Empty State */}
              {filteredUsers.length === 0 && (
                <div className="text-center py-12">
                  <Users className="h-12 w-12 mx-auto text-gray-400 mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 mb-2">
                    No users found
                  </h3>
                  <p className="text-gray-600">
                    Try adjusting your filters to see more users.
                  </p>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Delete Confirmation Modal */}
          {userToDelete && (
            <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
              <div className="bg-white rounded-lg p-6 w-full max-w-md">
                <div className="flex justify-between items-center mb-4">
                  <h2 className="text-lg font-bold">Confirm Delete</h2>
                  <Button variant="ghost" onClick={handleCloseDeleteModal}>
                    <X className="h-4 w-4" />
                  </Button>
                </div>
                <p className="text-sm text-gray-600 mb-4">
                  Are you sure you want to delete the user "{userToDelete.name}
                  "?
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
                    onClick={() => handleDeleteUser(userToDelete)}
                  >
                    Yes
                  </Button>
                </div>
              </div>
            </div>
          )}

          {/* View User Modal */}
          {selectedUser && (
            <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
              <div className="bg-white rounded-lg p-4 w-full max-w-md max-h-[80vh] overflow-y-auto">
                <div className="flex justify-between items-center mb-3">
                  <h2 className="text-lg font-bold">{selectedUser.name}</h2>
                  <Button variant="ghost" onClick={closeViewModal}>
                    <X className="h-4 w-4" />
                  </Button>
                </div>
                <div className="space-y-2">
                  <Avatar className="w-16 h-16">
                    <AvatarImage
                      src={selectedUser.avatar || "/placeholder.svg"}
                      alt={selectedUser.name}
                    />
                    <AvatarFallback>
                      {selectedUser.name
                        .split(" ")
                        .map((n) => n[0])
                        .join("")}
                    </AvatarFallback>
                  </Avatar>
                  <p className="text-sm">
                    <strong>User ID:</strong> {selectedUser.id}
                  </p>
                  <p className="text-sm">
                    <strong>Name:</strong> {selectedUser.name}
                  </p>
                  <p className="text-sm">
                    <strong>Email:</strong> {selectedUser.email}
                  </p>
                  <p className="text-sm">
                    <strong>Role:</strong> {selectedUser.role}
                  </p>
                  <p className="text-sm">
                    <strong>Status:</strong> {selectedUser.status}
                  </p>
                  <p className="text-sm">
                    <strong>Join Date:</strong> {selectedUser.joinDate}
                  </p>
                  <p className="text-sm">
                    <strong>Last Active:</strong> {selectedUser.lastActive}
                  </p>
                  {selectedUser.role === "organizer" && (
                    <>
                      <p className="text-sm">
                        <strong>Events Created:</strong>{" "}
                        {selectedUser.eventsCreated}
                      </p>
                      <p className="text-sm">
                        <strong>Total Revenue:</strong> $
                        {selectedUser.totalRevenue.toLocaleString()}
                      </p>
                    </>
                  )}
                  <p className="text-sm">
                    <strong>Avatar URL:</strong>{" "}
                    {selectedUser.avatar ? (
                      <a
                        href={selectedUser.avatar}
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
