# HoopLock server + web console in one image.
# Build context: the repository root (Railway: RAILWAY_DOCKERFILE_PATH=hooplock/Dockerfile).

# ---- web console (Flutter) ----
FROM debian:bookworm-slim AS web
ARG FLUTTER_VERSION=3.50.1
RUN apt-get update && apt-get install -y --no-install-recommends curl git xz-utils unzip ca-certificates && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" | tar -xJ -C /opt \
 && git config --global --add safe.directory /opt/flutter
ENV PATH=/opt/flutter/bin:$PATH
RUN flutter config --no-analytics && flutter precache --web
WORKDIR /src
COPY hooplock/console/pubspec.yaml hooplock/console/pubspec.lock ./
RUN flutter pub get
COPY hooplock/console/ ./
RUN flutter build web --release --no-web-resources-cdn

# ---- server ----
FROM node:22-bookworm-slim AS server
WORKDIR /app
COPY hooplock/server/package.json hooplock/server/package-lock.json ./
RUN npm ci
COPY hooplock/server/tsconfig.json ./
COPY hooplock/server/src ./src
COPY hooplock/server/migrations ./migrations
RUN npm run build && npm prune --omit=dev

# ---- runtime ----
FROM node:22-bookworm-slim
ENV NODE_ENV=production WEB_DIR=/app/web AGENT_DIR=/app/agent PORT=8080
WORKDIR /app
COPY --from=server /app/node_modules ./node_modules
COPY --from=server /app/dist ./dist
COPY --from=server /app/migrations ./migrations
COPY --from=server /app/package.json ./
COPY --from=web /src/build/web ./web
COPY hooplock/agent-dist/ ./agent/
USER node
EXPOSE 8080
CMD ["node", "dist/src/index.js"]
