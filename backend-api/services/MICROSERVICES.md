# EventBn Microservices Architecture

## Overview

EventBn has been successfully transformed from a monolithic architecture to a true microservices architecture with two independent services:

- **Core Service** (Port 3001): Handles users, events, organizations, tickets, and authentication
- **Post Service** (Port 3002): Handles social media features (posts, comments, likes, feeds)

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Client Applications                       │
│  (Web Dashboard, Mobile App, Admin Panel)                  │
└─────────────────┬───────────────────────┬───────────────────┘
                  │                       │
                  │                       │
┌─────────────────▼─────────────────┐    │
│           API Gateway             │    │
│      (Future Implementation)      │    │
└─────────────────┬─────────────────┘    │
                  │                       │
                  │                       │
        ┌─────────▼─────────┐   ┌─────────▼─────────┐
        │   Core Service    │   │   Post Service    │
        │   (Port 3001)     │◄──┤   (Port 3002)     │
        │                   │   │                   │
        │ • Users           │   │ • Posts           │
        │ • Events          │   │ • Comments        │
        │ • Organizations   │   │ • Likes           │
        │ • Tickets         │   │ • Feeds           │
        │ • Authentication  │   │ • Social Features │
        └─────────┬─────────┘   └─────────┬─────────┘
                  │                       │
                  │                       │
        ┌─────────▼─────────┐   ┌─────────▼─────────┐
        │  PostgreSQL DB    │   │  PostgreSQL DB    │
        │   (Core Data)     │   │  (Social Data)    │
        └───────────────────┘   └───────────────────┘
                  │                       │
                  └───────────┬───────────┘
                              │
                    ┌─────────▼─────────┐
                    │     RabbitMQ      │
                    │  Message Broker   │
                    │                   │
                    │ • User Events     │
                    │ • Social Events   │
                    │ • Analytics       │
                    └───────────────────┘
```

## Service Communication

### 1. HTTP Communication (Synchronous)

**Post Service → Core Service**

- User data enrichment for posts/comments/likes
- User verification and authentication
- Event data for event-related posts

**Endpoints:**

```
Core Service Internal API:
GET  /internal/v1/users/{userId}          - Get user details
POST /internal/v1/users/batch             - Get multiple users
GET  /internal/v1/users/{userId}/verify   - Verify user exists
GET  /internal/v1/events/{eventId}        - Get event details
```

### 2. RabbitMQ Messaging (Asynchronous)

**Event Types:**

- `user.created` - New user registration
- `user.updated` - Profile updates
- `user.deleted` - Account deletion
- `post.created` - New post created
- `post.liked` - Post engagement
- `comment.created` - New comment

**Queues:**

- `user_events` - User-related events
- `post_events` - Post-related events
- `social_events` - Social interactions
- `analytics_events` - Analytics data

## Service Details

### Core Service (Port 3001)

**Responsibilities:**

- User management and authentication
- Event creation and management
- Organization management
- Ticket booking and management
- Core business logic

**API Endpoints:**

```
External API (Client Access):
POST /api/v1/auth/login           - User authentication
POST /api/v1/auth/register        - User registration
GET  /api/v1/users/profile        - Get user profile
PUT  /api/v1/users/profile        - Update profile
GET  /api/v1/events               - List events
GET  /api/v1/events/{id}          - Get event details
GET  /api/v1/analytics/dashboard  - User analytics

Internal API (Service-to-Service):
GET  /internal/v1/users/{userId}          - Get user details
POST /internal/v1/users/batch             - Batch get users
GET  /internal/v1/users/{userId}/verify   - Verify user
GET  /internal/v1/events/{eventId}        - Get event details

Health Endpoints:
GET  /health        - Basic health check
GET  /health/ready  - Readiness probe
GET  /health/live   - Liveness probe
```

### Post Service (Port 3002)

**Responsibilities:**

- Social media posts management
- Comments and reactions
- User feeds (home, explore)
- Social analytics and metrics
- Media upload handling

**API Endpoints:**

```
External API (Client Access):
GET  /api/v1/posts                    - List posts
GET  /api/v1/posts/{id}               - Get post details
POST /api/v1/posts                    - Create post
PUT  /api/v1/posts/{id}               - Update post
DELETE /api/v1/posts/{id}             - Delete post

GET  /api/v1/feeds/home               - Home feed
GET  /api/v1/feeds/explore            - Explore feed

GET  /api/v1/posts/{id}/comments      - Get comments
POST /api/v1/posts/{id}/comments      - Add comment

POST /api/v1/posts/{id}/like          - Toggle like
GET  /api/v1/posts/{id}/likes         - Get likes

Internal API (Service-to-Service):
GET  /internal/v1/users/{userId}/posts     - Get user posts
GET  /internal/v1/posts/{postId}/stats     - Post statistics
GET  /internal/v1/users/{userId}/engagement - User engagement
DELETE /internal/v1/users/{userId}/posts   - Delete user posts
GET  /internal/v1/posts/trending           - Trending posts
GET  /internal/v1/metrics                  - Service metrics

Health Endpoints:
GET  /health        - Basic health check
GET  /health/ready  - Readiness probe
GET  /health/live   - Liveness probe
```

## Authentication & Security

### Service-to-Service Authentication

- **Inter-Service Key**: Shared secret key for internal API calls
- **Header**: `X-Service-Key: your-secret-key`

### Client Authentication

- **JWT Tokens**: Bearer token authentication
- **Header**: `Authorization: Bearer <token>`
- **User ID**: Passed via `X-User-ID` header (temporary for development)

### CORS Configuration

```javascript
// Core Service
origin: [
  "http://localhost:3000",
  "http://localhost:3002",
  "http://localhost:8080",
];

// Post Service
origin: [
  "http://localhost:3000",
  "http://localhost:3001",
  "http://localhost:8080",
];
```

## Database Architecture

### Core Service Database

```sql
Tables:
- users (id, name, email, password, profile_picture, etc.)
- events (id, title, description, start_time, location, etc.)
- organizations (id, name, description, owner_id, etc.)
- tickets (id, event_id, user_id, seat_info, etc.)
- user_organizations (user_id, organization_id, role)
```

### Post Service Database

```sql
Tables:
- posts (id, user_id, content, media_url, created_at, etc.)
- comments (id, post_id, user_id, content, created_at, etc.)
- likes (id, post_id, user_id, created_at)
- follows (id, follower_id, following_id, created_at)
- feed_cache (user_id, post_id, score, created_at)
```

## Deployment

### Development Setup

1. **Install Dependencies:**

   ```bash
   # Core Service
   cd services/core-service
   npm install

   # Post Service
   cd ../post-service
   npm install
   ```

2. **Environment Configuration:**

   ```bash
   # Copy and configure environment files
   cp services/core-service/.env.example services/core-service/.env
   cp services/post-service/.env.example services/post-service/.env
   ```

3. **Database Setup:**

   ```bash
   # Run Prisma migrations for both services
   cd services/core-service && npx prisma migrate dev
   cd ../post-service && npx prisma migrate dev
   ```

4. **Start Services:**

   ```bash
   # Option 1: Use startup script
   cd services
   node start-microservices.js

   # Option 2: Start individually
   # Terminal 1 - Core Service
   cd services/core-service && npm start

   # Terminal 2 - Post Service
   cd services/post-service && npm start
   ```

### Production Deployment

**Docker Configuration:**

```dockerfile
# Core Service Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3001
CMD ["node", "server.js"]

# Post Service Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3002
CMD ["node", "server.js"]
```

**Docker Compose:**

```yaml
version: "3.8"
services:
  core-service:
    build: ./services/core-service
    ports:
      - "3001:3001"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${CORE_DB_URL}
      - INTER_SERVICE_KEY=${SERVICE_KEY}
    depends_on:
      - postgres
      - rabbitmq

  post-service:
    build: ./services/post-service
    ports:
      - "3002:3002"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${POST_DB_URL}
      - CORE_SERVICE_URL=http://core-service:3001
      - INTER_SERVICE_KEY=${SERVICE_KEY}
    depends_on:
      - postgres
      - rabbitmq
      - core-service

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=eventbn
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

  rabbitmq:
    image: rabbitmq:3-management-alpine
    environment:
      - RABBITMQ_DEFAULT_USER=${RABBITMQ_USER}
      - RABBITMQ_DEFAULT_PASS=${RABBITMQ_PASS}
    ports:
      - "5672:5672"
      - "15672:15672"

volumes:
  postgres_data:
```

## Monitoring & Observability

### Health Checks

```bash
# Core Service
curl http://localhost:3001/health

# Post Service
curl http://localhost:3002/health

# Readiness Probes
curl http://localhost:3001/health/ready
curl http://localhost:3002/health/ready
```

### Service Discovery

Each service exposes metadata about itself:

```bash
curl http://localhost:3001/      # Core service info
curl http://localhost:3002/      # Post service info
```

### Logging

- Structured logging with service identification
- Request/response logging with correlation IDs
- Error tracking with stack traces
- Performance metrics logging

## Future Enhancements

1. **API Gateway**: Centralized routing and authentication
2. **Service Mesh**: Istio/Linkerd for advanced traffic management
3. **Circuit Breakers**: Resilience patterns for service failures
4. **Distributed Tracing**: Request tracing across services
5. **Auto-scaling**: Kubernetes HPA for dynamic scaling
6. **Database Sharding**: Horizontal database scaling
7. **Caching Layer**: Redis for improved performance
8. **Message Streaming**: Apache Kafka for high-throughput events

## Migration from Monolith

The migration has been completed with:

- ✅ Separate service applications
- ✅ Independent databases
- ✅ HTTP inter-service communication
- ✅ RabbitMQ event messaging
- ✅ Service authentication
- ✅ Independent deployment
- ✅ Health monitoring
- ✅ Error handling
- ✅ Environment configuration

The services now operate as true microservices with clear boundaries, independent scaling, and fault isolation.
