# =============================================================================
# DOCKERFILE FOR DEMO TODO REACT APPLICATION
# =============================================================================
# This Dockerfile uses a multi-stage build approach to create an optimized
# production-ready container for a React application.
#
# Multi-stage builds allow us to:
# 1. Use a full Node.js environment to build the application
# 2. Copy only the built artifacts to a lightweight Nginx server
# 3. Reduce final image size significantly (from ~1GB to ~25MB)
# =============================================================================

# =============================================================================
# STAGE 1: BUILD STAGE
# =============================================================================
# Purpose: Install dependencies and build the React application
# Base Image: node:16-alpine (Alpine Linux for smaller size)
# =============================================================================

FROM node:16-alpine AS build

# WORKDIR: Sets the working directory inside the container
# All subsequent commands will run from this directory
# Creates the directory if it doesn't exist
WORKDIR /app

# COPY package files first (for better Docker layer caching)
# If package.json hasn't changed, Docker will use cached node_modules
# This significantly speeds up subsequent builds
COPY package.json package-lock.json ./

# RUN npm install: Install dependencies
# Using --legacy-peer-deps to handle older dependency configurations
# This ensures compatibility with peer dependency requirements
RUN npm install --legacy-peer-deps

# COPY all project files to the container
# This includes source code, configuration files, etc.
COPY . .

# RUN npm run build: Execute the build script from package.json
# This creates optimized production files in the /app/build directory
# For this project, it runs 'craco build' which outputs to /app/build
RUN npm run build

# =============================================================================
# STAGE 2: PRODUCTION STAGE
# =============================================================================
# Purpose: Serve the built application using Nginx
# Base Image: nginx:alpine (minimal Nginx image ~25MB)
# =============================================================================

FROM nginx:alpine AS production

# Copy custom Nginx configuration for SPA routing
# This is essential for React Router to work correctly
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the built files from the build stage
# /app/build contains the production-optimized React application
# /usr/share/nginx/html is Nginx's default static file directory
COPY --from=build /app/build /usr/share/nginx/html

# EXPOSE: Documents which port the container listens on
# Nginx default HTTP port is 80
# Note: This is documentation only; actual port mapping happens at runtime
EXPOSE 80

# CMD: The command that runs when the container starts
# nginx -g 'daemon off;' - runs Nginx in foreground (required for Docker)
# Docker containers exit when the main process exits, so Nginx must run
# in the foreground, not as a background daemon
CMD ["nginx", "-g", "daemon off;"]
