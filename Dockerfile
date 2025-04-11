# Build stage
FROM node:18-alpine as build

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM nginx:alpine

# Install envsubst to handle environment variables in nginx config
RUN apk add --no-cache gettext

# Copy the built files from the build stage
COPY --from=build /app/build /usr/share/nginx/html

# Copy and configure nginx configuration
COPY nginx.conf /etc/nginx/templates/default.conf.template

# Expose the port (Cloud Run will override this)
EXPOSE 8080

# Start Nginx with environment variable substitution
CMD ["/bin/sh", "-c", "envsubst '${PORT}' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
