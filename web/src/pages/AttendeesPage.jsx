"use client"

import Sidebar from "../components/layout/Sidebar"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "../../components/ui/card"

const AttendeesPage = () => {
  return (
    <div className="flex h-screen bg-gray-100">
      <Sidebar />
      <div className="flex-1 p-8">
        <Card>
          <CardHeader>
            <CardTitle>Attendees</CardTitle>
            <CardDescription>Manage event attendees</CardDescription>
          </CardHeader>
          <CardContent>
            <p>Attendees page content coming soon...</p>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

export default AttendeesPage