# Organizer Analytics Integration

## Overview

The organizer analytics page has been updated to display real data specific to each organizer's events and performance, filtered by their organization ID.

## Key Differences from Admin Analytics

### Data Filtering

- **Admin Analytics**: Shows platform-wide data across all organizations
- **Organizer Analytics**: Shows data filtered by specific organization ID only

### Metrics Scope

- **Revenue**: Only from events created by the organizer's organization
- **Tickets**: Only from the organizer's events
- **Events**: Only events belonging to the organizer's organization
- **Categories**: Distribution of the organizer's event categories only
- **Top Events**: Best performing events from the organizer's organization

## New Backend Features

### Organizer-Specific Analytics Service Methods

Added to `backend-api/services/core-service/analytics/index.js`:

1. `getOrganizerDashboardOverview(organizationId, timeRange)`
2. `getOrganizerRevenueTrend(organizationId, timeRange)`
3. `getOrganizerEventCategories(organizationId)`
4. `getOrganizerTopEvents(organizationId, limit)`
5. `getOrganizerDailyAttendees(organizationId)`

### New API Endpoints

Added to `backend-api/routes/analytics.js`:

- `GET /api/analytics/organizer/:organizationId/dashboard/overview?timeRange=6months`
- `GET /api/analytics/organizer/:organizationId/dashboard/revenue-trend?timeRange=6months`
- `GET /api/analytics/organizer/:organizationId/dashboard/categories`
- `GET /api/analytics/organizer/:organizationId/dashboard/top-events?limit=5`
- `GET /api/analytics/organizer/:organizationId/dashboard/daily-attendees`

### Database Queries

All queries are filtered by `organization_id` to ensure data isolation:

```sql
-- Example: Revenue data for specific organizer
SELECT SUM(p.amount) as revenue, COUNT(*) as tickets
FROM payment p
JOIN "Event" e ON p.event_id = e.event_id
WHERE p.status = 'completed'
  AND e.organization_id = ?
  AND p.payment_date >= ?
```

## Frontend Features

### Organizer Analytics Hook

Created `web/hooks/use-organizer-analytics.ts`:

- Similar to admin analytics hook but requires organization ID
- Validates organization ID before making API calls
- Provides organizer-specific data fetching

### Enhanced User Interface

Updated `web/app/organizer/analytics/page.tsx`:

#### User Validation

- Checks if user data exists
- Validates organization ID presence
- Shows appropriate error states for missing data

#### Real-time Data Display

- Revenue from organizer's events only
- Tickets sold for organizer's events
- Conversion rate based on organizer's event performance
- Total events created by the organizer

#### Empty State Handling

- Informative messages for new organizers
- Guidance on what actions to take
- Encouragement to create events and start selling tickets

#### Error Handling

- Network error recovery
- Invalid organization ID handling
- Graceful fallbacks for missing data

## Data Flow

### User Authentication & Organization ID

1. User logs in and data is stored in localStorage
2. Organization ID is extracted from user data
3. If no organization ID exists, user is prompted to create one

### Data Fetching Process

1. Organization ID is validated
2. API calls are made with organization ID as parameter
3. Backend filters all data by organization ID
4. Frontend displays organizer-specific insights

## Security Considerations

### Data Isolation

- All database queries filter by organization ID
- No cross-organization data leakage
- Organizers can only see their own analytics

### API Security

- Organization ID validation on backend
- Proper error handling for unauthorized access
- Rate limiting considerations for analytics endpoints

## Performance Optimizations

### Database Indexing

Recommended indexes for optimal performance:

```sql
CREATE INDEX idx_event_organization_id ON "Event"(organization_id);
CREATE INDEX idx_payment_event_date ON payment(event_id, payment_date);
CREATE INDEX idx_ticket_purchase_event_date ON ticket_purchase(event_id, purchase_date);
```

### Caching Strategy

- Consider caching analytics data for frequently accessed time ranges
- Implement cache invalidation when new data is added
- Use Redis for session-based caching

## Testing Scenarios

### With Organizer Data

1. Create organization with events
2. Add ticket sales and payments
3. Verify analytics show correct filtered data
4. Test different time ranges
5. Validate category distribution

### Without Data

1. New organizer with no events
2. Organizer with events but no sales
3. Organizer with sales but no recent activity
4. Test empty state messages and guidance

### Error Scenarios

1. Invalid organization ID
2. Network connectivity issues
3. Database connection problems
4. Missing user authentication

## Monitoring & Analytics

### Key Metrics to Track

- API response times for organizer endpoints
- Most popular analytics time ranges
- Common error scenarios
- Data fetching patterns

### Logging

- Log analytics queries for performance monitoring
- Track API usage patterns
- Monitor error rates and types

## Future Enhancements

### Advanced Analytics

1. **Comparative Analytics**

   - Compare performance with previous periods
   - Benchmark against industry averages
   - Trend analysis and predictions

2. **Real-time Dashboards**

   - Live ticket sales tracking
   - Real-time event performance
   - WebSocket-based updates

3. **Export Features**

   - PDF report generation
   - CSV data exports
   - Scheduled email reports

4. **Custom Metrics**
   - User-defined KPIs
   - Custom date ranges
   - Advanced filtering options

### Integration Opportunities

1. **Third-party Analytics**

   - Google Analytics integration
   - Social media metrics
   - Email marketing analytics

2. **Business Intelligence**
   - Data warehouse integration
   - Advanced reporting tools
   - Predictive analytics

## Deployment Checklist

### Backend

- [ ] Deploy analytics service updates
- [ ] Add new API routes
- [ ] Update database indexes
- [ ] Test all organizer endpoints

### Frontend

- [ ] Deploy organizer analytics page
- [ ] Update analytics hooks
- [ ] Test user authentication flow
- [ ] Verify error handling

### Database

- [ ] Run necessary migrations
- [ ] Add performance indexes
- [ ] Verify data integrity
- [ ] Test query performance

### Monitoring

- [ ] Set up analytics endpoint monitoring
- [ ] Configure error alerting
- [ ] Track performance metrics
- [ ] Monitor user adoption

## Support Documentation

### For Organizers

- How to interpret analytics data
- Understanding conversion rates
- Best practices for event promotion
- Troubleshooting common issues

### For Developers

- API documentation and examples
- Database schema explanations
- Performance optimization guidelines
- Error handling best practices
