"use client";

import { useState, useEffect, useRef } from "react";
import { apiUrl } from "@/lib/api";
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
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Shield, Camera, User, Building2 } from "lucide-react";

interface UserType {
  user_id: number;
  name: string;
  email: string;
  phone_number: string | null;
  profile_picture: string | null;
  role: "ADMIN" | "ORGANIZER";
  is_active: boolean;
  is_email_verified: boolean;
  created_at: string;
}

export default function OrganizerSettingsPage() {
  const [user, setUser] = useState<UserType | null>(null);
  const [profileData, setProfileData] = useState({
    name: "",
    email: "",
    phone: "",
    avatar: "/placeholder.svg?height=100&width=100",
  });
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showPopup, setShowPopup] = useState(false);
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  // Organization state variables
  const [organizationData, setOrganizationData] = useState({
    name: "",
    description: "",
    contact_email: "",
    contact_number: "",
    website_url: "",
    logo_url: "",
  });
  const [organizationLogo, setOrganizationLogo] = useState<File | null>(null);

  // Password state variables
  const [passwordData, setPasswordData] = useState({
    currentPassword: "",
    newPassword: "",
    confirmPassword: "",
  });
  const [passwordLoading, setPasswordLoading] = useState(false);

  useEffect(() => {
    const fetchUserData = async () => {
      try {
        const userData = localStorage.getItem("user");
        if (!userData) {
          setError("No user data found in local storage");
          setLoading(false);
          return;
        }

        const parsedUser = JSON.parse(userData);
        const userId = parsedUser.user_id;

        if (!userId) {
          setError("User ID not found");
          setLoading(false);
          return;
        }

        const token = localStorage.getItem("token");
        if (!token) {
          setError("Authentication token not found");
          setLoading(false);
          return;
        }

        const response = await fetch(apiUrl(`api/users/${userId}`), {
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
          },
        });
        if (!response.ok) throw new Error("Failed to fetch user data");

        const result = await response.json();
        if (result.success && result.data) {
          setUser(result.data);
          setProfileData({
            name: result.data.name || "",
            email: result.data.email || "",
            phone: result.data.phone_number || "",
            avatar:
              result.data.profile_picture ||
              "/placeholder.svg?height=100&width=100",
          });

          // Fetch organization data
          try {
            const orgResponse = await fetch(
              apiUrl(`api/organizations/user/${userId}`),
              {
                headers: {
                  Authorization: `Bearer ${token}`,
                  "Content-Type": "application/json",
                },
              }
            );

            if (orgResponse.ok) {
              const orgResult = await orgResponse.json();
              if (orgResult.success && orgResult.data) {
                setOrganizationData({
                  name: orgResult.data.name || "",
                  description: orgResult.data.description || "",
                  contact_email: orgResult.data.contact_email || "",
                  contact_number: orgResult.data.contact_number || "",
                  website_url: orgResult.data.website_url || "",
                  logo_url: orgResult.data.logo_url || "",
                });
              }
            }
            // If organization doesn't exist (404), that's ok - user hasn't created one yet
          } catch (orgErr) {
            console.log("No existing organization found for user");
          }
        } else throw new Error("Invalid API response");
      } catch (err) {
        console.error("Error fetching user data:", err);
        const errorMessage =
          err instanceof Error ? err.message : "Error fetching user data";
        setError(errorMessage);

        // If it's an authentication error, clear localStorage and redirect to login
        if (
          errorMessage.includes("Authentication token") ||
          errorMessage.includes("Invalid API response") ||
          errorMessage.includes("User not found")
        ) {
          localStorage.removeItem("token");
          localStorage.removeItem("user");
          // Redirect to login page
          window.location.href = "/login";
        }
      } finally {
        setLoading(false);
      }
    };

    fetchUserData();
  }, []);

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    if (file.size > 5 * 1024 * 1024) {
      alert("File size must be less than 5MB");
      return;
    }

    // Check if it's an image file
    if (!file.type.startsWith("image/")) {
      alert("Please select an image file");
      return;
    }

    setSelectedFile(file);

    // Create preview URL
    const reader = new FileReader();
    reader.onloadend = () => {
      setProfileData({ ...profileData, avatar: reader.result as string });
    };
    reader.readAsDataURL(file);
  };

  const handleProfileSave = async () => {
    try {
      const userData = localStorage.getItem("user");
      if (!userData) return;

      const parsedUser = JSON.parse(userData);
      const userId = parsedUser.user_id;

      const token = localStorage.getItem("token");
      if (!token) {
        alert("Authentication token not found");
        return;
      }

      // Create FormData for multipart/form-data request
      const formData = new FormData();
      formData.append("name", profileData.name);
      formData.append("email", profileData.email);
      formData.append("phone_number", profileData.phone);

      // Only append the file if a new one was selected
      if (selectedFile) {
        formData.append("profile_picture", selectedFile);
      }

      const response = await fetch(apiUrl(`api/users/${userId}`), {
        method: "PUT",
        headers: {
          Authorization: `Bearer ${token}`,
          // Don't set Content-Type header - let browser set it with boundary
        },
        body: formData,
      });

      if (!response.ok) throw new Error("Failed to save profile data");

      const result = await response.json();

      if (result.success && result.data) {
        setUser(result.data);
        setProfileData({
          name: result.data.name,
          email: result.data.email,
          phone: result.data.phone_number || "",
          avatar:
            result.data.profile_picture ||
            "/placeholder.svg?height=100&width=100",
        });

        // Clear selected file after successful upload
        setSelectedFile(null);

        localStorage.setItem("user", JSON.stringify(result.data));

        setShowPopup(true);
        setTimeout(() => setShowPopup(false), 3000);
      }
    } catch (err) {
      console.error("Error saving profile:", err);
      alert("Failed to save profile. Please try again.");
    }
  };

  const handleOrganizationSave = async () => {
    try {
      const userData = localStorage.getItem("user");
      if (!userData) return;

      const parsedUser = JSON.parse(userData);
      const userId = parsedUser.user_id;

      const token = localStorage.getItem("token");
      if (!token) {
        alert("Authentication token not found");
        return;
      }

      // Create FormData for multipart/form-data request
      const formData = new FormData();
      formData.append("name", organizationData.name);
      formData.append("description", organizationData.description);
      formData.append("contact_email", organizationData.contact_email);
      formData.append("contact_number", organizationData.contact_number);
      formData.append("website_url", organizationData.website_url);

      // Only append the logo file if a new one was selected
      if (organizationLogo) {
        formData.append("logo", organizationLogo);
      }

      const response = await fetch(apiUrl(`api/organizations/user/${userId}`), {
        method: "POST",
        headers: {
          Authorization: `Bearer ${token}`,
          // Don't set Content-Type header - let browser set it with boundary
        },
        body: formData,
      });

      if (!response.ok) throw new Error("Failed to save organization data");

      const result = await response.json();

      if (result.success && result.data) {
        setOrganizationData({
          name: result.data.name || "",
          description: result.data.description || "",
          contact_email: result.data.contact_email || "",
          contact_number: result.data.contact_number || "",
          website_url: result.data.website_url || "",
          logo_url: result.data.logo_url || "",
        });

        // Clear selected logo file after successful upload
        setOrganizationLogo(null);

        setShowPopup(true);
        setTimeout(() => setShowPopup(false), 3000);
      }
    } catch (err) {
      console.error("Error saving organization:", err);
      alert("Failed to save organization. Please try again.");
    }
  };

  const handlePasswordUpdate = async () => {
    // Validation
    if (!passwordData.currentPassword) {
      alert("Please enter your current password");
      return;
    }

    if (!passwordData.newPassword) {
      alert("Please enter a new password");
      return;
    }

    if (passwordData.newPassword.length < 6) {
      alert("New password must be at least 6 characters long");
      return;
    }

    if (passwordData.newPassword !== passwordData.confirmPassword) {
      alert("New password and confirm password do not match");
      return;
    }

    if (passwordData.currentPassword === passwordData.newPassword) {
      alert("New password must be different from current password");
      return;
    }

    setPasswordLoading(true);

    try {
      const userData = localStorage.getItem("user");
      if (!userData) {
        alert("User data not found");
        return;
      }

      const parsedUser = JSON.parse(userData);
      const userId = parsedUser.user_id;

      const token = localStorage.getItem("token");
      if (!token) {
        alert("Authentication token not found");
        return;
      }

      const response = await fetch(apiUrl(`api/users/${userId}/password`), {
        method: "PUT",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          currentPassword: passwordData.currentPassword,
          newPassword: passwordData.newPassword,
        }),
      });

      if (!response.ok) {
        const errorResult = await response.json();
        throw new Error(errorResult.error || "Failed to update password");
      }

      const result = await response.json();

      if (result.success) {
        // Clear password fields
        setPasswordData({
          currentPassword: "",
          newPassword: "",
          confirmPassword: "",
        });

        setShowPopup(true);
        setTimeout(() => setShowPopup(false), 3000);
        alert("Password updated successfully!");
      }
    } catch (err) {
      console.error("Error updating password:", err);
      const errorMessage =
        err instanceof Error ? err.message : "Failed to update password";
      alert(errorMessage);
    } finally {
      setPasswordLoading(false);
    }
  };

  if (loading)
    return (
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <div className="flex-1 lg:ml-64">
          <div className="flex items-center justify-center h-full">
            <div className="text-center">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900 mx-auto"></div>
              <p className="mt-2 text-gray-600">Loading your settings...</p>
            </div>
          </div>
        </div>
      </div>
    );

  if (error)
    return (
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <div className="flex-1 lg:ml-64">
          <div className="flex items-center justify-center h-full">
            <div className="text-center max-w-md">
              <div className="text-red-500 mb-4">
                <Shield className="h-16 w-16 mx-auto" />
              </div>
              <h2 className="text-xl font-semibold text-gray-900 mb-2">
                Authentication Required
              </h2>
              <p className="text-gray-600 mb-4">
                {error.includes("User not found")
                  ? "Your account could not be found. Please log in again."
                  : error}
              </p>
              <Button
                onClick={() => (window.location.href = "/login")}
                className="bg-blue-600 hover:bg-blue-700"
              >
                Go to Login
              </Button>
            </div>
          </div>
        </div>
      </div>
    );

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />
      <div className="flex-1 lg:ml-64">
        <div className="p-6 lg:p-8">
          <div className="mb-8">
            <h1 className="text-3xl font-bold text-gray-900">Settings</h1>
            <p className="text-gray-600 mt-2">
              Manage your organizer account settings and preferences
            </p>
          </div>

          {showPopup && (
            <div className="fixed top-4 right-4 z-50 flex items-center bg-white text-gray-800 px-4 py-3 rounded-lg shadow-xl border-l-4 border-green-500 transition-all duration-300 transform animate-slide-in">
              <svg
                className="h-6 w-6 text-green-500 mr-3"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="2"
                  d="M5 13l4 4L19 7"
                />
              </svg>
              <div>
                <p className="font-semibold text-sm">Success</p>
                <p className="text-sm">Profile saved successfully!</p>
              </div>
            </div>
          )}

          <style jsx>{`
            @keyframes slide-in {
              0% {
                transform: translateY(-20px);
                opacity: 0;
              }
              100% {
                transform: translateY(0);
                opacity: 1;
              }
            }
            .animate-slide-in {
              animation: slide-in 0.3s ease-out;
            }
          `}</style>

          <Tabs defaultValue="profile" className="space-y-6">
            <TabsList className="inline-flex rounded-lg bg-gray-100 p-1.5">
              <TabsTrigger
                value="profile"
                className="px-4 py-2 text-sm font-medium text-gray-600 rounded-md border border-gray-300 transition-all duration-200 data-[state=active]:bg-white data-[state=active]:text-gray-900 data-[state=active]:border-blue-500 data-[state=active]:shadow-sm hover:bg-gray-200 hover:border-gray-400"
              >
                Profile
              </TabsTrigger>
              <TabsTrigger
                value="organization"
                className="px-4 py-2 text-sm font-medium text-gray-600 rounded-md border border-gray-300 transition-all duration-200 data-[state=active]:bg-white data-[state=active]:text-gray-900 data-[state=active]:border-blue-500 data-[state=active]:shadow-sm hover:bg-gray-200 hover:border-gray-400"
              >
                Organization
              </TabsTrigger>
              <TabsTrigger
                value="security"
                className="px-4 py-2 text-sm font-medium text-gray-600 rounded-md border border-gray-300 transition-all duration-200 data-[state=active]:bg-white data-[state=active]:text-gray-900 data-[state=active]:border-blue-500 data-[state=active]:shadow-sm hover:bg-gray-200 hover:border-gray-400"
              >
                Security
              </TabsTrigger>
            </TabsList>

            <TabsContent value="profile">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center">
                    <User className="h-5 w-5 mr-2" />
                    Profile Information
                  </CardTitle>
                  <CardDescription>
                    Update your personal information and profile details
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-6">
                  <div className="flex items-center space-x-4">
                    <Avatar className="h-16 w-16">
                      <AvatarImage
                        src={profileData.avatar}
                        alt={profileData.name}
                      />
                      <AvatarFallback className="text-base">
                        {profileData.name
                          .split(" ")
                          .map((n) => n[0])
                          .join("")}
                      </AvatarFallback>
                    </Avatar>
                    <div>
                      <Button
                        onClick={() => fileInputRef.current?.click()}
                        variant="outline"
                        size="sm"
                      >
                        <Camera className="h-4 w-4 mr-2" /> Change Photo
                      </Button>
                      <input
                        type="file"
                        ref={fileInputRef}
                        className="hidden"
                        accept="image/*"
                        onChange={handleFileChange}
                      />
                      <p className="text-xs text-gray-500 mt-1">
                        JPG, GIF or PNG. 500KB max.
                      </p>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="space-y-2">
                      <Label htmlFor="name">Full Name</Label>
                      <Input
                        id="name"
                        value={profileData.name}
                        onChange={(e) =>
                          setProfileData({
                            ...profileData,
                            name: e.target.value,
                          })
                        }
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="email">Email Address</Label>
                      <Input
                        id="email"
                        type="email"
                        value={profileData.email}
                        onChange={(e) =>
                          setProfileData({
                            ...profileData,
                            email: e.target.value,
                          })
                        }
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="phone">Phone Number</Label>
                      <Input
                        id="phone"
                        value={profileData.phone}
                        onChange={(e) =>
                          setProfileData({
                            ...profileData,
                            phone: e.target.value,
                          })
                        }
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="role">Role</Label>
                      <Input
                        id="role"
                        value="Event Organizer"
                        disabled
                        className="bg-gray-50"
                      />
                    </div>
                  </div>

                  <div className="flex justify-end">
                    <Button onClick={handleProfileSave}>Save Changes</Button>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="organization">
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center">
                    <Building2 className="h-5 w-5 mr-2" />
                    Organization Details
                  </CardTitle>
                  <CardDescription>
                    Manage your organization information and preferences
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-6">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="space-y-2">
                      <Label htmlFor="org-name">Organization Name</Label>
                      <Input
                        id="org-name"
                        placeholder="Enter your organization name"
                        value={organizationData.name}
                        onChange={(e) =>
                          setOrganizationData({
                            ...organizationData,
                            name: e.target.value,
                          })
                        }
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="org-contact-email">Contact Email</Label>
                      <Input
                        id="org-contact-email"
                        type="email"
                        placeholder="contact@yourorganization.com"
                        value={organizationData.contact_email}
                        onChange={(e) =>
                          setOrganizationData({
                            ...organizationData,
                            contact_email: e.target.value,
                          })
                        }
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="org-contact-number">Contact Number</Label>
                      <Input
                        id="org-contact-number"
                        type="tel"
                        placeholder="+1 (555) 123-4567"
                        value={organizationData.contact_number}
                        onChange={(e) =>
                          setOrganizationData({
                            ...organizationData,
                            contact_number: e.target.value,
                          })
                        }
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="org-website">Website</Label>
                      <Input
                        id="org-website"
                        type="url"
                        placeholder="https://yourorganization.com"
                        value={organizationData.website_url}
                        onChange={(e) =>
                          setOrganizationData({
                            ...organizationData,
                            website_url: e.target.value,
                          })
                        }
                      />
                    </div>
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="org-description">
                      Organization Description
                    </Label>
                    <textarea
                      id="org-description"
                      rows={4}
                      className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                      placeholder="Describe your organization and the types of events you organize..."
                      value={organizationData.description}
                      onChange={(e) =>
                        setOrganizationData({
                          ...organizationData,
                          description: e.target.value,
                        })
                      }
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="org-logo">Organization Logo</Label>
                    <div className="flex items-center space-x-4">
                      <Avatar className="h-16 w-16">
                        <AvatarImage
                          src={
                            organizationData.logo_url ||
                            "/placeholder.svg?height=64&width=64"
                          }
                          alt="Organization Logo"
                        />
                        <AvatarFallback>
                          <Building2 className="h-8 w-8" />
                        </AvatarFallback>
                      </Avatar>
                      <div>
                        <input
                          type="file"
                          id="org-logo"
                          accept="image/*"
                          onChange={(e) =>
                            setOrganizationLogo(e.target.files?.[0] || null)
                          }
                          className="hidden"
                        />
                        <Button
                          type="button"
                          variant="outline"
                          onClick={() =>
                            document.getElementById("org-logo")?.click()
                          }
                        >
                          <Camera className="h-4 w-4 mr-2" />
                          Upload Logo
                        </Button>
                        {organizationLogo && (
                          <p className="text-sm text-gray-600 mt-1">
                            Selected: {organizationLogo.name}
                          </p>
                        )}
                      </div>
                    </div>
                  </div>

                  <div className="flex justify-end">
                    <Button onClick={handleOrganizationSave}>
                      Save Organization Details
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="security">
              <div className="space-y-6">
                <Card>
                  <CardHeader>
                    <CardTitle className="flex items-center">
                      <Shield className="h-5 w-5 mr-2" />
                      Password & Security
                    </CardTitle>
                    <CardDescription>
                      Manage your password and security settings
                    </CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div className="space-y-2">
                      <Label htmlFor="current-password">Current Password</Label>
                      <Input
                        id="current-password"
                        type="password"
                        value={passwordData.currentPassword}
                        onChange={(e) =>
                          setPasswordData({
                            ...passwordData,
                            currentPassword: e.target.value,
                          })
                        }
                        placeholder="Enter your current password"
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="new-password">New Password</Label>
                      <Input
                        id="new-password"
                        type="password"
                        value={passwordData.newPassword}
                        onChange={(e) =>
                          setPasswordData({
                            ...passwordData,
                            newPassword: e.target.value,
                          })
                        }
                        placeholder="Enter your new password (min 6 characters)"
                      />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="confirm-password">
                        Confirm New Password
                      </Label>
                      <Input
                        id="confirm-password"
                        type="password"
                        value={passwordData.confirmPassword}
                        onChange={(e) =>
                          setPasswordData({
                            ...passwordData,
                            confirmPassword: e.target.value,
                          })
                        }
                        placeholder="Confirm your new password"
                      />
                    </div>
                    <Button
                      onClick={handlePasswordUpdate}
                      disabled={passwordLoading}
                    >
                      {passwordLoading ? "Updating..." : "Update Password"}
                    </Button>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader>
                    <CardTitle>Two-Factor Authentication</CardTitle>
                    <CardDescription>
                      Add an extra layer of security to your organizer account
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="font-medium">Two-factor authentication</p>
                        <p className="text-sm text-gray-600">
                          Secure your organizer account with 2FA
                        </p>
                      </div>
                      <Button variant="outline">Enable 2FA</Button>
                    </div>
                  </CardContent>
                </Card>
              </div>
            </TabsContent>
          </Tabs>
        </div>
      </div>
    </div>
  );
}
