FROM node:18-slim

# Install necessary dependencies for Prisma, bcrypt, and Puppeteer
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    libssl3 \
    ca-certificates \
    openssl \
    wget \
    gnupg \
    fonts-liberation \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgconf-2-4 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    libxtst6 \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Set environment variables for Prisma
ENV PRISMA_CLI_BINARY_TARGETS="debian-openssl-3.0.x"
ENV PRISMA_QUERY_ENGINE_BINARY="./node_modules/.prisma/client/query_engine-debian-openssl-3.0.x"

# Copy package files first for better caching
COPY package*.json ./
COPY prisma ./prisma

# Install dependencies (including Prisma)
RUN npm install --production

# Copy the rest of the application
COPY . .

# Rebuild bcrypt for the correct platform
RUN npm rebuild bcrypt --build-from-source

# Generate Prisma client with explicit platform
RUN npx prisma generate --schema=./prisma/schema.prisma

# Debug: Verify Prisma client generation
RUN echo "=== Prisma Debug Information ===" && \
    ls -la node_modules/.prisma/ || echo "No .prisma directory found" && \
    ls -la node_modules/@prisma/client/ || echo "No @prisma/client directory found" && \
    find node_modules -name "*prisma*" -type d && \
    echo "=== End Debug ==="

# Test Prisma import
RUN node -e "try { const { PrismaClient } = require('@prisma/client'); console.log('✅ PrismaClient import successful'); } catch(e) { console.log('❌ PrismaClient import failed:', e.message); }"

EXPOSE 3001
CMD ["node", "server.js"]