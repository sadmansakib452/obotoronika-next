# Spree Commerce Application

## Project Structure

| Directory | Description |
|-----------|-------------|
| `backend/` | Rails API application (Spree Commerce) |
| `apps/storefront/` | Next.js storefront |

## Auto-Delegation (CRITICAL)

When the user asks you to do work, delegate to the correct subagent:

- **Backend work** (Rails, Spree, API, database, migrations, Sidekiq): Invoke `@spree-backend`
- **Storefront work** (Next.js, React, TypeScript, components, pages): Invoke `@spree-storefront`
- **Code review** (before merging or after implementation): Invoke `@code-review`

If the task touches BOTH backend and storefront, split it: first `@spree-backend` for the API/db work, then `@spree-storefront` for the UI.

## Agent Instructions

- **Backend work** (Ruby/Rails, Spree models, API, database): See `backend/CLAUDE.md`
- **Storefront work** (Next.js, React, TypeScript): See `apps/storefront/CLAUDE.md`

## Session Memory

At the start of every session, the current project state is in `.opencode/SESSION.md`. Read it first to understand what was done last and what's pending.

## Spree Documentation

Full developer docs are installed locally:

```
node_modules/@spree/docs/dist/
├── developer/
│   ├── core-concepts/     # Products, orders, payments, inventory, etc.
│   ├── customization/     # Decorators, extensions, configuration, dependencies
│   ├── admin/             # Admin panel customization
│   ├── storefront/        # Storefront building guides
│   ├── sdk/               # TypeScript SDK documentation
│   └── tutorial/          # Step-by-step tutorials
├── api-reference/
│   ├── store-api/         # Store API v3 guides
│   └── store.yaml         # OpenAPI 3.0 spec (all endpoints, params, schemas)
└── integrations/          # Stripe, Meilisearch, etc.
```

Read these files when you need Spree-specific guidance.

## Common Commands

```bash
npm run dev              # Start backend (Docker)
npm run stop             # Stop services
npm run console          # Rails console
npm run logs             # Backend logs
npx spree eject          # Switch to local backend builds
```
