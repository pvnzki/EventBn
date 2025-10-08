# Use official Node.js image
FROM node:20-bookworm-slim

# Install OpenSSL for Prisma engines
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends openssl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy the rest of your code
COPY . .

# Create uploads directory for static files
RUN mkdir -p uploads

# Expose the port your server runs on
EXPOSE 3000

# Start the server
CMD ["node", "server.js"]
