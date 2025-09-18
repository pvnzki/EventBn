"use client";

import { useState, useEffect, useRef } from "react";
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
import { Shield, Camera, User } from "lucide-react";

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

export default function SettingsPage() {
  const [user, setUser] = useState<UserType | null>(null);
  const [profileData, setProfileData] = useState({
    name: "",
    email: "",
    phone: "",
    avatar: "/placeholder.svg?height=100&width=100",
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showPopup, setShowPopup] = useState(false);
  const fileInputRef = useRef<HTMLInputElement | null>(null);

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

        const response = await fetch(
          `http://localhost:3000/api/users/${userId}`
        );
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
        } else throw new Error("Invalid API response");
      } catch (err) {
        setError(
          err instanceof Error ? err.message : "Error fetching user data"
        );
      } finally {
        setLoading(false);
      }
    };

    fetchUserData();
  }, []);

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    if (file.size > 500 * 1024) {
      alert("File size must be less than 500KB");
      return;
    }

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

      const response = await fetch(
        `http://localhost:3000/api/users/${userId}`,
        {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            name: profileData.name,
            email: profileData.email,
            phone_number: profileData.phone,
            profile_picture: profileData.avatar,
          }),
        }
      );

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

        localStorage.setItem("user", JSON.stringify(result.data));

        setShowPopup(true);
        setTimeout(() => setShowPopup(false), 3000);
      }
    } catch (err) {
      console.error("Error saving profile:", err);
    }
  };

  if (loading)
    return <div className="flex min-h-screen bg-gray-50">Loading...</div>;
  if (error)
    return <div className="flex min-h-screen bg-gray-50">Error: {error}</div>;

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />
      <div className="flex-1 lg:ml-64">
        <div className="p-6 lg:p-8">
          <div className="mb-8">
            <h1 className="text-3xl font-bold text-gray-900">Settings</h1>
            <p className="text-gray-600 mt-2">
              Manage your account settings and preferences
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
                  </div>

                  <div className="flex justify-end">
                    <Button onClick={handleProfileSave}>Save Changes</Button>
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
                      <Input id="current-password" type="password" />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="new-password">New Password</Label>
                      <Input id="new-password" type="password" />
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="confirm-password">
                        Confirm New Password
                      </Label>
                      <Input id="confirm-password" type="password" />
                    </div>
                    <Button>Update Password</Button>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader>
                    <CardTitle>Two-Factor Authentication</CardTitle>
                    <CardDescription>
                      Add an extra layer of security to your account
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="font-medium">Two-factor authentication</p>
                        <p className="text-sm text-gray-600">
                          Secure your account with 2FA
                        </p>
                      </div>
                      <Button variant="outline">Enable 2FA</Button>
                    </div>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader>
                    <CardTitle>Account Actions</CardTitle>
                    <CardDescription>
                      Manage your account status
                    </CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="font-medium">Export Data</p>
                        <p className="text-sm text-gray-600">
                          Download a copy of your account data
                        </p>
                      </div>
                      <Button variant="outline">Export</Button>
                    </div>
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="font-medium text-red-600">
                          Delete Account
                        </p>
                        <p className="text-sm text-gray-600">
                          Permanently delete your account and all data
                        </p>
                      </div>
                      <Button variant="destructive">Delete</Button>
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
