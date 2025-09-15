# Use build argument for Node version
ARG NODE_VERSION=20.14.0

# ---------- Builder Stage ----------
FROM node:${NODE_VERSION}-alpine AS builder

WORKDIR /usr/src/questionService

# Install dependencies
COPY package*.json ./
RUN npm ci

# Copy source files
COPY . .

# Generate Prisma client & build project
RUN npx prisma generate && npm run build


# ---------- Production Stage ----------
FROM node:${NODE_VERSION}-alpine AS production

WORKDIR /usr/src/questionService

# Copy only required artifacts from builder
COPY --from=builder /usr/src/questionService/node_modules ./node_modules
COPY --from=builder /usr/src/questionService/dist ./dist
COPY --from=builder /usr/src/questionService/generated ./generated
COPY --from=builder /usr/src/questionService/package*.json ./
COPY --from=builder /usr/src/questionService/prisma ./prisma
COPY --from=builder /usr/src/questionService/.env ./

# Expose the app port
EXPOSE 3000

# Healthcheck for container monitoring
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

# Run the app with module-alias support
CMD ["node", "-r", "module-alias/register", "dist/index.js"]
