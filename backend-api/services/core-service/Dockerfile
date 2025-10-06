FROM node:18-slim

# Install necessary dependencies for Prisma and bcrypt
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    libssl3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Set environment variables for Prisma
ENV PRISMA_CLI_BINARY_TARGETS="debian-openssl-3.0.x"

COPY package*.json ./
RUN npm install --production

COPY . .

# Rebuild bcrypt for the correct platform
RUN npm rebuild bcrypt --build-from-source

# Generate Prisma client for the correct platform
RUN npx prisma generate

# Debug: Check if Prisma client was generated correctly
RUN ls -la node_modules/.prisma/ || echo "No .prisma directory found"
RUN ls -la node_modules/@prisma/client/ || echo "No @prisma/client directory found"

EXPOSE 3001
CMD ["node", "server.js"]
