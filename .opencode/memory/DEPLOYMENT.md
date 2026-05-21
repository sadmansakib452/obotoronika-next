# Deployment & Infrastructure

## Docker Services

### Production (`docker-compose.yml`)
Uses prebuilt image: `ghcr.io/spree/spree:${SPREE_VERSION_TAG:-latest}`

| Service | Image | Port | Health Check |
|---------|-------|------|-------------|
| postgres | postgres:18-alpine | internal | pg_isready (5s) |
| redis | redis:7-alpine | internal | redis-cli ping (5s) |
| meilisearch | getmeili/meilisearch:latest | 7700 (host-mapped) | curl /health (5s) |
| web | ghcr.io/spree/spree | 3000 (host-mapped) | curl /up (10s, 30s start) |
| worker | ghcr.io/spree/spree | internal | — |

### Development (`docker-compose.dev.yml`)
Same services but **builds from local** `backend/Dockerfile` instead of using prebuilt image.

### Named Volumes
- `postgres_data`
- `redis_data`
- `meilisearch_data`
- `storage_data`

## Dockerfile (Multi-Stage, Production)

- **Base:** Ruby 4.0.1 slim + system deps (libjemalloc, libvips, postgresql-client)
- **Build:** Install build tools, bundle install, precompile bootsnap + assets
- **Final:** Copy artifacts only, run as non-root user (UID 1000)
- **Entrypoint:** `/rails/bin/docker-entrypoint` → runs `db:prepare` before `rails server`
- **CMD:** `./bin/rails server -b 0.0.0.0`
- **Exposes:** Port 3000
- Uses `LD_PRELOAD` for jemalloc memory allocator

## CI/CD (GitHub Actions)

### Backend CI (`backend-ci.yml`)
**Trigger:** Push to `main`, PR to `main`

**Services:** postgres:18, redis:7

**Steps:**
1. Checkout
2. Ruby setup (bundler-cache)
3. `bin/rails db:prepare` (RAILS_ENV=test, spree_test database)
4. `bundle exec rspec`
5. `bundle exec brakeman --no-pager -q` (security scan)
6. `bundle exec bundle-audit check --update` (dependency scan)

### Release Pipeline (`release.yml`)
**Trigger:** Push of `v*` tags (e.g., `v1.0.0`)

**Multi-arch build (amd64 + arm64):**
1. Build each platform image on respective runner
2. Push by digest (not tag)
3. Merge digests into multi-arch manifest
4. Tag manifest with version number + `latest`

**Image:** `ghcr.io/spree/spree:v1.0.0` and `ghcr.io/spree/spree:latest`

## Development

### Backend
```bash
# From root
npm run dev              # Start all services via Docker
npm run stop             # Stop all services
npm run console          # Rails console
npm run logs             # Web server logs
npm run logs:worker      # Sidekiq logs
npm run seed             # Seed database
npm run load-sample-data # Load sample products/categories/images
npm run eject            # Switch from prebuilt image to local build
```

### Storefront
```bash
cd apps/storefront
npm run dev              # Start on port 3001 (turbopack)
npm run check            # Biome lint + format check
npm run format           # Auto-format with Biome
npm run test             # Vitest
```

### Backend (inside backend/)
```bash
bin/setup                # bundle install + db:create/migrate/seed
bin/dev                  # Start all processes (web, admin CSS, Sidekiq)
bin/rails console        # Rails console
bin/rails db:migrate     # Run migrations
bin/rails db:seed        # Seed database
bundle exec rspec        # Full test suite
```

## Environment Variables

### Root `.env` (Docker)
| Variable | Default | Purpose |
|----------|---------|---------|
| SECRET_KEY_BASE | — | Rails secret key (generated) |
| SPREE_PORT | 3000 | Web service port mapping |
| SPREE_VERSION_TAG | latest | Spree Docker image tag |

### Backend `.env.example` (Production)
| Variable | Default | Purpose |
|----------|---------|---------|
| SECRET_KEY_BASE | (required) | Rails secret |
| DATABASE_URL | postgres://... | Full PG connection |
| REDIS_URL | redis://redis:6379/0 | Redis connection |
| REDIS_CACHE_URL | — | Dedicated cache Redis |
| MEILISEARCH_URL | — | Search engine |
| SMTP_HOST/PORT/USERNAME/PASSWORD | — | Email delivery |
| RAILS_HOST | example.com | Email link host |
| AWS_ACCESS_KEY_ID/SECRET_ACCESS_KEY | — | S3 storage |
| SENTRY_DSN | — | Error tracking |
| SPREE_PATH | — | Local Spree monorepo for development |

### Storefront `.env.example`
| Variable | Default | Purpose |
|----------|---------|---------|
| SPREE_API_URL | — | Backend URL (required) |
| SPREE_PUBLISHABLE_KEY | — | API key (required) |
| NEXT_PUBLIC_DEFAULT_COUNTRY | us | Default country |
| NEXT_PUBLIC_DEFAULT_LOCALE | en | Default locale |
| NEXT_PUBLIC_SITE_URL | — | Canonical URL |
| SPREE_WEBHOOK_SECRET | — | Webhook signature |
| RESEND_API_KEY | — | Email delivery |
| NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY | — | Stripe public key |
| GTM_ID | — | Google Tag Manager |
| SENTRY_DSN | — | Error tracking |

## Deployment Options

1. **Docker Compose** (current): Any VPS with Docker
2. **Render.com**: Blueprint in `backend/render.yaml` (free tier)
3. **Kamal/Custom**: Multi-stage Dockerfile ready for any container platform
4. **Storefront:** Designed for Vercel deployment (uses edge middleware, serverless)
