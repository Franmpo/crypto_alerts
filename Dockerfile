# Install dependencies only when needed
FROM node:16.15.1-alpine AS deps
RUN apk add --no-cache libc6-compat nasm autoconf automake bash libltdl libtool gcc make g++ zlib-dev
RUN apk add --no-cache git
WORKDIR /app
RUN npm install -g npm@8.15.0
COPY package.json ./
RUN npm i
#COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./
#RUN \
#    [ -f yarn.lock ] && yarn --frozen-lockfile --prod || \
#    [ -f package-lock.json ] && npm ci || \
#    [ -f pnpm-lock.yaml ] && yarn global add pnpm && pnpm fetch --prod && pnpm i -r --offline --prod || \
#    (echo "Lockfile not found." && exit 1)
# ==================================================================
# Rebuild the source code only when needed
FROM node:16.15.1-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# Next.js collects completely anonymous telemetry data about general usage.
# Learn more here: https://nextjs.org/telemetry
# Uncomment the following line in case you want to disable telemetry during the build.
# ENV NEXT_TELEMETRY_DISABLED 1
RUN npm run build
# ==================================================================
# Production image, copy all the files and run next
FROM node:16.15.1-alpine AS runner
WORKDIR /app
ENV NODE_ENV production
# Uncomment the following line in case you want to disable telemetry during runtime.
# ENV NEXT_TELEMETRY_DISABLED 1
RUN apk add --no-cache libc6-compat nasm autoconf automake bash
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
# You only need to copy next.config.js if you are NOT using the default configuration
COPY --from=builder /app/next.config.js ./
COPY --from=builder /app/schema.prisma ./
COPY --from=builder /app/migrations ./migrations
COPY --from=builder /app/server.js ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/pages ./pages
COPY --from=builder /app/components ./components
COPY --from=builder /app/context ./context
COPY --from=builder /app/libs ./libs
COPY --from=builder /app/src ./src
COPY --from=builder /app/utils ./utils
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY .env ./
RUN chown -R nextjs /app
RUN npx prisma generate
#RUN npx prisma db push
RUN npx prisma migrate deploy
# Automatically leverage output traces to reduce image size 
# https://nextjs.org/docs/advanced-features/output-file-tracing
# COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
# COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
USER nextjs
EXPOSE 3000
ENV PORT 3000
CMD ["npm", "run", "start"]