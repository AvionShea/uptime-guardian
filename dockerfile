# Use an official Node.js image as the base
FROM node:20-slim

# Create and set working directory inside container
WORKDIR /app

# Copy package.json and package-lock.json first (for caching)
COPY package*.json ./

RUN npm ci --omit=dev

# Copy the rest of the app
COPY . .

# Expose the app port
EXPOSE 3000

# Start the app
CMD ["node", "js/server.js"]