FROM node:24-bookworm-slim AS base

WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1

# stage 2

FROM base AS deps

COPY package.json package-lock.json ./

RUN npm ci

# stage 3

FROM base AS builder

COPY --from=deps /app/node_modules ./node_modules

COPY . .

ENV NODE_ENV=production

RUN npm run build

# stage 4  runtime {production}

FROM cgr.dev/chainguard/node:latest AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Copy runtime assets owned by Chainguard's built-in 'node' user
COPY --from=builder --chown=node:node /app/public ./public
COPY --from=builder --chown=node:node /app/.next/standalone ./
COPY --from=builder --chown=node:node /app/.next/static ./.next/static

USER node

EXPOSE 3000

CMD ["server.js"]
