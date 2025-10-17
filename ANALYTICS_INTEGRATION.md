# Analytics Integration Testing Guide

## Overview

The admin analytics page has been updated to display real data from the backend API instead of hardcoded values.

## Changes Made

### Backend Changes

1. **Enhanced Analytics Service** (`backend-api/services/core-service/analytics/index.js`)

   - Added `getDashboardOverview()` - Returns key metrics like revenue, tickets sold, conversion rate
   - Added `getRevenueTrend()` - Returns monthly revenue and ticket data
   - Added `getEventCategories()` - Returns event category distribution
   - Added `getTopEvents()` - Returns top performing events by revenue
   - Added `getDailyAttendees()` - Returns daily attendance data for the last week

2. **New API Endpoints** (`backend-api/routes/analytics.js` & `backend-api/controllers/analytics.js`)
   - `GET /api/analytics/dashboard/overview?timeRange=6months`
   - `GET /api/analytics/dashboard/revenue-trend?timeRange=6months`
   - `GET /api/analytics/dashboard/categories`
   - `GET /api/analytics/dashboard/top-events?limit=5`
   - `GET /api/analytics/dashboard/daily-attendees`

### Frontend Changes

1. **Analytics Hook** (`web/hooks/use-analytics.ts`)

   - Custom React hook that fetches all analytics data
   - Handles loading states and error handling
   - Supports different time ranges

2. **Analytics Page** (`web/app/admin/analytics/page.tsx`)
   - Replaced all hardcoded data with real API calls
   - Added loading spinners and error states
   - Enhanced data formatting with proper currency and number formatting
   - Added fallbacks when no data is available

## API Data Structure

### Dashboard Overview

```typescript
interface DashboardOverview {
  totalRevenue: number;
  ticketsSold: number;
  conversionRate: number; // tickets per event average
  pageViews: number; // based on search logs
  totalPayments: number;
  totalEvents: number;
}
```

### Revenue Trend Data

```typescript
interface RevenueData {
  month: string; // "Jan", "Feb", etc.
  revenue: number;
  tickets: number;
  events: number;
}
```

### Event Categories

```typescript
interface CategoryData {
  name: string; // category name
  value: number; // percentage
  color: string; // hex color for chart
}
```

### Top Events

```typescript
interface TopEvent {
  name: string;
  attendees: number;
  revenue: number;
  conversion: number; // percentage based on capacity
}
```

## Testing Instructions

### Prerequisites

1. Ensure PostgreSQL database is running
2. Ensure Redis is running (if used)
3. Install all dependencies: `npm install` in both frontend and backend

### Backend Testing

1. Start the backend server:

   ```bash
   cd backend-api
   npm run dev
   ```

2. Test the new endpoints using curl or Postman:

   ```bash
   # Test dashboard overview
   curl http://localhost:3001/api/analytics/dashboard/overview?timeRange=6months

   # Test revenue trend
   curl http://localhost:3001/api/analytics/dashboard/revenue-trend?timeRange=6months

   # Test categories
   curl http://localhost:3001/api/analytics/dashboard/categories

   # Test top events
   curl http://localhost:3001/api/analytics/dashboard/top-events?limit=5

   # Test daily attendees
   curl http://localhost:3001/api/analytics/dashboard/daily-attendees
   ```

### Frontend Testing

1. Set up environment variable (if needed):

   ```bash
   # In web/.env.local
   NEXT_PUBLIC_API_URL=http://localhost:3001
   ```

2. Start the frontend:

   ```bash
   cd web
   npm run dev
   ```

3. Navigate to `/admin/analytics` and verify:
   - Loading states appear initially
   - Real data loads from the backend
   - Charts display actual data
   - Empty states show when no data is available
   - Time range selector updates the data

### Sample Data Setup

To see meaningful analytics, ensure you have:

1. Users in the database
2. Events with different categories
3. Ticket purchases with completed payments
4. Some search log entries

### Expected Behavior

#### With Data

- Key metrics show actual numbers from the database
- Charts display real trends and distributions
- Top events list shows actual events ranked by revenue
- Performance insights reflect actual data patterns

#### Without Data

- Graceful fallbacks with helpful messages
- Empty state displays for charts
- Zero values for metrics
- Guidance on what data is needed

## Troubleshooting

### Common Issues

1. **Database Connection Errors**

   - Ensure DATABASE_URL is correctly set
   - Check PostgreSQL is running
   - Verify database schema matches Prisma schema

2. **API Endpoint 404 Errors**

   - Verify routes are properly registered in main router
   - Check route paths match exactly

3. **CORS Issues**

   - Ensure CORS is configured for frontend domain
   - Check API_URL is correctly set in frontend

4. **No Data Showing**

   - Check if events exist in database
   - Verify payments have 'completed' status
   - Ensure ticket purchases are linked to payments

5. **Chart Not Rendering**
   - Check browser console for errors
   - Verify chart data format matches expected structure
   - Ensure chart container has proper dimensions

## Future Enhancements

1. **Real-time Updates**

   - Add WebSocket support for live data updates
   - Implement periodic data refresh

2. **More Metrics**

   - Revenue per category
   - User engagement metrics
   - Geographic distribution
   - Time-based trends

3. **Export Functionality**

   - PDF reports
   - CSV data export
   - Email reports

4. **Advanced Filtering**
   - Date range picker
   - Category filters
   - Event-specific analytics
