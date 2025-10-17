"use client"

import Sidebar from "../components/layout/Sidebar"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "../../components/ui/card"

const EventsPage = () => {
  return (
    <div className="flex h-screen bg-gray-100">
      <Sidebar />
      <div className="flex-1 p-8">
        <Card>
          <CardHeader>
            <CardTitle>Events</CardTitle>
            <CardDescription>Manage your events</CardDescription>
          </CardHeader>
          <CardContent>
            <p>Events page content coming soon...</p>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

export default EventsPage