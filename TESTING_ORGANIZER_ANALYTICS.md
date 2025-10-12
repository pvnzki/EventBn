# Testing Organizer Analytics Integration

## Problem Solved

The organizer analytics page was showing "No Organization Found" because it was expecting the `organization_id` to be directly available in the user data from localStorage. However, organizers who haven't created an organization yet won't have this field.

## Solution Implemented

### 1. Backend Changes

- **New API Endpoint**: `GET /api/organizations/user/:userId`
  - Fetches organization data using the user's ID
  - Returns 404 if user doesn't have an organization yet

### 2. Frontend Changes

- **New Hook**: `useOrganization(userId)` in `/hooks/use-organization.ts`

  - Fetches organization data for a given user ID
  - Handles loading and error states
  - Returns null if user doesn't have an organization

- **Updated Analytics Page**: `/app/organizer/analytics/page.tsx`
  - Now uses `user_id` instead of expecting `organization_id` directly
  - First fetches organization data, then uses organization ID for analytics
  - Shows helpful error message when no organization exists

### 3. Data Flow

```
User Login → localStorage stores user data with user_id
↓
Analytics page loads → extracts user_id from localStorage
↓
useOrganization hook → calls /api/organizations/user/{user_id}
↓
If organization found → use organization_id for analytics
If no organization → show "create organization" message
```

## Testing Scenarios

### Scenario 1: Organizer with Organization

**Setup:**

1. Login as organizer user
2. Ensure user has an organization in the database

**Expected Result:**

- Analytics page loads successfully
- Shows real data from organizer's events
- All charts and metrics display correctly

### Scenario 2: Organizer without Organization

**Setup:**

1. Login as organizer user
2. Ensure user has NO organization in the database

**Expected Result:**

- Shows "No Organization Found" message
- Provides guidance to create an organization first
- Retry button allows re-checking after organization creation

### Scenario 3: New Organizer Flow

**Complete Flow:**

1. Login as organizer without organization
2. See "No Organization Found" message
3. Create organization (via separate flow)
4. Return to analytics page
5. Should now show analytics data

## Database Setup for Testing

### Create Test Organizer User

```sql
INSERT INTO "User" (name, email, password_hash, role)
VALUES ('Test Organizer', 'organizer@test.com', 'hashed_password', 'ORGANIZER');
```

### Create Organization for Testing

```sql
INSERT INTO "Organization" (user_id, name, description)
VALUES (
  (SELECT user_id FROM "User" WHERE email = 'organizer@test.com'),
  'Test Organization',
  'Test organization for analytics'
);
```

### Create Test Events and Data

```sql
-- Insert test event
INSERT INTO "Event" (
  organization_id,
  title,
  description,
  start_time,
  end_time,
  capacity,
  status
) VALUES (
  (SELECT organization_id FROM "Organization" WHERE name = 'Test Organization'),
  'Test Event',
  'Test event for analytics',
  NOW() + INTERVAL '7 days',
  NOW() + INTERVAL '8 days',
  100,
  'ACTIVE'
);

-- Insert test ticket purchases
INSERT INTO "ticket_purchase" (
  event_id,
  user_id,
  purchase_date,
  price
) VALUES (
  (SELECT event_id FROM "Event" WHERE title = 'Test Event'),
  (SELECT user_id FROM "User" WHERE email = 'organizer@test.com'),
  NOW(),
  5000
);

-- Insert test payment
INSERT INTO "payment" (
  user_id,
  event_id,
  amount,
  status,
  payment_date
) VALUES (
  (SELECT user_id FROM "User" WHERE email = 'organizer@test.com'),
  (SELECT event_id FROM "Event" WHERE title = 'Test Event'),
  50.00,
  'completed',
  NOW()
);
```

## API Testing

### Test Organization Endpoint

```bash
# Test getting organization by user ID (replace 1 with actual user_id)
curl http://localhost:3001/api/organizations/user/1

# Expected response when organization exists:
{
  "organization_id": 1,
  "user_id": 1,
  "name": "Test Organization",
  "description": "Test organization",
  "created_at": "2024-01-01T00:00:00.000Z",
  "user": {
    "user_id": 1,
    "name": "Test Organizer",
    "email": "organizer@test.com"
  }
}

# Expected response when no organization:
{
  "error": "Organization not found for this user."
}
```

### Test Analytics Endpoints

```bash
# Test organizer analytics (replace 1 with actual organization_id)
curl "http://localhost:3001/api/analytics/organizer/1/dashboard/overview?timeRange=6months"
curl "http://localhost:3001/api/analytics/organizer/1/dashboard/revenue-trend?timeRange=6months"
curl "http://localhost:3001/api/analytics/organizer/1/dashboard/categories"
curl "http://localhost:3001/api/analytics/organizer/1/dashboard/top-events?limit=5"
curl "http://localhost:3001/api/analytics/organizer/1/dashboard/daily-attendees"
```

## Troubleshooting

### Issue: Still shows "No Organization Found"

**Possible Causes:**

1. User data in localStorage doesn't have `user_id` field
2. Backend API endpoint not accessible
3. Database connection issues
4. Organization doesn't exist for the user

**Debug Steps:**

1. Check browser dev tools → Application → Local Storage → user data
2. Check browser dev tools → Network tab for API calls
3. Verify backend server is running on correct port
4. Check database for organization records

### Issue: Analytics show no data

**Possible Causes:**

1. No events created by the organization
2. No ticket sales or payments
3. All payments have status other than 'completed'
4. Date range filters excluding the data

**Debug Steps:**

1. Check database for events with correct organization_id
2. Verify ticket_purchase records exist
3. Ensure payment status is 'completed'
4. Try different time ranges

### Issue: API 404 errors

**Possible Causes:**

1. Routes not properly registered
2. Server not running
3. Port conflicts

**Debug Steps:**

1. Check server logs for route registration
2. Verify server is running on expected port
3. Check API_BASE_URL in frontend environment

## Environment Variables

### Frontend (.env.local)

```bash
NEXT_PUBLIC_API_URL=http://localhost:3001
```

### Backend (.env)

```bash
DATABASE_URL="postgresql://username:password@localhost:5432/eventbn"
JWT_SECRET="your-jwt-secret"
PORT=3001
```

## Expected User Experience

### Good Flow

1. User logs in as organizer
2. Analytics page loads with loading spinner
3. Organization data fetched successfully
4. Analytics data loads and displays charts
5. All metrics show real data from organizer's events

### Error Recovery Flow

1. User logs in as organizer without organization
2. "No Organization Found" message appears
3. User creates organization (external flow)
4. User clicks "Retry" button
5. Organization data fetched and analytics loads

This solution provides a robust, user-friendly experience that handles both new organizers and established ones with existing data.
