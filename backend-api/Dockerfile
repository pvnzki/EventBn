# Use a Node.js image with Debian base (build tools friendly)
FROM node:18-bullseye

# Set working directory
WORKDIR /app

# Install required build tools for bcrypt & Prisma
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    openssl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install --production

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
