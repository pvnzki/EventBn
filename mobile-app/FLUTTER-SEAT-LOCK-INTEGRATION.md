# 🔒 Flutter Seat Lock Integration Guide

## Overview

This guide explains how to integrate the Redis-based seat locking system into your Flutter EventBn app. The system prevents double bookings by temporarily locking seats when users select them.

## 🚀 Quick Start

### 1. **Backend Setup**

First, ensure your backend is running with Redis:

```bash
# In backend-api directory
docker-compose up --build
```

This starts:
- Backend API on `http://localhost:3000` 
- Redis server on `localhost:6379`

### 2. **Frontend Integration**

The seat locking is now integrated into your existing Flutter screens:

- **SeatSelectionScreen** - Handles seat locking/unlocking
- **PaymentScreen** - Extends locks during payment
- **SeatLockService** - Manages all lock operations

## 📱 **How It Works**

### **User Flow:**

1. **Seat Selection:**
   - User taps on available seat
   - App calls `lockSeat()` API
   - Seat is locked for 5 minutes
   - Other users see seat as "Locked" (orange)

2. **During Payment:**
   - Payment screen extends lock to 10 minutes
   - User has more time to complete payment

3. **After Payment:**
   - Successful payment releases all locks
   - Seats marked as permanently booked in database

4. **Auto-Expiry:**
   - If user abandons selection, locks auto-expire
   - Other users can select those seats

## 🎯 **Key Features Implemented**

### ✅ **Real-time Seat Status**
- **Available** (Green) - Can be selected
- **Selected** (Orange) - Selected by current user (auto-locked behind the scenes)
- **Unavailable** (Gray/Red) - Already booked or being selected by another user

### ✅ **User-Friendly Experience**
Shows only relevant states to users:
- No confusing "locked" terminology
- Orange = "I selected this seat"  
- Gray = "Not available right now"

### ✅ **Behind-the-Scenes Locking**
- Automatic 5-minute lock when seat selected
- Extends to 10 minutes during payment
- Auto-cleanup if user abandons selection
- Real-time conflict prevention

### ✅ **Error Handling**
- Network timeout handling
- User-friendly error messages
- Graceful degradation

## 🔧 **Technical Implementation**

### **SeatLockService Methods:**

```dart
// Lock a seat (5 minutes)
final result = await seatLockService.lockSeat(
  eventId: 'event123',
  seatId: 'A1',
);

// Check lock status  
final status = await seatLockService.getSeatLockStatus(
  eventId: 'event123',
  seatId: 'A1',
);

// Extend lock (10 minutes for payment)
await seatLockService.extendSeatLock(
  eventId: 'event123', 
  seatId: 'A1',
);

// Release lock
await seatLockService.releaseSeatLock(
  eventId: 'event123',
  seatId: 'A1',
);
```

### **Real-time Updates:**

The app polls for lock updates every 15 seconds:

```dart
// Start polling
seatLockService.startPollingEventLocks(eventId);

// Listen to updates
seatLockService.getLockUpdateStream(eventId)?.listen((update) {
  // Handle seat lock/unlock events
});
```

## 🎨 **UI Components**

### **LockableSeat Widget**

Advanced seat widget with built-in locking:

```dart
LockableSeat(
  eventId: eventId,
  seatId: seatId,
  seatLabel: 'A1',
  isAvailable: true,
  isSelected: false,
  price: 25.0,
  onTap: () => handleSeatTap(),
)
```

### **Updated Seat Legend**

Shows user-friendly seat states:

- 🟢 **Available** - Ready to select
- � **Selected** - Selected by you (locked automatically)
- � **VIP** - Premium seating
- ⚫ **Unavailable** - Already booked or being selected

### **Simplified User Experience**

Users only see:
- **Green seats** → Available to select
- **Orange seats** → Selected by them (automatically locked for 5 minutes)
- **Gray/Red seats** → Not available (booked or being selected by someone else)

No confusing "locked" terminology - just intuitive seat selection!

## ⚡ **Performance Optimizations**

### **Efficient Polling**
- Only polls when users are viewing seat maps
- 15-second intervals (configurable)
- Stops polling when leaving screens

### **Smart Caching**
- Caches lock status locally
- Only updates changed seats
- Minimal network requests

### **Background Processing**
- Non-blocking lock operations
- Graceful error handling
- Continues working offline

## 🛠 **Configuration**

### **Lock Durations:**
```dart
// In SeatLockService
final LOCK_DURATION = 5 * 60; // 5 minutes
final PAYMENT_LOCK_DURATION = 10 * 60; // 10 minutes
```

### **Polling Interval:**
```dart
// In seat_selection_screen.dart
_startLockPolling(interval: Duration(seconds: 15));
```

### **Environment Variables:**
```env
# Backend .env
REDIS_HOST=localhost
REDIS_PORT=6379
```

## 🧪 **Testing the Implementation**

### **Test Scenarios:**

1. **Basic Locking:**
   - Open app on two devices
   - User A selects seat → User B should see it as locked

2. **Lock Expiry:**
   - Select seat, wait 5 minutes
   - Lock should expire automatically

3. **Payment Extension:**
   - Select seat → Go to payment
   - Lock should extend to 10 minutes

4. **Successful Booking:**
   - Complete payment successfully
   - Seat should be marked as permanently booked

### **Test Commands:**

```bash
# Start backend with Redis
docker-compose up --build

# Test API directly
curl -X POST http://localhost:3000/api/seat-locks/events/123/seats/A1/lock \
  -H "Authorization: Bearer YOUR_TOKEN"

# Check lock status
curl http://localhost:3000/api/seat-locks/events/123/seats/A1/lock
```

## 🔍 **Debugging**

### **Enable Debug Logs:**
```dart
// In SeatLockService
print('🔒 Seat locked: $seatId');
print('⏰ Lock extended: $seatId'); 
print('🔓 Lock released: $seatId');
```

### **Common Issues:**

1. **Locks not working:**
   - Check Redis connection
   - Verify JWT token validity
   - Ensure correct API endpoints

2. **UI not updating:**
   - Check polling is running
   - Verify stream subscriptions
   - Test network connectivity

3. **Payment lock issues:**
   - Verify payment screen extends locks
   - Check lock release after payment
   - Test abandonment scenarios

## 📊 **Monitoring**

### **Redis Commands for Monitoring:**
```bash
# Connect to Redis
redis-cli

# View all seat locks
KEYS seat_lock:*

# Check specific lock
GET seat_lock:event123:seatA1

# Monitor lock operations
MONITOR
```

### **Backend Health Check:**
```bash
curl http://localhost:3000/health
```

Should show Redis status: "Connected"

## 🚀 **Production Deployment**

### **Redis Setup:**
- Use managed Redis (AWS ElastiCache, etc.)
- Configure Redis persistence
- Set up Redis clustering for high availability

### **Environment Variables:**
```env
# Production
REDIS_HOST=your-redis-cluster.com
REDIS_PORT=6379
REDIS_PASSWORD=your-password
```

### **Monitoring:**
- Monitor Redis memory usage
- Track lock duration metrics  
- Alert on Redis connection failures

## 📚 **API Reference**

### **Backend Endpoints:**

```http
POST /api/seat-locks/events/:eventId/seats/:seatId/lock
GET  /api/seat-locks/events/:eventId/seats/:seatId/lock  
PUT  /api/seat-locks/events/:eventId/seats/:seatId/lock/extend
DELETE /api/seat-locks/events/:eventId/seats/:seatId/lock
GET  /api/seat-locks/events/:eventId/locks
```

### **Response Examples:**

```json
// Lock Success
{
  "success": true,
  "message": "Seat locked successfully",
  "lockInfo": {
    "eventId": "123",
    "seatId": "A1", 
    "userId": "user456",
    "duration": "5 minutes"
  }
}

// Lock Failed (Already Locked)
{
  "success": false,
  "message": "Seat is temporarily locked by another user",
  "ttl": 245
}
```

## 🎉 **Success!**

Your EventBn app now has a robust seat locking system that:

- ✅ Prevents double bookings
- ✅ Provides real-time updates
- ✅ Handles network issues gracefully  
- ✅ Scales for multiple concurrent users
- ✅ Works seamlessly with existing payment flow

The system is production-ready and provides an excellent user experience with clear visual feedback and automatic cleanup.

---

**Need help?** Check the backend logs and Redis status if you encounter issues. The system is designed to fail gracefully and continue working even if Redis is temporarily unavailable.
