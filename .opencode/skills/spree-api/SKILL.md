---
name: spree-api
description: Spree Store API v3 patterns, SDK usage, endpoints, authentication, and data fetching patterns. Load when working with the storefront's data layer or adding new API endpoints.
license: MIT
compatibility: opencode
metadata:
  audience: storefront-developers
  workflow: spree-api-integration
---

# Spree Store API v3 & SDK Patterns

## SDK Singleton (storefront)

```typescript
import { getClient } from "@/lib/spree";
// Module-level singleton — auto-inits from SPREE_API_URL + SPREE_PUBLISHABLE_KEY
const client = await getClient();
```

## Server Action Pattern

```typescript
// src/lib/data/my-feature.ts
"use server";

import { getClient } from "@/lib/spree";
import { getLocaleOptions } from "@/lib/spree/locale";
import { getAccessToken } from "@/lib/spree/cookies";
import { actionResult } from "./utils";

export async function getMyData(params: MyParams) {
  return actionResult(async () => {
    const client = await getClient();
    const localeOptions = await getLocaleOptions();
    const accessToken = await getAccessToken();

    const result = await client.someResource.list({
      ...localeOptions,
      ...params,
    }, {
      token: accessToken,
    });

    return { data: result };
  }, "Failed to fetch my data");
}
```

## Caching Pattern

```typescript
export async function cachedMyData(params: MyParams, options: Options, userToken?: string) {
  "use cache: remote";
  cacheLife("tenMinutes");
  cacheTag("my-data");

  const client = await getClient();
  return client.someResource.list(params, options);
}

// Public wrapper that resolves locale + auth
export async function getMyData(params: MyParams) {
  const localeOptions = await getLocaleOptions();
  const accessToken = await getAccessToken();
  return cachedMyData(params, localeOptions, accessToken || undefined);
}
```

## Cache Life Options
- `cacheLife("tenMinutes")` — 5 min stale, 10 min revalidate, 60 min expire
- `cacheLife("hours")` — longer cache for rarely-changing data (categories, markets, countries)

## On-Demand Revalidation (After Mutations)
```typescript
import { updateTag } from "next/cache";
updateTag("cart");       // Revalidate cart data
updateTag("customer");   // Revalidate customer data
updateTag("checkout");   // Revalidate checkout data
```

## Per-User Cache Segmentation
```typescript
// userToken is passed as SEPARATE arg (NOT to SDK call)
// Guest users pass undefined — they share one cache entry
// Authenticated users pass their JWT — each gets own cache
export async function cachedProducts(params, options, userToken?: string) {
  "use cache: remote";
  cacheTag("products");
  return client.products.list(params, options);
}
```

## Auth Patterns

### Guest Cart
```typescript
const cartToken = await getCartToken();
const result = await client.carts.get({ spreeToken: cartToken });
```

### Authenticated
```typescript
const accessToken = await getAccessToken();
const cartToken = await getCartToken();
const result = await client.orders.list(params, {
  token: accessToken,
  spreeToken: cartToken,
});
```

### JWT Proactive Refresh
```typescript
import { withAuthRefresh } from "@/lib/spree/auth-helpers";
// Automatically refreshes JWT on 401, retries operation
const result = await withAuthRefresh(() =>
  client.customer.update(data, { token: await getAccessToken() })
);
```

## Common Endpoints (SDK → API)

| SDK Call | Endpoint |
|----------|----------|
| `client.products.list()` | `GET /api/v3/store/products` |
| `client.products.get(slug)` | `GET /api/v3/store/products/:slug` |
| `client.products.filters()` | `GET /api/v3/store/products/filters` |
| `client.categories.list()` | `GET /api/v3/store/categories` |
| `client.categories.get(permalink)` | `GET /api/v3/store/categories/:permalink` |
| `client.carts.get()` | `GET /api/v3/store/cart` |
| `client.carts.create()` | `POST /api/v3/store/cart` |
| `client.carts.items.create()` | `POST /api/v3/store/cart/line_items` |
| `client.carts.items.update()` | `PATCH /api/v3/store/cart/line_items/:id` |
| `client.carts.items.delete()` | `DELETE /api/v3/store/cart/line_items/:id` |
| `client.carts.discountCodes.apply()` | `POST /api/v3/store/cart/apply_coupon_code` |
| `client.carts.giftCards.apply()` | `POST /api/v3/store/cart/apply_gift_card` |
| `client.carts.complete()` | `PATCH /api/v3/store/cart/complete` |
| `client.carts.paymentSessions.create()` | `POST /api/v3/store/cart/payment_sessions` |
| `client.auth.login()` | `POST /api/v3/store/account/login` |
| `client.auth.logout()` | `DELETE /api/v3/store/account/logout` |
| `client.auth.refresh()` | `POST /api/v3/store/account/refresh` |
| `client.customer.get()` | `GET /api/v3/store/account` |
| `client.customer.update()` | `PATCH /api/v3/store/account` |
| `client.customers.create()` | `POST /api/v3/store/account` |
| `client.customer.addresses.*()` | `GET/POST/PATCH/DELETE /api/v3/store/account/addresses` |
| `client.customer.orders.list()` | `GET /api/v3/store/account/orders` |
| `client.markets.list()` | `GET /api/v3/store/markets` |
| `client.countries.list()` | `GET /api/v3/store/countries` |
| `client.policies.get(slug)` | `GET /api/v3/store/policies/:slug` |

## Error Handling
```typescript
// actionResult returns { success: true, data } | { success: false, error }
const result = await getMyData(params);
if (!result.success) {
  return <ErrorFallback message={result.error} />;
}

// withFallback returns fallback value on error
const { data } = await withFallback(getProducts(params), { data: [] });
```

## Testing Server Actions
```typescript
import { vi } from "vitest";
vi.mock("@/lib/spree");

// Mock SDK client
const mockClient = { products: { list: vi.fn() } };
vi.mocked(getClient).mockResolvedValue(mockClient as any);
mockClient.products.list.mockResolvedValue({ data: [...], pagination: {...} });

const result = await getProducts({});
expect(result.success).toBe(true);
```
