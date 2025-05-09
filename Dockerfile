# syntax=docker/dockerfile:1.4

# Build stage
FROM --platform=$BUILDPLATFORM node:20-slim AS builder
WORKDIR /app

LABEL org.opencontainers.image.source="https://github.com/aaronsb/google-workspace-mcp"
LABEL org.opencontainers.image.description="Google Workspace MCP Server"
LABEL org.opencontainers.image.licenses="MIT"

COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm,sharing=locked \
    npm ci --prefer-offline --no-audit --no-fund

COPY . .
RUN --mount=type=cache,target=/root/.npm,sharing=locked \
    npm run build

# Production stage
FROM node:20-slim AS production
WORKDIR /app

ARG DOCKER_HASH=unknown
ENV DOCKER_HASH=$DOCKER_HASH

COPY --from=builder /app/build ./build
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/docker-entrypoint.sh ./docker-entrypoint.sh

RUN --mount=type=cache,target=/root/.npm,sharing=locked \
    npm ci --prefer-offline --no-audit --no-fund --omit=dev && \
    npm install uuid@11.1.0 && \
    chmod +x docker-entrypoint.sh build/index.js && \
    mkdir -p /app/logs

ENTRYPOINT ["/app/docker-entrypoint.sh"]
