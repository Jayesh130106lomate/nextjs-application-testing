FROM node:24-alpine AS base

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

# stage 4 

FROM base AS runner

WORKDIR /app

ENV NODE_ENV=production

ENV NEXT_TELEMETRY_DISABLED=1

ENV PORT=3000

ENV HOSTNAME="0.0.0.0"

# Create an unprivileged user
RUN addgroup -S -g 1001 nodejs && \
    adduser -S -u 1001 -G nodejs nextjs

# Copy only required runtime files
COPY --from=builder --chown=nextjs:nodejs \
    /app/public ./public

COPY --from=builder --chown=nextjs:nodejs \
    /app/.next/standalone ./

COPY --from=builder --chown=nextjs:nodejs \
    /app/.next/static ./.next/static

# Do not run as root
USER nextjs

EXPOSE 3000

CMD ["node", "server.js"]
