"use client";
import { useRouter, useSearchParams } from "next/navigation";
import { useEffect, useState } from "react";
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

const statusOptions = [
  { value: "ACTIVE", label: "Active" },
  { value: "SOLD_OUT", label: "Sold Out" },
  { value: "CANCELLED", label: "Cancelled" },
];

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

  useEffect(() => {
    if (eventId) {
      fetch(`http://localhost:3000/api/events/${eventId}`)
        .then((res) => res.json())
        .then((data) => {
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
          setLoading(false);
        })
        .catch((err) => {
          setLoading(false);
          toast({
            title: "Error",
            description: "Failed to load event.",
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

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setJsonError({});
    // Validate JSON fields
    let seatMapObj = null,
      ticketTypesObj = null;
    try {
      seatMapObj =
        form.seat_map && form.seat_map.toString().trim()
          ? JSON.parse(form.seat_map as string)
          : null;
    } catch {
      setJsonError((prev) => ({ ...prev, seat_map: "Invalid JSON" }));
      setSubmitting(false);
      return;
    }
    try {
      ticketTypesObj =
        form.ticket_types && form.ticket_types.toString().trim()
          ? JSON.parse(form.ticket_types as string)
          : null;
    } catch {
      setJsonError((prev) => ({ ...prev, ticket_types: "Invalid JSON" }));
      setSubmitting(false);
      return;
    }
    // Prepare payload
    const payload = {
      ...form,
      seat_map: seatMapObj,
      ticket_types: ticketTypesObj,
      capacity: form.capacity ? Number(form.capacity) : null,
      organization_id: form.organization_id
        ? Number(form.organization_id)
        : null,
    };
    try {
      const res = await fetch(`http://localhost:3000/api/events/${eventId}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      if (res.ok) {
        toast({ title: "Success", description: "Event updated successfully!" });
        router.push("/organizer/dashboard");
      } else {
        toast({
          title: "Error",
          description: "Failed to update event.",
          variant: "destructive",
        });
      }
    } catch {
      toast({
        title: "Error",
        description: "Network error.",
        variant: "destructive",
      });
    }
    setSubmitting(false);
  };

  if (loading) return <div className="p-8 text-center text-lg">Loading...</div>;

  return (
    <div className="flex justify-center items-center min-h-screen bg-gradient-to-br from-gray-50 to-blue-100">
      <Card className="w-full max-w-2xl shadow-xl">
        <CardHeader>
          <CardTitle className="text-3xl font-bold text-blue-900">
            Edit Event
          </CardTitle>
        </CardHeader>
        <CardContent>
          <form className="space-y-5" onSubmit={handleSubmit}>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <Label htmlFor="title">Title</Label>
                <Input
                  name="title"
                  id="title"
                  value={form.title || ""}
                  onChange={handleChange}
                  required
                />
              </div>
              <div>
                <Label htmlFor="category">Category</Label>
                <Input
                  name="category"
                  id="category"
                  value={form.category || ""}
                  onChange={handleChange}
                />
              </div>
              <div>
                <Label htmlFor="venue">Venue</Label>
                <Input
                  name="venue"
                  id="venue"
                  value={form.venue || ""}
                  onChange={handleChange}
                />
              </div>
              <div>
                <Label htmlFor="location">Location</Label>
                <Input
                  name="location"
                  id="location"
                  value={form.location || ""}
                  onChange={handleChange}
                />
              </div>
              <div>
                <Label htmlFor="start_time">Start Time</Label>
                <Input
                  name="start_time"
                  id="start_time"
                  type="datetime-local"
                  value={form.start_time || ""}
                  onChange={handleChange}
                  required
                />
              </div>
              <div>
                <Label htmlFor="end_time">End Time</Label>
                <Input
                  name="end_time"
                  id="end_time"
                  type="datetime-local"
                  value={form.end_time || ""}
                  onChange={handleChange}
                  required
                />
              </div>
              <div>
                <Label htmlFor="capacity">Capacity</Label>
                <Input
                  name="capacity"
                  id="capacity"
                  type="number"
                  min={0}
                  value={form.capacity || ""}
                  onChange={handleChange}
                />
              </div>
              <div>
                <Label htmlFor="cover_image_url">Cover Image URL</Label>
                <Input
                  name="cover_image_url"
                  id="cover_image_url"
                  value={form.cover_image_url || ""}
                  onChange={handleChange}
                />
              </div>
              <div>
                <Label htmlFor="other_images_url">Other Images URL</Label>
                <Textarea
                  name="other_images_url"
                  id="other_images_url"
                  value={form.other_images_url || ""}
                  onChange={handleChange}
                />
              </div>
              <div>
                <Label htmlFor="video_url">Video URL</Label>
                <Input
                  name="video_url"
                  id="video_url"
                  value={form.video_url || ""}
                  onChange={handleChange}
                />
              </div>
              <div>
                <Label htmlFor="status">Status</Label>
                <Select
                  value={form.status || ""}
                  onValueChange={(v) => handleSelect("status", v)}
                >
                  <SelectTrigger id="status">
                    <SelectValue placeholder="Select status" />
                  </SelectTrigger>
                  <SelectContent>
                    {statusOptions.map((opt) => (
                      <SelectItem key={opt.value} value={opt.value}>
                        {opt.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
            <div>
              <Label htmlFor="description">Description</Label>
              <Textarea
                name="description"
                id="description"
                value={form.description || ""}
                onChange={handleChange}
                rows={3}
              />
            </div>
            <div>
              <Label htmlFor="seat_map">Seat Map (JSON)</Label>
              <Textarea
                name="seat_map"
                id="seat_map"
                value={form.seat_map || ""}
                onChange={(e) => handleJsonChange("seat_map", e.target.value)}
                rows={4}
                className={jsonError.seat_map ? "border-red-500" : ""}
              />
              {jsonError.seat_map && (
                <div className="text-red-500 text-xs mt-1">
                  {jsonError.seat_map}
                </div>
              )}
            </div>
            <div>
              <Label htmlFor="ticket_types">Ticket Types (JSON Array)</Label>
              <Textarea
                name="ticket_types"
                id="ticket_types"
                value={form.ticket_types || ""}
                onChange={(e) =>
                  handleJsonChange("ticket_types", e.target.value)
                }
                rows={4}
                className={jsonError.ticket_types ? "border-red-500" : ""}
              />
              {jsonError.ticket_types && (
                <div className="text-red-500 text-xs mt-1">
                  {jsonError.ticket_types}
                </div>
              )}
            </div>
            <div className="flex justify-between mt-6">
              <Button
                type="button"
                variant="outline"
                onClick={() => router.back()}
                disabled={submitting}
              >
                Cancel
              </Button>
              <Button type="submit" disabled={submitting}>
                {submitting ? "Saving..." : "Save Changes"}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
};

export default EditEventPage;
