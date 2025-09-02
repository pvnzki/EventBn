"use client";
import { useRouter, useSearchParams } from "next/navigation";
import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";

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
};

const EditEventPage = () => {
  const router = useRouter();
  const searchParams = useSearchParams();
  const eventId = searchParams ? searchParams.get("id") : null;
  const [event, setEvent] = useState<Event | null>(null);

  useEffect(() => {
    if (eventId) {
      fetch(`http://localhost:3000/api/events/${eventId}`)
        .then((res) => res.json())
        .then((data) => setEvent(data.data))
        .catch((err) => console.error(err));
    }
  }, [eventId]);

  if (!event) return <div>Loading...</div>;

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">Edit Event: {event.title}</h1>
      {/* Add your event edit form here, prefilled with event data */}
      <Button onClick={() => router.back()}>Back</Button>
    </div>
  );
};

export default EditEventPage;
