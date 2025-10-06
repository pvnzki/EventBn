# Use official Node.js image
FROM node:18-slim

# Install OpenSSL for Prisma
RUN apt-get update && apt-get install -y openssl

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install --production

# Copy the rest of your code
COPY . .

# Rebuild bcrypt for the container architecture
RUN npm rebuild bcrypt --build-from-source

# Generate Prisma client
RUN npx prisma generate

# Create uploads directory for static files
RUN mkdir -p uploads

# Expose the port your server runs on
EXPOSE 3000

# Start the server
CMD ["node", "server.js"]
