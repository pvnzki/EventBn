# Use a more secure and updated Node.js image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install required build tools for bcrypt & Prisma (Alpine Linux)
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    openssl \
    git

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install --production

# Copy Prisma schemas for services
COPY services/*/prisma ./prisma/
COPY services/core-service/package*.json ./services/core-service/
COPY services/post-service/package*.json ./services/post-service/

# Install dependencies for each service
RUN cd services/core-service && npm install --production
RUN cd services/post-service && npm install --production

# Copy the rest of the backend code
COPY . .

# Rebuild bcrypt for container architecture
RUN npm rebuild bcrypt --build-from-source

# Generate Prisma client
RUN npx prisma generate

# Create uploads directory for static files
RUN mkdir -p uploads

# Expose default backend port
EXPOSE 3000

# Start your microservices (core + post)
CMD ["node", "start-microservices.js"]
