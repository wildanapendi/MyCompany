# backend/Dockerfile
# Node.js 24.16.0 LTS (Iron) — alpine3.21 untuk image yang ringan
FROM node:24.16.0-alpine3.21 AS deps
RUN apk add --no-cache python3 make g++
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

FROM node:24.16.0-alpine3.21 AS production
LABEL maintainer="YPRN Team"

# Buat user non-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./
COPY server.js ./
COPY database/ ./database/
COPY scripts/ ./scripts/

# ✅ Buat entrypoint script untuk init direktori saat runtime
# (bukan saat build, agar tidak ditimpa volume mount)
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Buat base uploads dir — volume akan di-mount di sini
# direktori ini penting agar path resolving tidak error
RUN mkdir -p /app/uploads \
  && chown -R appuser:appgroup /app

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD node -e "fetch('http://localhost:${PORT:-5000}/api/health').then(r=>{if(!r.ok)throw new Error();process.exit(0)}).catch(()=>process.exit(1))"

USER appuser

# ✅ Gunakan entrypoint, bukan langsung node
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["node", "server.js"]
