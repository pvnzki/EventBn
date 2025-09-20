# EventBn Dual Architecture Guide

EventBn now supports **TWO deployment modes** - you can choose the one that suits your development or production needs!

## 🏗️ Architecture Overview

### Mode 1: Monolithic Mode (Recommended for Development)
- **Single Process**: All services run in one Node.js process  
- **Shared Database**: All services share the same database connection
- **Port**: 3001
- **Perfect for**: Development, testing, Flutter app connectivity

### Mode 2: Microservices Mode (Production Ready)
- **Separate Processes**: Each service runs independently
- **Dedicated Databases**: Each service has its own database
- **Ports**: Core Service (3001), Post Service (3002)  
- **Message Queue**: RabbitMQ for inter-service communication
- **Perfect for**: Production, scalability, enterprise deployment

---

## 🚀 How to Run Each Mode

### Running Monolithic Mode

```bash
# Navigate to the backend API directory
cd backend-api

# Start the monolithic server
node server.js
```

**What happens:**
- Single server starts on port 3001
- All services (users, events, posts) available via shared API
- Uses SQLite database (no external dependencies)
- Perfect for Flutter app development

**Endpoints available:**
- `http://localhost:3001/api/auth/*`
- `http://localhost:3001/api/events/*` 
- `http://localhost:3001/api/users/*`
- `http://localhost:3001/health`

### Running Microservices Mode

```bash
# Navigate to the services directory  
cd backend-api/services

# Start all microservices
node start-microservices.js
```

**What happens:**
- Core Service starts on port 3001 (users, events, organizations, tickets)
- Post Service starts on port 3002 (posts, comments, social features)
- Each service connects to its own PostgreSQL database
- RabbitMQ handles communication between services
- Enterprise-grade architecture with independent scaling

**Endpoints available:**
- **Core Service**: `http://localhost:3001/api/*`
- **Post Service**: `http://localhost:3002/api/posts/*`
- **Health checks**: `/health` on both services

---

## 📁 Project Structure

```
backend-api/
├── server.js                    # 🏢 MONOLITHIC MODE - Single server
├── services/
│   ├── start-microservices.js   # 🚀 MICROSERVICES MODE - Startup script
│   ├── core-service/
│   │   ├── server.js            # Independent core service
│   │   ├── .env                 # PostgreSQL config
│   │   └── prisma/schema.prisma # Core database schema
│   └── post-service/
│       ├── server.js            # Independent post service  
│       ├── .env                 # PostgreSQL config
│       └── prisma/schema.prisma # Posts database schema
├── routes/                      # Shared API routes (monolith)
└── lib/database.js             # Shared database (monolith)
```

---

## ⚙️ Configuration

### Monolithic Mode Configuration
- **File**: `backend-api/.env`
- **Database**: SQLite (`DATABASE_URL="file:./dev.db"`)
- **Port**: 3001

### Microservices Mode Configuration

#### Core Service (`services/core-service/.env`)
```env
CORE_SERVICE_PORT=3001
DATABASE_URL="postgresql://..."  # Supabase PostgreSQL
RABBITMQ_URL=amqp://localhost
```

#### Post Service (`services/post-service/.env`)
```env  
POST_SERVICE_PORT=3002
DATABASE_URL="postgresql://..."  # Different Supabase PostgreSQL
CORE_SERVICE_URL=http://localhost:3001
RABBITMQ_URL=amqp://localhost
```

---

## 🔄 Switching Between Modes

### From Monolithic to Microservices
1. Stop monolithic server: `Ctrl+C` or `taskkill /f /im node.exe`
2. Start microservices: `cd services && node start-microservices.js`

### From Microservices to Monolithic  
1. Stop microservices: `Ctrl+C` in the services terminal
2. Start monolith: `cd .. && node server.js`

---

## 📱 Flutter App Connectivity

### For Monolithic Mode:
```dart
// mobile-app/.env
BASE_URL=http://10.0.2.2:3001
```

### For Microservices Mode:
```dart  
// mobile-app/.env
BASE_URL=http://10.0.2.2:3001  # Points to core-service
POST_SERVICE_URL=http://10.0.2.2:3002  # Optional: Direct post service access
```

The Flutter app works with **both modes** using the same BASE_URL (port 3001)!

---

## 🔍 Health Checks & Monitoring

### Monolithic Mode:
```bash
curl http://localhost:3001/health
```

### Microservices Mode:
```bash  
# Core Service
curl http://localhost:3001/health

# Post Service  
curl http://localhost:3002/health
```

---

## 🎯 When to Use Which Mode?

| Scenario | Recommended Mode |
|----------|-----------------|
| **Local Development** | Monolithic (simpler setup) |
| **Flutter App Testing** | Monolithic (single endpoint) |
| **Admin Panel Development** | Either (both work) |
| **Production Deployment** | Microservices (scalable) |
| **Team Development** | Microservices (parallel work) |
| **CI/CD Pipeline** | Microservices (independent deploys) |

---

## 🛠️ Troubleshooting

### Monolithic Mode Issues:
- **Port 3001 busy**: Stop other servers with `taskkill /f /im node.exe`
- **Database errors**: Check `backend-api/.env` file exists
- **CORS errors**: Verify CORS_ORIGIN settings

### Microservices Mode Issues:
- **Service won't start**: Check PostgreSQL connection in service `.env`
- **RabbitMQ errors**: Install RabbitMQ or disable in development  
- **Port conflicts**: Ensure 3001 and 3002 are available

### Quick Reset:
```bash
# Stop all Node processes
taskkill /f /im node.exe

# Restart in desired mode
cd backend-api && node server.js          # Monolithic
# OR
cd backend-api/services && node start-microservices.js  # Microservices
```

---

## 🚀 Ready to Go!

Your EventBn backend now supports both architectures! Start with monolithic mode for development, then switch to microservices when you need the power and scalability of enterprise architecture.