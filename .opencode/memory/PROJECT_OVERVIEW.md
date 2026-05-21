# Project Overview — my-store (Spree Commerce)

## What This Is

A **Spree Commerce** e-commerce platform with a Rails API backend and a Next.js storefront. Generated from the `spree_starter` template. Currently a **stock starter** with zero custom business logic.

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Backend framework | Rails | 8.1.x |
| E-commerce engine | Spree Commerce | 5.x (>= 5.4.0) |
| Language | Ruby | 4.0.1 |
| Database | PostgreSQL | 18 |
| Background jobs | Sidekiq | (via spree) |
| Search | Meilisearch | latest (optional) |
| Payments | Stripe, Adyen, PayPal | (extensions) |
| Frontend framework | Next.js | 16 |
| Frontend library | React | 19 |
| Styling | Tailwind CSS | v4 |
| UI components | shadcn/ui (Radix) | latest |
| API client | @spree/sdk | 1.0.0 |
| i18n | next-intl | latest |
| Linting | Biome (storefront), RuboCop (backend) | latest |
| Testing | RSpec (backend), Vitest (storefront) | latest |
| Error tracking | Sentry | latest (both) |

## Directory Structure

```
my-store/
├── backend/                  # Rails API + Spree Commerce
│   ├── app/
│   │   ├── models/           # Only Spree::User and Spree::AdminUser (everything else from gems)
│   │   ├── controllers/      # Only ApplicationController
│   │   ├── subscribers/      # Empty — add custom subscribers here
│   │   └── assets/           # Tailwind + Stimulus + Turbo
│   ├── config/
│   │   ├── initializers/spree.rb    # Central Spree config
│   │   ├── routes.rb                # Routes (Spree engine at /, Sidekiq at /sidekiq)
│   │   ├── database.yml             # PostgreSQL config
│   │   └── environments/            # dev, test, production
│   ├── db/
│   │   ├── schema.rb                # 100+ tables (2135 lines)
│   │   └── migrate/                 # 75 migrations
│   ├── spec/                        # RSpec test suite (1 existing test)
│   ├── Dockerfile                   # Multi-stage production image
│   ├── Gemfile                      # Ruby dependencies
│   └── bin/                         # Scripts (setup, dev, docker-entrypoint)
│
├── apps/storefront/          # Next.js 16 storefront
│   ├── src/
│   │   ├── app/[country]/[locale]/
│   │   │   ├── (storefront)/        # Main shopping UI (header + footer)
│   │   │   └── (checkout)/         # Minimal checkout UI (no header/footer)
│   │   ├── components/             # UI components (products, cart, checkout, account, layout)
│   │   ├── contexts/               # Store, Auth, Cart, Checkout contexts
│   │   ├── lib/
│   │   │   ├── spree/              # Spree SDK integration (config, cookies, auth, middleware, webhooks)
│   │   │   └── data/               # 16 server action files (products, cart, checkout, payment, etc.)
│   │   └── types/                  # TypeScript type definitions
│   ├── messages/                   # i18n JSON (en, de, es, fr, pl)
│   ├── public/                     # Static assets
│   └── biome.json                  # Biome linter/formatter config
│
├── docker-compose.yml              # Production (prebuilt image)
├── docker-compose.dev.yml          # Development (builds from backend/)
├── .github/workflows/              # CI (backend-ci.yml) + Release (release.yml)
├── package.json                    # Root: @spree/cli + @spree/docs
├── CLAUDE.md                       # Agent instructions
└── opencode.json                   # OpenCode config (not yet populated)
```

## Ports

| Service | Dev Port | Prod Port |
|---------|----------|-----------|
| Backend (Rails) | 3000 | 3000 |
| Storefront (Next.js) | 3001 | N/A (Vercel) |
| Meilisearch | 7700 | 7700 |
| PostgreSQL | internal | internal |
| Redis | internal | internal |

## URLs

| Resource | URL |
|----------|-----|
| Admin Dashboard | http://localhost:3000/admin |
| Store API v3 | http://localhost:3000/api/v3/store |
| Admin API v3 | http://localhost:3000/api/v3/admin |
| Sidekiq UI | http://localhost:3000/sidekiq |
| Health Check | http://localhost:3000/up |
| Storefront | http://localhost:3001 |

## Default Credentials

- Admin: `spree@example.com` / `spree123`

## Spree Documentation (Local)

```
node_modules/@spree/docs/dist/
├── developer/
│   ├── core-concepts/       # Products, orders, payments, inventory
│   ├── customization/       # Decorators, extensions, configuration
│   ├── admin/               # Admin panel customization
│   ├── storefront/          # Storefront building guides
│   ├── sdk/                 # TypeScript SDK documentation
│   └── tutorial/            # Step-by-step tutorials
├── api-reference/
│   ├── store-api/           # Store API v3 guides
│   └── store.yaml           # OpenAPI 3.0 spec
└── integrations/            # Stripe, Meilisearch, etc.
```

## Current State

- **Backend:** Fresh Spree starter. No custom models, controllers, services, subscribers, or decorators.
- **Storefront:** Complete ready-to-use storefront with product listing, cart, checkout, account management. No custom features beyond what the template provides.
- **Deployment:** Not deployed. Docker Compose for local dev. CI/CD pipelines configured but not yet connected to any deployment target.

## Key Design Decisions

1. Backend customization priority: **Events/Subscribers → Service Swapping → Extensions → Decorators (last resort)**
2. Storefront uses **Server Components by default**, only `"use client"` for interactivity
3. Filter/sort state lives in **URL search params** (shareable, bookmarkable)
4. Cart/auth tokens in **httpOnly cookies** (not localStorage)
5. JWT **proactive refresh** (decode `exp`, refresh if <5 min to expiry)
6. All mutations via **Server Actions** (no API routes for CRUD)
7. Two route groups: `(storefront)` with full header/footer, `(checkout)` with minimal layout
