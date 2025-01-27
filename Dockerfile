# Stage 1: Base setup
FROM --platform=$TARGETPLATFORM node:18-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

# Stage 2: Build the application
FROM base AS build
WORKDIR /app

# Copy package files and install dependencies
COPY package.json pnpm-lock.yaml ./
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile

# Copy the rest of the application and build
COPY . .
ENV NODE_ENV=production
RUN pnpm run build

# Stage 3: Prepare for deployment
FROM base AS deploy
WORKDIR /app
ENV NODE_ENV=production

# Copy standalone output
COPY --from=build /app/.next/standalone ./
COPY --from=build /app/.next/static ./.next/static

# Copy public assets
COPY --from=build /app/public ./public

# Expose the port and start the application
EXPOSE 8000
CMD ["node", "server.js"]