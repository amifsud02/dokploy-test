# Stage 1: Base setup
FROM node:18-alpine AS base
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

# Copy only the necessary files from the build stage
COPY --from=build /app/.next ./.next
COPY --from=build /app/public ./public
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/pnpm-lock.yaml ./pnpm-lock.yaml

# Install production dependencies
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile --prod

# Expose the port and start the application
EXPOSE 3000
CMD ["pnpm", "start"]