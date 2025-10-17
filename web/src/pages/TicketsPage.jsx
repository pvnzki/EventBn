"use client"

import Sidebar from "../components/layout/Sidebar"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "../../components/ui/card"

const TicketsPage = () => {
  return (
    <div className="flex h-screen bg-gray-100">
      <Sidebar />
      <div className="flex-1 p-8">
        <Card>
          <CardHeader>
            <CardTitle>Tickets</CardTitle>
            <CardDescription>Manage event tickets</CardDescription>
          </CardHeader>
          <CardContent>
            <p>Tickets page content coming soon...</p>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

export default TicketsPage