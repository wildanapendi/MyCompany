# ============================================
# Multi-stage Dockerfile for React Frontend
# Stage 1: Install dependencies & build
# Stage 2: Serve with Nginx
# ============================================

# --- Stage 1: Install dependencies & build ---
FROM node:24-alpine AS build

WORKDIR /app

# Copy package files dulu untuk cache layer
COPY package.json package-lock.json ./

# Install semua dependencies (termasuk devDependencies untuk build)
RUN npm ci

# Copy source code
COPY index.html ./
COPY vite.config.js ./
COPY postcss.config.js ./
COPY tailwind.config.js ./
COPY jsconfig.json ./
COPY public/ ./public/
COPY src/ ./src/

# Build argument untuk API URL (bisa di-override saat build)
# DEFAULT: /api (relative path) — aman untuk production (nginx reverse proxy)
# Jangan pernah gunakan localhost sebagai default di sini!
ARG VITE_API_URL=/api
ENV VITE_API_URL=${VITE_API_URL}

# Build production
RUN npm run build

# --- Stage 2: Serve dengan Nginx ---
FROM nginx:1.31.1-alpine AS production

# Label metadata
LABEL maintainer="YPRN Team"
LABEL description="Rimba Nusantara Frontend - React SPA served by Nginx"

# Hapus default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx config & security headers
COPY nginx/nginx.conf /etc/nginx/conf.d/default.conf
COPY nginx/security-headers.conf /etc/nginx/security-headers.conf

# Copy build output dari stage sebelumnya
COPY --from=build /app/dist /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost/health || exit 1

# Nginx berjalan di foreground
CMD ["nginx", "-g", "daemon off;"]
