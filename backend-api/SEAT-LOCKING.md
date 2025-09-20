# EventBn Backend API with Redis Seat Locking

This backend API now includes Redis-based seat locking functionality to prevent double bookings.

## 🚀 Quick Start

### Using Docker (Recommended)

1. **Start the services:**
```bash
docker-compose up --build
```

This will start:
- Backend API on `http://localhost:3000`
- Redis server on `localhost:6379`

2. **Stop the services:**
```bash
docker-compose down
```

### Local Development (without Docker)

1. **Install Redis locally:**
- Windows: Download from https://redis.io/download
- macOS: `brew install redis`
- Ubuntu: `sudo apt install redis-server`

2. **Start Redis:**
```bash
redis-server
```

3. **Start the backend:**
```bash
npm install
npm run dev
```

## 🔒 Seat Locking API Endpoints

### 1. Lock a Seat
```http
POST /api/seat-locks/events/{eventId}/seats/{seatId}/lock
Authorization: Bearer {token}
```

**Response:**
```json
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
```

### 2. Check Seat Lock Status
```http
GET /api/seat-locks/events/{eventId}/seats/{seatId}/lock
```

**Response:**
```json
{
  "success": true,
  "lockStatus": {
    "locked": true,
    "ttl": 245,
    "userId": "user456",
    "timestamp": 1693123456789
  }
}
```

### 3. Extend Lock (for Payment)
```http
PUT /api/seat-locks/events/{eventId}/seats/{seatId}/lock/extend
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "message": "Lock extended successfully",
  "duration": "10 minutes"
}
```

### 4. Release Lock
```http
DELETE /api/seat-locks/events/{eventId}/seats/{seatId}/lock
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "message": "Lock released successfully"
}
```

### 5. Get All Locked Seats for Event
```http
GET /api/seat-locks/events/{eventId}/locks
```

**Response:**
```json
{
  "success": true,
  "eventId": "123",
  "lockedSeats": [
    {
      "seatId": "A1",
      "ttl": 245,
      "timestamp": 1693123456789
    }
  ]
}
```

## 🔄 Complete Seat Selection Flow

### Frontend Implementation:

1. **When user selects a seat:**
```javascript
// Lock the seat
const response = await fetch('/api/seat-locks/events/123/seats/A1/lock', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer ' + token,
    'Content-Type': 'application/json'
  }
});

if (response.ok) {
  // Seat locked successfully
  showSeatAsSelected();
  startCountdownTimer();
} else if (response.status === 409) {
  // Seat already locked by another user
  showSeatAsLocked();
}
```

2. **Check seat availability before showing seat map:**
```javascript
const response = await fetch('/api/seat-locks/events/123/locks');
const data = await response.json();

data.lockedSeats.forEach(seat => {
  markSeatAsTemporarilyLocked(seat.seatId);
});
```

3. **Extend lock when starting payment:**
```javascript
const response = await fetch('/api/seat-locks/events/123/seats/A1/lock/extend', {
  method: 'PUT',
  headers: {
    'Authorization': 'Bearer ' + token,
    'Content-Type': 'application/json'
  }
});
```

4. **Release lock after successful payment:**
```javascript
// After successful booking
await fetch('/api/seat-locks/events/123/seats/A1/lock', {
  method: 'DELETE',
  headers: {
    'Authorization': 'Bearer ' + token
  }
});
```

## 📊 Redis Data Structure

**Lock Key Format:**
```
seat_lock:{eventId}:{seatId}
```

**Lock Value:**
```
{userId}:{timestamp}
```

**TTL (Time To Live):**
- Initial lock: 5 minutes
- Extended lock: 10 minutes
- Auto-expires: Redis handles cleanup

## 🛠 Environment Variables

Add to your `.env` file:

```env
# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
```

For Docker deployment, these are set in `docker-compose.yml`:
```env
REDIS_HOST=redis
REDIS_PORT=6379
```

## 🔧 Error Handling

The API handles common scenarios:

- **409 Conflict:** Seat already locked by another user
- **403 Forbidden:** User doesn't own the lock they're trying to modify
- **500 Internal Server Error:** Redis connection issues or other errors

## 🚀 Production Deployment

For production:

1. Use managed Redis (AWS ElastiCache, Google Cloud Memorystore, etc.)
2. Update `REDIS_HOST` and `REDIS_PORT` in environment variables
3. Consider Redis clustering for high availability
4. Monitor Redis memory usage and set appropriate limits

## 🧪 Testing

Test the seat locking functionality:

1. **Start services:** `docker-compose up --build`
2. **Check health:** `http://localhost:3000/health`
3. **Test locking:** Use the API endpoints above with Postman or curl

## 🐳 Docker Commands

```bash
# Build and start
docker-compose up --build

# Start in background
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Remove volumes (clears Redis data)
docker-compose down -v
```
