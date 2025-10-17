"use client"

import Sidebar from "../components/layout/Sidebar"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "../../components/ui/card"

const UsersPage = () => {
  return (
    <div className="flex h-screen bg-gray-100">
      <Sidebar />
      <div className="flex-1 p-8">
        <Card>
          <CardHeader>
            <CardTitle>Users</CardTitle>
            <CardDescription>Manage users and organizers</CardDescription>
          </CardHeader>
          <CardContent>
            <p>Users page content coming soon...</p>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

export default UsersPage