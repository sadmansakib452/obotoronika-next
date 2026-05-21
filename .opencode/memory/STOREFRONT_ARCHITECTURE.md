# Storefront Architecture — Next.js 16 + React 19 + Spree SDK

## Overview

Headless e-commerce storefront using Next.js 16 App Router with `[country]/[locale]` internationalized routing. Connects to the Spree backend via `@spree/sdk`.

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | Next.js 16 (App Router) |
| React | 19 (compiler enabled, Server Components, `use()`, `useActionState`, `useOptimistic`) |
| Styling | Tailwind CSS v4 |
| UI Library | shadcn/ui (Radix primitives) |
| API Client | @spree/sdk v1.0.0 |
| i18n | next-intl (5 locales: en, de, pl, es, fr) |
| Payments | Stripe Elements, Adyen Drop-in, PayPal Smart Buttons |
| Lint/Format | Biome (not ESLint) |
| Testing | Vitest + React Testing Library |
| Analytics | GA4 ecommerce (via GTM, 17 events) |
| Error Tracking | Sentry |
| Emails | React Email templates + Resend (production) / local disk (dev) |

## Routing Structure

```
src/app/
├── layout.tsx                           # Root: <html>, Geist font, GTM, Vercel Analytics
├── global-error.tsx                     # Sentry error boundary
├── api/webhooks/spree/route.ts          # Webhook endpoint
│
└── [country]/[locale]/                  # i18n route segment
    ├── layout.tsx                       # Validates market, wraps Store/Auth/Cart providers
    │
    ├── (storefront)/                    # Route group: full header + footer layout
    │   ├── layout.tsx                   # Fetches categories, renders Header + Footer
    │   ├── page.tsx                     # Home: HeroSection + FeaturedProducts
    │   ├── products/
    │   │   ├── page.tsx                 # Product listing with filters (URL params)
    │   │   └── [slug]/page.tsx          # Product detail + JSON-LD
    │   ├── c/[...permalink]/page.tsx    # Category page with children + products
    │   ├── cart/page.tsx                # Cart page with Express Checkout
    │   └── account/                     # Login, register, profile, orders, addresses
    │       ├── layout.tsx               # Sidebar nav + auth guard
    │       └── ...                      # Sub-pages
    │
    └── (checkout)/                      # Route group: minimal layout (no header/footer)
        ├── layout.tsx                   # Checkout shell with sidebar summary
        ├── checkout/[id]/page.tsx       # Address → Delivery → Payment flow
        ├── confirm-payment/[id]/page.tsx # Interstitial for offsite payment returns
        └── order-placed/[id]/page.tsx   # Confirmation page
```

## Middleware

`src/proxy.ts` → `createSpreeMiddleware()`:
1. Skips static routes (`/_next`, `/api`, `/dev`, `/favicon.ico`)
2. If URL has `/[country]/[locale]` → syncs cookies
3. Otherwise detects country (cookie → `x-vercel-ip-country` → `cf-ipcountry` → default) and locale → redirects to `/[country]/[locale]/...`

## SDK Integration (`src/lib/spree/`)

### config.ts — Singleton Client
- Lazy-init from `SPREE_API_URL` + `SPREE_PUBLISHABLE_KEY`
- `resetClient()` for testing

### cookies.ts — Server-Side Cookies
| Cookie | Name | Max Age | Purpose |
|--------|------|---------|---------|
| Cart token | `_spree_cart_token` | 30 days | Guest order token |
| Cart ID | `_spree_cart_token_id` | 30 days | Stored cart UUID |
| Access token | `_spree_jwt` | 7 days | JWT for authenticated API calls |
| Refresh token | `_spree_refresh_token` | 30 days | Long-lived JWT renewal |

All cookies are httpOnly, secure in production, sameSite: "lax"

### auth-helpers.ts — JWT Management
- `getAuthOptions()` — Proactively decodes JWT `exp` claim; refreshes if <5 min to expiry
- `withAuthRefresh(fn)` — Wraps any operation; on 401, tries refresh token then retries
- `tryRefresh()` — Calls `auth.refresh()` with stored refresh token

### middleware.ts — `createSpreeMiddleware()`
Creates Next.js middleware for country/locale detection and cookie sync

### webhooks.ts — `createWebhookHandler()`
- Verifies `x-spree-webhook-signature`
- Dispatches to registered handlers
- Unhandled events return `{ handled: false }`

## Data Layer (`src/lib/data/`) — 16 Server Action Files

### Pattern 1: `actionResult()` Wrapper
```typescript
export async function addToCart(variantId, quantity) {
  return actionResult(async () => {
    const result = await client.carts.items.create(cartId, ...);
    return { cart: result };
  }, "Failed to add item to cart");
}
// Returns { success: true, cart } | { success: false, error }
```

### Pattern 2: "use cache" with cacheTag
```typescript
// Persistent remote caching
export async function cachedListProducts(params) {
  "use cache: remote";
  cacheLife("tenMinutes");
  cacheTag("products");
  return client.products.list(params);
}
```

### Files

| File | Purpose | Cache |
|------|---------|-------|
| products.ts | Product list + detail + filters | cacheLife("tenMinutes"), tags: "products", "product:${slug}" |
| categories.ts | Category list + detail + products | cacheLife("hours" for list, "tenMinutes" for detail) |
| cart.ts | getCart, getOrCreateCart, add/update/remove items | updateTag("cart") after mutations |
| checkout.ts | getCheckoutOrder, updateAddresses, selectDelivery, applyCode | updateTag("checkout") |
| payment.ts | create/complete payment sessions, complete order | — |
| customer.ts | login, register, logout, getCustomer, updateCustomer | updateTag("customer", "cart") |
| orders.ts | getOrders, getOrder (authenticated) | — |
| addresses.ts | CRUD customer addresses | withAuthRefresh |
| credit-cards.ts | List/delete saved cards | withAuthRefresh |
| gift-cards.ts | List gift cards | — |
| countries.ts | getCountries, getCountry | cacheLife("hours") |
| markets.ts | getMarkets, resolveCurrency | cacheLife("hours") |
| policies.ts | getPolicy by slug | — |
| cookies.ts | isAuthenticated() | — |
| express-checkout-flow.ts | Orchestrate Stripe Express Checkout | — |
| cached.ts | React.cache() wrappers + expand/field lists | Per-render dedup |
| utils.ts | actionResult(), withFallback() | Helpers |

## Caching Strategy (3-Tier)

1. **"use cache" (remote, persistent):** Products/categories/markets/countries with `cacheLife` and `cacheTag`
2. **React.cache() (in-memory, per-render):** Dedup within a single page render
3. **updateTag() (on-demand revalidation):** Cart/auth mutations revalidate `"cart"`, `"customer"`, `"checkout"` tags

### Per-User Cache Segmentation
`userToken` passed as separate arg (NOT to SDK) to segment cache per user for B2B pricing. Guest users share one cache entry.

## State Management (Contexts)

### StoreContext
- country, locale, currency (derived from market)
- countries: CountryWithMarket[] (all available)
- Loading state

### AuthContext
- user, isAuthenticated, loading
- login(), register(), logout(), refreshUser()
- Hydrates from getCustomer() on mount

### CartContext
- cart, itemCount (derived from line items sum)
- addItem(), updateItem(), removeItem(), refreshCart()
- Cart drawer open/close state
- mutateCart() pattern: set updating → action → handle result → router.refresh()
- Re-fetches on pathname change

### CheckoutContext
- summaryContent (ReactNode)
- Enables sidebar summary content injection from main page

## Key Component Patterns

### Server/Client Split
- Server Components (default): Layouts, page data fetching, SEO metadata, listing shells
- Client Components (`"use client"`): CartDrawer, ProductCard, FilterBar, PaymentSection, VariantPicker

### Infinite Scroll
1. Server renders `ProductListing` with page 1 → passes to `InfiniteProductList`
2. Client uses `IntersectionObserver` on sentinel div
3. Fetches next page via `startTransition`
4. Appends deduplicated products
5. Component keyed on `listingKey(state)` — any filter change remounts with fresh page 1
6. Filter state in URL params; pagination state in component local state

### Filter Architecture
- FilterBar reads URL search params, writes via `router.push` in `startTransition`
- FilterDropdown components: Price, Sort, Availability, Option values
- `buildListingSearchParams()` serializes to URL
- `wrapInRansackParams()` wraps in `q[...]` for Spree Ransack

### Checkout Flow
1. AddressSection → DeliveryMethodSection → PaymentSection
2. Staleness detection: compares line-item fingerprint between CartContext and local cart
3. PaymentSection uses `useImperativeHandle` to expose `submit()`
4. Multi-gateway: Stripe PaymentElement, Adyen Drop-in, PayPal Smart Buttons, Check/COD
5. Session flow: create session → render gateway form → submit → confirm payment → complete order
6. Express Checkout: Stripe ExpressCheckoutElement with shipping callbacks

## Webhooks & Emails

### Webhook Endpoint: `POST /api/webhooks/spree`
Handlers:
- `order.completed` → order confirmation email
- `order.canceled` → cancellation email
- `order.shipped` → shipment notification with tracking
- `customer.password_reset_requested` → password reset email

Idempotency guard: `PROCESSED_EVENTS` Set (max 10k entries)

### Email System
- Dev: Renders HTML via react-email → writes to `.next/emails/` for browser preview
- Prod: Sends via Resend API
- Templates: OrderConfirmation, OrderCanceled, ShipmentShipped, PasswordReset

## Security

- Server-only API keys (`SPREE_API_URL`, `SPREE_PUBLISHABLE_KEY`)
- Only Stripe key is `NEXT_PUBLIC_`
- httpOnly cookies for all auth/cart tokens
- Webhook signature verification (x-spree-webhook-signature + timestamp replay protection)
- JWT proactive refresh (decode exp, refresh if <5 min)
- Policy consent required for guest checkout

## Testing

| Area | Tool | Location |
|------|------|----------|
| Server actions | Vitest (mocked SDK) | `src/lib/data/__tests__/` |
| Component tests | React Testing Library | `src/components/*/__tests__/` |
| Context tests | React Testing Library | `src/contexts/__tests__/` |
| Page tests | React Testing Library | `src/app/*/__tests__/` |

## Environment Variables (from .env.example)

| Variable | Required | Purpose |
|----------|----------|---------|
| SPREE_API_URL | Yes | Backend URL |
| SPREE_PUBLISHABLE_KEY | Yes | API storefront key |
| NEXT_PUBLIC_DEFAULT_COUNTRY | No (default: us) | Default country |
| NEXT_PUBLIC_DEFAULT_LOCALE | No (default: en) | Default locale |
| NEXT_PUBLIC_SITE_URL | Yes | Canonical URL |
| NEXT_PUBLIC_STORE_NAME | Yes | Store name |
| GTM_ID | No | Google Tag Manager |
| SPREE_WEBHOOK_SECRET | Yes | Webhook signing secret |
| RESEND_API_KEY | No | Email delivery |
| NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY | No | Stripe public key |
| SENTRY_DSN | No | Error tracking |
