# Use official Node.js image
FROM node:22-alpine

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
