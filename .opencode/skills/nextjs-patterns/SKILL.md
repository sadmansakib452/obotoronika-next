---
name: nextjs-patterns
description: Next.js 16 + React 19 best practices, Server Components, Server Actions, caching, streaming, and performance patterns. Load when building or modifying storefront pages and components.
license: MIT
compatibility: opencode
metadata:
  audience: storefront-developers
  workflow: nextjs-development
---

# Next.js 16 & React 19 Patterns

## Component Architecture

### Server Component (DEFAULT — no "use client")
```typescript
// src/app/[country]/[locale]/(storefront)/products/page.tsx
import { getProducts } from "@/lib/data/products";

export default async function ProductsPage() {
  const { data: products } = await getProducts({ per_page: 12 });
  return <ProductList products={products} />;
}
```

### Client Component (ONLY when interactive)
```typescript
"use client";
import { useState } from "react";

export function ProductCard({ product }: { product: StoreProduct }) {
  const [isFavorited, setIsFavorited] = useState(false);
  return <button onClick={() => setIsFavorited(!isFavorited)}>Favorite</button>;
}
```

## useEffect — When NOT to Use

### ❌ BAD: Derived state
```typescript
const [fullName, setFullName] = useState("");
useEffect(() => { setFullName(`${first} ${last}`); }, [first, last]);
// ✅ GOOD: Compute during render
const fullName = `${first} ${last}`;
```

### ❌ BAD: Reset state on prop change
```typescript
useEffect(() => { setSelected(null); }, [productId]);
// ✅ GOOD: Use key prop
<ProductDetails key={productId} product={product} />
```

### ❌ BAD: Fetch on user event
```typescript
const [query, setQuery] = useState("");
useEffect(() => { fetchResults(query); }, [query]);
// ✅ GOOD: Fetch in event handler
const handleSearch = async (query: string) => {
  const results = await fetchResults(query);
  setResults(results);
};
```

### ❌ BAD: One-time init
```typescript
useEffect(() => { initAnalytics(); }, []);
// ✅ GOOD: Module-level init
let didInit = false;
if (!didInit) { didInit = true; initAnalytics(); }
```

### ✅ GOOD: When useEffect IS correct
- Synchronizing with external DOM APIs
- Setting up WebSocket subscriptions
- IntersectionObserver / ResizeObserver
- Focus management / scroll position

## Server Actions for Mutations

```typescript
// src/lib/data/cart.ts
"use server";

export async function addToCart(variantId: string, quantity: number) {
  return actionResult(async () => {
    const cart = await getOrCreateCart();
    const client = await getClient();
    const result = await client.carts.items.create(
      cart.id,
      { variant_id: variantId, quantity },
      { token: cart.token }
    );
    updateTag("cart");
    return { cart: result };
  }, "Failed to add item to cart");
}
```

## React 19 Features

### use() for Promises
```typescript
import { use, Suspense } from "react";

function ProductDetails({ productPromise }: { productPromise: Promise<Product> }) {
  const product = use(productPromise);
  return <div>{product.name}</div>;
}

// Parent
function Page({ id }: { id: string }) {
  const promise = getProduct(id); // Don't await
  return (
    <Suspense fallback={<Skeleton />}>
      <ProductDetails productPromise={promise} />
    </Suspense>
  );
}
```

### useActionState for Forms
```typescript
"use client";
import { useActionState } from "react";
import { updateProfile } from "@/lib/data/customer";

function ProfileForm({ user }: { user: User }) {
  const [state, formAction, isPending] = useActionState(updateProfile, {
    error: null,
    success: false,
  });

  return (
    <form action={formAction}>
      <input name="firstName" defaultValue={user.first_name} />
      <button disabled={isPending}>{isPending ? "Saving..." : "Save"}</button>
      {state.error && <p className="text-red-500">{state.error}</p>}
    </form>
  );
}
```

### useOptimistic for Instant UI
```typescript
import { useOptimistic } from "react";

function CartItem({ item, onUpdate }: Props) {
  const [optimisticQty, setOptimisticQty] = useOptimistic(item.quantity);

  const handleChange = async (newQty: number) => {
    setOptimisticQty(newQty);
    await onUpdate(item.id, newQty);
  };

  return <span>Qty: {optimisticQty}</span>;
}
```

## Streaming & Suspense

```typescript
// Page with streaming sections
export default function Page() {
  return (
    <div>
      <Suspense fallback={<ProductInfoSkeleton />}>
        <ProductInfo />
      </Suspense>
      <Suspense fallback={<ReviewsSkeleton />}>
        <Reviews />
      </Suspense>
    </div>
  );
}
```

## Parallel Data Fetching
```typescript
// ✅ Good: Parallel
const [products, categories, markets] = await Promise.all([
  getProducts(),
  getCategories(),
  getMarkets(),
]);

// ❌ Bad: Sequential waterfall
const products = await getProducts();
const categories = await getCategories();
const markets = await getMarkets();
```

## Caching Patterns

### Persistent Cache
```typescript
export async function cachedProducts(params, options, userToken?: string) {
  "use cache: remote";
  cacheLife("tenMinutes");
  cacheTag("products");
  return client.products.list(params, options);
}
```

### Per-Render Dedup
```typescript
import { cache } from "react";
export const getCachedProduct = cache((slug: string) => getProduct(slug));
```

### On-Demand Revalidation
```typescript
import { updateTag } from "next/cache";
updateTag("cart");     // After cart mutation
updateTag("customer"); // After auth change
```

## Image Optimization
```typescript
import Image from "next/image";

<ProductImage
  src={image.url}
  alt={image.alt || ""}
  width={800}
  height={800}
  priority={isLCP}     // true for above-fold critical images
  placeholder="blur"
  blurDataURL={image.thumbnail_url}
/>
```

## Lazy Loading Components
```typescript
import dynamic from "next/dynamic";

const ProductReviews = dynamic(() => import("./ProductReviews"), {
  loading: () => <ReviewsSkeleton />,
});
```

## Filter State in URL (Bookmarkable)
```typescript
"use client";
import { useSearchParams, useRouter } from "next/navigation";

function FilterBar() {
  const searchParams = useSearchParams();
  const router = useRouter();

  const updateFilter = (key: string, value: string) => {
    const params = new URLSearchParams(searchParams);
    value ? params.set(key, value) : params.delete(key);
    router.push(`?${params.toString()}`);
  };
}
```

## Metadata API
```typescript
import type { Metadata } from "next";

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const product = await getProduct(slug);

  return {
    title: product.meta_title || product.name,
    description: product.meta_description,
    openGraph: {
      images: product.images.map((img) => img.url),
    },
  };
}
```

## TypeScript Conventions
```typescript
// Use SDK types
import type { StoreProduct, StoreVariant, StoreOrder } from "@spree/sdk";

// Explicit return types
function useMyHook(): { data: Data; loading: boolean } { ... }

// satisfies for object literals
const config = { ... } satisfies MyConfig;

// No any — use unknown if truly unknown
function process(data: unknown): void { ... }
```
