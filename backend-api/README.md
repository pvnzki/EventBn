# EventBn Backend API

This is the backend API server for the EventBn application.

## Setup

### Prerequisites

- Node.js (v14 or higher)
- npm or yarn
- PostgreSQL (for database)
- Redis (optional, for caching)

### Installation

1. Install dependencies:

```bash
npm install
```

2. Set up environment variables:

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env with your configuration
# Make sure to update the database credentials, JWT secrets, etc.
```

3. Start the development server:

```bash
npm run dev
```

Or for production:

```bash
npm start
```

## Environment Variables

The application uses the following environment variables (see `.env.example` for all options):

### Required Variables

- `PORT` - Server port (default: 3000)
- `NODE_ENV` - Environment (development/production)
- `DATABASE_URL` - PostgreSQL connection string
- `JWT_SECRET` - Secret key for JWT tokens

### Optional Variables

- `REDIS_HOST` - Redis host for caching
- `SMTP_*` - Email configuration
- `STRIPE_*` - Payment gateway configuration
- `GOOGLE_MAPS_API_KEY` - For location services

## Security Notes

⚠️ **Important**: Never commit the `.env` file to version control. It contains sensitive information like database passwords and API keys.

The `.env` file is already included in `.gitignore` to prevent accidental commits.

## API Endpoints

### Health Check

- `GET /health` - Server health status

### Authentication (Coming Soon)

- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `POST /api/auth/logout` - User logout

### Events (Coming Soon)

- `GET /api/events` - Get all events
- `POST /api/events` - Create new event
- `GET /api/events/:id` - Get event by ID
- `PUT /api/events/:id` - Update event
- `DELETE /api/events/:id` - Delete event

### Users (Coming Soon)

- `GET /api/users/profile` - Get user profile
- `PUT /api/users/profile` - Update user profile

## Development

### Running in Development Mode

```bash
npm run dev
```

This will start the server with nodemon for automatic restarts on file changes.

### Environment Setup

1. Copy `.env.example` to `.env`
2. Update the variables in `.env` with your local configuration
3. Ensure your database is running and accessible
4. Run the server

### Database Setup

Make sure PostgreSQL is installed and running, then create a database:

```sql
CREATE DATABASE eventbn_db;
```

Update the `DATABASE_URL` in your `.env` file accordingly.

## Production Deployment

1. Set `NODE_ENV=production` in your environment
2. Update all production-specific environment variables
3. Use strong, unique secrets for JWT and other sensitive configurations
4. Ensure database and Redis are properly configured
5. Set up proper logging and monitoring

## Contributing

1. Make sure to never commit the `.env` file
2. Update `.env.example` if you add new environment variables
3. Follow the existing code style and patterns
4. Add appropriate error handling and logging
