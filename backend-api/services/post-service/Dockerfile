FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --production

COPY . .

# Generate Prisma client for the correct platform
RUN npx prisma generate

EXPOSE 3002
CMD ["node", "server.js"]
