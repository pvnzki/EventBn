"use client";
import { useRouter, useSearchParams } from "next/navigation";
import { useEffect, useState } from "react";
import { apiUrl } from "@/lib/api";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Select,
  SelectTrigger,
  SelectContent,
  SelectItem,
  SelectValue,
} from "@/components/ui/select";
import { useToast } from "@/components/ui/use-toast";
import { Sidebar } from "@/components/layout/sidebar";
import {
  Calendar,
  MapPin,
  Users,
  Image as ImageIcon,
  Video,
  FileText,
  Save,
  X,
  ArrowLeft,
  Plus,
  Trash2,
  DollarSign,
  Loader2,
} from "lucide-react";
import { Badge } from "@/components/ui/badge";
import SeatingArrangementSection from "@/components/seating/SeatingArrangementSection";

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
  booked?: boolean;
  ticketType: string;
}

type Event = {
  event_id: number;
  title: string;
  description: string;
  category: string;
  venue: string;
  location: string;
  start_time: string;
  end_time: string;
  capacity: number;
  cover_image_url: string;
  other_images_url: string;
  video_url: string;
  status: string;
  organization_id: number | null;
  seat_map: any;
  ticket_types: any;
};

const EditEventPage = () => {
  const router = useRouter();
  const searchParams = useSearchParams();
  const eventId = searchParams ? searchParams.get("id") : null;
  const { toast } = useToast();

  const [form, setForm] = useState<Partial<Event>>({});
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [jsonError, setJsonError] = useState<{
    seat_map?: string;
    ticket_types?: string;
  }>({});

  // File upload states
  const [coverImageFile, setCoverImageFile] = useState<File | null>(null);
  const [coverImagePreview, setCoverImagePreview] = useState<string>("");
  const [additionalImages, setAdditionalImages] = useState<File[]>([]);
  const [additionalImagePreviews, setAdditionalImagePreviews] = useState<
    string[]
  >([]);
  const [videoFile, setVideoFile] = useState<File | null>(null);
  const [videoPreview, setVideoPreview] = useState<string>("");

  // Upload loading states
  const [uploadingCover, setUploadingCover] = useState(false);
  const [uploadingImages, setUploadingImages] = useState(false);
  const [uploadingVideo, setUploadingVideo] = useState(false);

  // Ticket types and seat map states
  const [ticketTypes, setTicketTypes] = useState<TicketType[]>([]);
  const [newTicket, setNewTicket] = useState({
    name: "",
    price: "",
    quantity: "",
    description: "",
  });
  const [seatMap, setSeatMap] = useState<Seat[] | null>(null);

  useEffect(() => {
    if (eventId) {
      console.log("Loading event with ID:", eventId);
      // Get token from localStorage
      const token = localStorage.getItem("token");
      const headers: HeadersInit = {};
      if (token) {
        headers["Authorization"] = `Bearer ${token}`;
      }

      fetch(apiUrl(`api/events/${eventId}`), { headers })
        .then((res) => {
          console.log("Fetch event response status:", res.status);
          if (!res.ok) {
            throw new Error(
              `Failed to fetch event: ${res.status} ${res.statusText}`
            );
          }
          return res.json();
        })
        .then((data) => {
          if (!data.data) {
            throw new Error("Event not found");
          }
          setForm({
            ...data.data,
            start_time: data.data.start_time?.slice(0, 16),
            end_time: data.data.end_time?.slice(0, 16),
            seat_map: data.data.seat_map
              ? JSON.stringify(data.data.seat_map, null, 2)
              : "",
            ticket_types: data.data.ticket_types
              ? JSON.stringify(data.data.ticket_types, null, 2)
              : "",
          });

          // Parse and set ticket types
          if (data.data.ticket_types) {
            try {
              const types = Array.isArray(data.data.ticket_types)
                ? data.data.ticket_types
                : JSON.parse(data.data.ticket_types);

              // Convert to the format expected by the component
              const formattedTypes = types.map((type: any, index: number) => ({
                id:
                  type.id || type.ticket_type_id?.toString() || `${index + 1}`,
                name: type.name || type.ticket_name || `Ticket ${index + 1}`,
                price: Number(type.price) || 0,
                quantity: Number(type.quantity) || 0,
                description: type.description || "",
              }));
              setTicketTypes(formattedTypes);
            } catch (e) {
              console.error("Error parsing ticket_types:", e);
            }
          }

          // Parse and set seat map
          if (data.data.seat_map) {
            try {
              const seats = Array.isArray(data.data.seat_map)
                ? data.data.seat_map
                : JSON.parse(data.data.seat_map);
              setSeatMap(seats);
            } catch (e) {
              console.error("Error parsing seat_map:", e);
            }
          }

          // Load existing images as previews
          if (data.data.cover_image_url) {
            setCoverImagePreview(data.data.cover_image_url);
          }
          if (data.data.other_images_url) {
            try {
              const urls =
                typeof data.data.other_images_url === "string"
                  ? JSON.parse(data.data.other_images_url)
                  : data.data.other_images_url;
              if (Array.isArray(urls)) {
                setAdditionalImagePreviews(urls);
              }
            } catch (e) {
              console.error("Error parsing other_images_url:", e);
            }
          }
          if (data.data.video_url) {
            setVideoPreview(data.data.video_url);
          }

          setLoading(false);
        })
        .catch((err) => {
          console.error("Error loading event:", err);
          setLoading(false);
          toast({
            title: "Error",
            description:
              err.message || "Failed to load event. The event may not exist.",
            variant: "destructive",
          });
        });
    }
  }, [eventId]);

  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
  };

  const handleSelect = (name: string, value: string) => {
    setForm((prev) => ({ ...prev, [name]: value }));
  };

  const handleJsonChange = (
    name: "seat_map" | "ticket_types",
    value: string
  ) => {
    setForm((prev) => ({ ...prev, [name]: value }));
    setJsonError((prev) => ({ ...prev, [name]: undefined }));
    try {
      if (value.trim()) JSON.parse(value);
    } catch (e) {
      setJsonError((prev) => ({ ...prev, [name]: "Invalid JSON" }));
    }
  };

  // File handling functions
  const handleCoverImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setUploadingCover(true);
      setCoverImageFile(file);
      const reader = new FileReader();
      reader.onloadend = () => {
        setCoverImagePreview(reader.result as string);
        setUploadingCover(false);
        toast({
          title: "Cover image uploaded",
          description: "Your cover image has been successfully uploaded.",
        });
      };
      reader.onerror = () => {
        setUploadingCover(false);
        toast({
          title: "Upload failed",
          description: "Failed to upload cover image. Please try again.",
          variant: "destructive",
        });
      };
      reader.readAsDataURL(file);
    }
  };

  const removeCoverImage = () => {
    setCoverImageFile(null);
    setCoverImagePreview("");
    setForm((prev) => ({ ...prev, cover_image_url: "" }));
  };

  const handleAdditionalImagesChange = (
    e: React.ChangeEvent<HTMLInputElement>
  ) => {
    const files = Array.from(e.target.files || []);
    if (files.length > 0) {
      setUploadingImages(true);
      setAdditionalImages((prev) => [...prev, ...files]);

      let loadedCount = 0;
      files.forEach((file) => {
        const reader = new FileReader();
        reader.onloadend = () => {
          setAdditionalImagePreviews((prev) => [
            ...prev,
            reader.result as string,
          ]);
          loadedCount++;
          if (loadedCount === files.length) {
            setUploadingImages(false);
            toast({
              title: "Images uploaded",
              description: `Successfully uploaded ${files.length} image(s).`,
            });
          }
        };
        reader.onerror = () => {
          loadedCount++;
          if (loadedCount === files.length) {
            setUploadingImages(false);
          }
          toast({
            title: "Upload failed",
            description: "Failed to upload some images. Please try again.",
            variant: "destructive",
          });
        };
        reader.readAsDataURL(file);
      });
    }
  };

  const removeAdditionalImage = (index: number) => {
    setAdditionalImages((prev) => prev.filter((_, i) => i !== index));
    setAdditionalImagePreviews((prev) => prev.filter((_, i) => i !== index));
  };

  const handleVideoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setUploadingVideo(true);
      setVideoFile(file);
      const reader = new FileReader();
      reader.onloadend = () => {
        setVideoPreview(reader.result as string);
        setUploadingVideo(false);
        toast({
          title: "Video uploaded",
          description: "Your video has been successfully uploaded.",
        });
      };
      reader.onerror = () => {
        setUploadingVideo(false);
        toast({
          title: "Upload failed",
          description: "Failed to upload video. Please try again.",
          variant: "destructive",
        });
      };
      reader.readAsDataURL(file);
    }
  };

  const removeVideo = () => {
    setVideoFile(null);
    setVideoPreview("");
    setForm((prev) => ({ ...prev, video_url: "" }));
  };

  // Ticket type management functions
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

  const handleSeatMapGenerate = (generatedSeatMap: Seat[]) => {
    setSeatMap(generatedSeatMap);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setJsonError({});

    try {
      console.log("Updating event with ID:", eventId);

      // Get token from localStorage
      const token = localStorage.getItem("token");
      if (!token) {
        toast({
          title: "Error",
          description: "You must be logged in to update an event",
          variant: "destructive",
        });
        setSubmitting(false);
        return;
      }

      // Use FormData to send files to backend for Cloudinary upload
      const formData = new FormData();

      // Add basic event data (with fallbacks for undefined values)
      formData.append("title", form.title || "");
      formData.append("description", form.description || "");
      formData.append("category", form.category || "");
      formData.append("venue", form.venue || "");
      formData.append("location", form.location || "");
      formData.append("start_time", form.start_time || "");
      formData.append("end_time", form.end_time || "");
      formData.append("capacity", form.capacity ? String(form.capacity) : "0");
      formData.append("status", form.status || "ACTIVE");

      if (form.organization_id) {
        formData.append("organization_id", String(form.organization_id));
      }

      // Add seat_map and ticket_types as JSON strings
      formData.append("seat_map", JSON.stringify(seatMap));
      formData.append("ticket_types", JSON.stringify(ticketTypes));

      // Add cover image file if new one was uploaded
      if (coverImageFile) {
        formData.append("cover_image", coverImageFile);
      } else if (
        form.cover_image_url &&
        !coverImagePreview.startsWith("data:")
      ) {
        // Keep existing Cloudinary URL
        formData.append("cover_image_url", form.cover_image_url);
      }

      // Add other images files if new ones were uploaded
      if (additionalImages.length > 0) {
        additionalImages.forEach((image) => {
          formData.append("other_images", image);
        });
      } else if (form.other_images_url) {
        // Keep existing URLs
        formData.append("other_images_url", form.other_images_url);
      }

      // Add video file if new one was uploaded
      if (videoFile) {
        formData.append("video", videoFile);
      } else if (form.video_url && !videoPreview.startsWith("data:")) {
        // Keep existing Cloudinary URL
        formData.append("video_url", form.video_url);
      }

      const res = await fetch(apiUrl(`api/events/${eventId}`), {
        method: "PUT",
        headers: {
          Authorization: `Bearer ${token}`,
          // Don't set Content-Type - let browser set it with boundary for FormData
        },
        body: formData,
      });
      if (res.ok) {
        toast({ title: "Success", description: "Event updated successfully!" });
        router.push("/organizer/dashboard");
      } else {
        const errorData = await res
          .json()
          .catch(() => ({ message: res.statusText }));
        console.error("Failed to update event:", res.status, errorData);
        toast({
          title: "Error",
          description:
            errorData.message || `Failed to update event (${res.status})`,
          variant: "destructive",
        });
      }
    } catch (error) {
      console.error("Exception during update:", error);
      toast({
        title: "Error",
        description: "Network error.",
        variant: "destructive",
      });
    }
    setSubmitting(false);
  };

  if (loading)
    return (
      <div className="flex min-h-screen bg-gray-50">
        <Sidebar />
        <main className="flex-1 p-8 lg:ml-64">
          <div className="flex items-center justify-center h-full">
            <div className="text-lg">Loading event...</div>
          </div>
        </main>
      </div>
    );

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />
      <main className="flex-1 p-6 lg:ml-64 overflow-auto">
        <div className="max-w-5xl">
          {/* Header */}
          <div className="mb-6">
            <Button
              variant="ghost"
              onClick={() => router.back()}
              className="mb-3"
            >
              <ArrowLeft className="h-4 w-4 mr-2" />
              Back
            </Button>
            <h1 className="text-3xl font-bold text-gray-900">Edit Event</h1>
            <p className="text-gray-500 text-sm mt-1">
              Update your event details
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Basic Information */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center text-lg">
                  <FileText className="h-5 w-5 mr-2" />
                  Basic Information
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <Label htmlFor="title">Event Title *</Label>
                    <Input
                      name="title"
                      id="title"
                      value={form.title || ""}
                      onChange={handleChange}
                      required
                      placeholder="Enter event title"
                      className="mt-1"
                    />
                  </div>
                  <div>
                    <Label htmlFor="category">Category</Label>
                    <Input
                      name="category"
                      id="category"
                      value={form.category || ""}
                      onChange={handleChange}
                      placeholder="e.g., Music, Sports, Conference"
                      className="mt-1"
                    />
                  </div>
                </div>

                <div>
                  <Label htmlFor="description">Description</Label>
                  <Textarea
                    name="description"
                    id="description"
                    value={form.description || ""}
                    onChange={handleChange}
                    rows={4}
                    placeholder="Describe your event..."
                    className="mt-1"
                  />
                </div>
              </CardContent>
            </Card>

            {/* Location & Venue */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center text-lg">
                  <MapPin className="h-5 w-5 mr-2" />
                  Location & Venue
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <Label htmlFor="venue">Venue Name</Label>
                    <Input
                      name="venue"
                      id="venue"
                      value={form.venue || ""}
                      onChange={handleChange}
                      placeholder="e.g., Madison Square Garden"
                      className="mt-1"
                    />
                  </div>
                  <div>
                    <Label htmlFor="location">Address</Label>
                    <Input
                      name="location"
                      id="location"
                      value={form.location || ""}
                      onChange={handleChange}
                      placeholder="Full address"
                      className="mt-1"
                    />
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Date & Time */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center text-lg">
                  <Calendar className="h-5 w-5 mr-2" />
                  Date & Time
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div>
                    <Label htmlFor="start_time">Start Date & Time *</Label>
                    <Input
                      name="start_time"
                      id="start_time"
                      type="datetime-local"
                      value={form.start_time || ""}
                      onChange={handleChange}
                      required
                      className="mt-1"
                    />
                  </div>
                  <div>
                    <Label htmlFor="end_time">End Date & Time *</Label>
                    <Input
                      name="end_time"
                      id="end_time"
                      type="datetime-local"
                      value={form.end_time || ""}
                      onChange={handleChange}
                      required
                      className="mt-1"
                    />
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Capacity */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center text-lg">
                  <Users className="h-5 w-5 mr-2" />
                  Capacity
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="max-w-xs">
                  <Label htmlFor="capacity">Maximum Attendees</Label>
                  <Input
                    name="capacity"
                    id="capacity"
                    type="number"
                    min={0}
                    value={form.capacity || ""}
                    onChange={handleChange}
                    placeholder="e.g., 500"
                    className="mt-1"
                  />
                </div>
              </CardContent>
            </Card>

            {/* Media */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center text-lg">
                  <ImageIcon className="h-5 w-5 mr-2" />
                  Media
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-6">
                {/* Cover Image */}
                <div>
                  <Label htmlFor="cover_image">Cover Image</Label>
                  <div className="mt-2">
                    {uploadingCover ? (
                      <div className="flex flex-col items-center justify-center w-full h-48 border-2 border-blue-300 border-dashed rounded-lg bg-blue-50">
                        <Loader2 className="w-10 h-10 mb-3 text-blue-500 animate-spin" />
                        <p className="text-sm text-blue-600 font-medium">
                          Uploading cover image...
                        </p>
                      </div>
                    ) : coverImagePreview ? (
                      <div className="space-y-3">
                        <div className="relative h-48 w-full rounded-lg overflow-hidden bg-gray-100 border">
                          <img
                            src={coverImagePreview}
                            alt="Cover preview"
                            className="w-full h-full object-cover"
                          />
                          <button
                            type="button"
                            onClick={removeCoverImage}
                            className="absolute top-2 right-2 bg-red-500 hover:bg-red-600 text-white p-2 rounded-full shadow-lg transition-colors"
                          >
                            <X className="h-4 w-4" />
                          </button>
                        </div>
                        <p className="text-xs text-gray-500">
                          Click the X button to remove and upload a new image
                        </p>
                      </div>
                    ) : (
                      <div className="flex items-center justify-center w-full">
                        <label
                          htmlFor="cover_image"
                          className="flex flex-col items-center justify-center w-full h-48 border-2 border-gray-300 border-dashed rounded-lg cursor-pointer bg-gray-50 hover:bg-gray-100 transition-colors"
                        >
                          <div className="flex flex-col items-center justify-center pt-5 pb-6">
                            <ImageIcon className="w-10 h-10 mb-3 text-gray-400" />
                            <p className="mb-2 text-sm text-gray-500">
                              <span className="font-semibold">
                                Click to upload
                              </span>{" "}
                              or drag and drop
                            </p>
                            <p className="text-xs text-gray-500">
                              PNG, JPG or WEBP (MAX. 5MB)
                            </p>
                          </div>
                          <input
                            id="cover_image"
                            type="file"
                            className="hidden"
                            accept="image/*"
                            onChange={handleCoverImageChange}
                          />
                        </label>
                      </div>
                    )}
                  </div>
                </div>

                {/* Additional Images */}
                <div>
                  <Label htmlFor="additional_images">Additional Images</Label>
                  <div className="mt-2 space-y-3">
                    {uploadingImages && (
                      <div className="flex items-center justify-center w-full h-24 border-2 border-blue-300 border-dashed rounded-lg bg-blue-50">
                        <Loader2 className="w-6 h-6 mr-2 text-blue-500 animate-spin" />
                        <p className="text-sm text-blue-600 font-medium">
                          Uploading images...
                        </p>
                      </div>
                    )}
                    {additionalImagePreviews.length > 0 && (
                      <div className="grid grid-cols-3 gap-3">
                        {additionalImagePreviews.map((preview, idx) => (
                          <div
                            key={idx}
                            className="relative h-24 rounded-lg overflow-hidden bg-gray-100 border group"
                          >
                            <img
                              src={preview}
                              alt={`Additional ${idx + 1}`}
                              className="w-full h-full object-cover"
                            />
                            <button
                              type="button"
                              onClick={() => removeAdditionalImage(idx)}
                              className="absolute top-1 right-1 bg-red-500 hover:bg-red-600 text-white p-1.5 rounded-full shadow-lg transition-all opacity-0 group-hover:opacity-100"
                            >
                              <X className="h-3 w-3" />
                            </button>
                          </div>
                        ))}
                      </div>
                    )}
                    <div className="flex items-center justify-center w-full">
                      <label
                        htmlFor="additional_images"
                        className="flex flex-col items-center justify-center w-full h-32 border-2 border-gray-300 border-dashed rounded-lg cursor-pointer bg-gray-50 hover:bg-gray-100 transition-colors"
                      >
                        <div className="flex flex-col items-center justify-center pt-5 pb-6">
                          <ImageIcon className="w-8 h-8 mb-2 text-gray-400" />
                          <p className="text-sm text-gray-500">
                            <span className="font-semibold">
                              Add more images
                            </span>
                          </p>
                          <p className="text-xs text-gray-500">
                            Multiple files allowed
                          </p>
                        </div>
                        <input
                          id="additional_images"
                          type="file"
                          className="hidden"
                          accept="image/*"
                          multiple
                          onChange={handleAdditionalImagesChange}
                        />
                      </label>
                    </div>
                  </div>
                </div>

                {/* Video */}
                <div>
                  <Label htmlFor="video">Event Video</Label>
                  <div className="mt-2">
                    {uploadingVideo ? (
                      <div className="flex flex-col items-center justify-center w-full h-48 border-2 border-blue-300 border-dashed rounded-lg bg-blue-50">
                        <Loader2 className="w-10 h-10 mb-3 text-blue-500 animate-spin" />
                        <p className="text-sm text-blue-600 font-medium">
                          Uploading video...
                        </p>
                        <p className="text-xs text-blue-500 mt-1">
                          This may take a moment
                        </p>
                      </div>
                    ) : videoPreview ? (
                      <div className="space-y-3">
                        <div className="relative h-48 w-full rounded-lg overflow-hidden bg-gray-100 border">
                          <video
                            src={videoPreview}
                            controls
                            className="w-full h-full object-cover"
                          />
                          <button
                            type="button"
                            onClick={removeVideo}
                            className="absolute top-2 right-2 bg-red-500 hover:bg-red-600 text-white p-2 rounded-full shadow-lg transition-colors"
                          >
                            <X className="h-4 w-4" />
                          </button>
                        </div>
                        <p className="text-xs text-gray-500">
                          Click the X button to remove and upload a new video
                        </p>
                      </div>
                    ) : (
                      <div className="flex items-center justify-center w-full">
                        <label
                          htmlFor="video"
                          className="flex flex-col items-center justify-center w-full h-48 border-2 border-gray-300 border-dashed rounded-lg cursor-pointer bg-gray-50 hover:bg-gray-100 transition-colors"
                        >
                          <div className="flex flex-col items-center justify-center pt-5 pb-6">
                            <Video className="w-10 h-10 mb-3 text-gray-400" />
                            <p className="mb-2 text-sm text-gray-500">
                              <span className="font-semibold">
                                Click to upload video
                              </span>{" "}
                              or drag and drop
                            </p>
                            <p className="text-xs text-gray-500">
                              MP4, WEBM or OGG (MAX. 50MB)
                            </p>
                          </div>
                          <input
                            id="video"
                            type="file"
                            className="hidden"
                            accept="video/*"
                            onChange={handleVideoChange}
                          />
                        </label>
                      </div>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Ticket Types */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center text-lg">
                  <DollarSign className="h-5 w-5 mr-2" />
                  Ticket Types
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                {/* Existing Ticket Types */}
                {ticketTypes.length > 0 && (
                  <div className="space-y-2">
                    <Label>Current Ticket Types</Label>
                    <div className="grid gap-2">
                      {ticketTypes.map((ticket) => (
                        <div
                          key={ticket.id}
                          className="flex items-center justify-between p-3 bg-gray-50 rounded-lg border"
                        >
                          <div className="flex-1">
                            <div className="flex items-center gap-2">
                              <span className="font-semibold">
                                {ticket.name}
                              </span>
                              <Badge variant="secondary">
                                ${ticket.price.toFixed(2)}
                              </Badge>
                              <Badge variant="outline">
                                {ticket.quantity} tickets
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
                            <Trash2 className="h-4 w-4 text-red-500" />
                          </Button>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Add New Ticket Type */}
                <div className="space-y-3 border-t pt-4">
                  <Label className="text-base font-semibold">
                    Add New Ticket Type
                  </Label>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                    <div>
                      <Label htmlFor="ticket_name">Ticket Name *</Label>
                      <Input
                        id="ticket_name"
                        value={newTicket.name}
                        onChange={(e) =>
                          setNewTicket({ ...newTicket, name: e.target.value })
                        }
                        placeholder="e.g., VIP, General Admission"
                        className="mt-1"
                      />
                    </div>
                    <div>
                      <Label htmlFor="ticket_price">Price ($) *</Label>
                      <Input
                        id="ticket_price"
                        type="number"
                        step="0.01"
                        min="0"
                        value={newTicket.price}
                        onChange={(e) =>
                          setNewTicket({ ...newTicket, price: e.target.value })
                        }
                        placeholder="0.00"
                        className="mt-1"
                      />
                    </div>
                    <div>
                      <Label htmlFor="ticket_quantity">Quantity *</Label>
                      <Input
                        id="ticket_quantity"
                        type="number"
                        min="1"
                        value={newTicket.quantity}
                        onChange={(e) =>
                          setNewTicket({
                            ...newTicket,
                            quantity: e.target.value,
                          })
                        }
                        placeholder="100"
                        className="mt-1"
                      />
                    </div>
                    <div>
                      <Label htmlFor="ticket_description">Description</Label>
                      <Input
                        id="ticket_description"
                        value={newTicket.description}
                        onChange={(e) =>
                          setNewTicket({
                            ...newTicket,
                            description: e.target.value,
                          })
                        }
                        placeholder="Optional description"
                        className="mt-1"
                      />
                    </div>
                  </div>
                  <Button
                    type="button"
                    onClick={addTicketType}
                    disabled={
                      !newTicket.name || !newTicket.price || !newTicket.quantity
                    }
                    className="w-full"
                  >
                    <Plus className="h-4 w-4 mr-2" />
                    Add Ticket Type
                  </Button>
                </div>
              </CardContent>
            </Card>

            {/* Seating Arrangement */}
            {ticketTypes.length > 0 && (
              <SeatingArrangementSection
                ticketTypes={ticketTypes}
                existingSeatMap={seatMap || undefined}
                onGenerate={handleSeatMapGenerate}
              />
            )}

            {/* Action Buttons */}
            <div className="flex justify-between items-center pt-4">
              <Button
                type="button"
                variant="outline"
                onClick={() => router.back()}
                disabled={submitting}
                className="px-6"
              >
                <ArrowLeft className="h-4 w-4 mr-2" />
                Cancel
              </Button>
              <Button type="submit" disabled={submitting} className="px-8">
                {submitting ? (
                  <>Saving...</>
                ) : (
                  <>
                    <Save className="h-4 w-4 mr-2" />
                    Save Changes
                  </>
                )}
              </Button>
            </div>
          </form>
        </div>
      </main>
    </div>
  );
};

export default EditEventPage;
