# EventBn Services Architecture

## Current Status: Modular Monolith

The services are currently organized as **modules within a single Express application** (not true microservices yet). They share:

- Same Node.js process
- Same database connection (Prisma client)
- Same Express server (port 3000)

## Service Organization

### Core Service (`/services/core-service/`)

Handles core business logic:

- **Users**: Authentication, profiles, user management
- **Organizations**: Organization CRUD and management
- **Events**: Event creation, management, discovery
- **Tickets**: Ticket purchasing, QR codes, validation

### Post Service (`/services/post-service/`)

Handles social features:

- **Posts**: User posts, comments, likes, shares
- **Feed**: Timeline generation and social interactions

### Upload Service (`/services/upload-service/`)

Handles file operations:

- **Media**: Image/video uploads via Cloudinary
- **Assets**: File management and CDN integration

## Health Endpoints

Monitor service modules:

```
GET /api/services/core/health    # Core service health
GET /api/services/post/health    # Post service health
GET /health                      # Overall application health
```

## Migration to True Microservices

To convert to separate microservices:

### 1. Separate Applications

```bash
# Create separate Node.js apps
backend-core-service/     # Port 3001
backend-post-service/     # Port 3002
backend-upload-service/   # Port 3003
```

### 2. Database Strategy

**Option A: Shared Database**

- Keep single PostgreSQL instance
- Services access different table groups
- Use database-level access controls

**Option B: Database Per Service**

- Split into separate databases
- Handle cross-service data via APIs
- Implement eventual consistency patterns

### 3. Inter-Service Communication

- **Synchronous**: HTTP REST APIs between services
- **Asynchronous**: RabbitMQ events (already partially implemented)
- **Service Discovery**: Use Docker Compose or Kubernetes

### 4. Deployment

```yaml
# docker-compose.yml example
services:
  core-service:
    build: ./backend-core-service
    ports: ["3001:3000"]

  post-service:
    build: ./backend-post-service
    ports: ["3002:3000"]

  upload-service:
    build: ./backend-upload-service
    ports: ["3003:3000"]
```

## Benefits of Current Modular Structure

1. **Clean Separation**: Services don't cross-import each other
2. **Easy Testing**: Each service module can be tested independently
3. **Migration Ready**: Minimal changes needed for microservice split
4. **Development Speed**: Single deployment, shared database, simpler debugging

## When to Migrate

Consider true microservices when you need:

- Independent scaling (e.g., post service needs more instances)
- Different technology stacks per service
- Independent deployment cycles
- Team boundaries aligned with services
- Fault isolation (one service failure doesn't crash others)

## Current API Routes

All routes currently served from single Express app:

```
/api/auth/*           → Core Service (Auth module)
/api/users/*          → Core Service (Users module)
/api/events/*         → Core Service (Events module)
/api/organizations/*  → Core Service (Organizations module)
/api/tickets/*        → Core Service (Tickets module)
/api/payments/*       → Core Service (via routes/payments.js)

# Future post service routes (not yet implemented):
/api/posts/*          → Post Service
/api/feed/*           → Post Service
/api/uploads/*        → Upload Service
```
