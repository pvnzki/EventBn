"use client"

import Sidebar from "../components/layout/Sidebar"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "../../components/ui/card"

const AnalyticsPage = () => {
  return (
    <div className="flex h-screen bg-gray-100">
      <Sidebar />
      <div className="flex-1 p-8">
        <Card>
          <CardHeader>
            <CardTitle>Analytics</CardTitle>
            <CardDescription>View your analytics and insights</CardDescription>
          </CardHeader>
          <CardContent>
            <p>Analytics page content coming soon...</p>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

export default AnalyticsPage