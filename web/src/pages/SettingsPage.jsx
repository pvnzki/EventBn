"use client";

import Sidebar from "../components/layout/Sidebar";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "../../components/ui/card";

const SettingsPage = () => {
  return (
    <div className="flex h-screen bg-gray-100">
      <Sidebar />
      <div className="flex-1 p-8">
        <Card>
          <CardHeader>
            <CardTitle>Settings</CardTitle>
            <CardDescription>
              Application settings and configuration
            </CardDescription>
          </CardHeader>
          <CardContent>
            <p>Settings page content coming soon...</p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default SettingsPage;
