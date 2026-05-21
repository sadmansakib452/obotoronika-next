# API Endpoints — Store API v3

## SDK to API Mapping

The storefront uses `@spree/sdk` Client. All SDK calls map to Spree Store API v3 endpoints.

## Product Endpoints

| SDK Call | Endpoint | Used In |
|----------|----------|---------|
| `client.products.list(params)` | `GET /api/v3/store/products` | Product listing, category products, featured products |
| `client.products.get(id_or_slug)` | `GET /api/v3/store/products/:id` | Product detail page |
| `client.products.filters(params)` | `GET /api/v3/store/products/filters` | Filter options (price ranges, option values, availability) |

### Product List Params
- `per_page` (default 12)
- `page` (for pagination)
- `includes` — comma-separated associations (e.g., `images,default_variant,option_types`)
- `fields` — sparse fieldsets per resource (e.g., `[products]=name,slug,price`)
- `filter[name]` — search query
- `filter[price]` — price range
- `filter[option_types]` — option values filter
- `sort` — `price`, `-price`, `name`, `-name`, `available_on`, `-available_on`

## Category Endpoints

| SDK Call | Endpoint | Used In |
|----------|----------|---------|
| `client.categories.list(params)` | `GET /api/v3/store/categories` | Header nav, footer |
| `client.categories.get(id_or_permalink)` | `GET /api/v3/store/categories/:id` | Category page |

### Category List Params
- `depth_eq` — filter by depth level (0 = root)
- `includes` — e.g., `children,children.children`
- `per_page`

## Cart Endpoints

| SDK Call | Endpoint | Used In |
|----------|----------|---------|
| `client.carts.get()` | `GET /api/v3/store/cart` | CartContext hydration |
| `client.carts.create()` | `POST /api/v3/store/cart` | getOrCreateCart() |
| `client.carts.update(params)` | `PATCH /api/v3/store/cart` | Update cart attributes |
| `client.carts.items.create(data)` | `POST /api/v3/store/cart/line_items` | addToCart() |
| `client.carts.items.update(id, data)` | `PATCH /api/v3/store/cart/line_items/:id` | updateCartItem() |
| `client.carts.items.delete(id)` | `DELETE /api/v3/store/cart/line_items/:id` | removeCartItem() |
| `client.carts.associate(userId)` | `POST /api/v3/store/cart/associate` | Associate guest cart with user |
| `client.carts.discountCodes.apply(code)` | `POST /api/v3/store/cart/apply_coupon_code` | Apply discount |
| `client.carts.discountCodes.remove(code)` | `DELETE /api/v3/store/cart/remove_coupon_code/:code` | Remove discount |
| `client.carts.giftCards.apply(code)` | `POST /api/v3/store/cart/apply_gift_card` | Apply gift card |
| `client.carts.giftCards.remove(code)` | `DELETE /api/v3/store/cart/remove_gift_card/:code` | Remove gift card |
| `client.carts.complete()` | `PATCH /api/v3/store/cart/complete` | Complete order |

### Cart Auth Options
- Guest: `{ token: cartToken }` (spreeToken)
- Authenticated: `{ token: jwtToken, spreeToken: cartToken }`

## Checkout Endpoints

| SDK Call | Endpoint | Used In |
|----------|----------|---------|
| `client.orders.get(id, params)` | `GET /api/v3/store/orders/:id` | Order detail |
| `client.carts.fulfillments.update(data)` | `PATCH /api/v3/store/cart` | Update shipping/billing addresses, email |
| `client.carts.paymentSessions.create(data)` | `POST /api/v3/store/cart/payment_sessions` | Start payment for gateway |
| `client.carts.paymentSessions.complete(sessionId, data)` | `PATCH /api/v3/store/cart/payment_sessions/:id/complete` | Complete payment session |
| `client.carts.payments.create(data)` | `POST /api/v3/store/cart/payments` | Direct payment (Check/COD) |
| Shipping rates | `GET /api/v3/store/cart/shipping_rates` | Delivery method selection |
| `client.carts.fulfillments.update(shipping_rate_id)` | `PATCH /api/v3/store/cart` | Select delivery rate |

## Auth Endpoints

| SDK Call | Endpoint | Used In |
|----------|----------|---------|
| `client.auth.login({ email, password })` | `POST /api/v3/store/account/login` | login() |
| `client.auth.logout()` | `DELETE /api/v3/store/account/logout` | logout() |
| `client.auth.refresh(refreshToken)` | `POST /api/v3/store/account/refresh` | JWT refresh |
| `client.passwordResets.create({ email })` | `POST /api/v3/store/account/password_resets` | Forgot password |
| `client.passwordResets.update({ token, password })` | `PATCH /api/v3/store/account/password_resets/:token` | Reset password |

## Customer Endpoints

| SDK Call | Endpoint | Used In |
|----------|----------|---------|
| `client.customers.create(params)` | `POST /api/v3/store/account` | register() |
| `client.customer.get()` | `GET /api/v3/store/account` | AuthContext hydration |
| `client.customer.update(data)` | `PATCH /api/v3/store/account` | updateCustomer() |
| `client.customer.addresses.list()` | `GET /api/v3/store/account/addresses` | Address management |
| `client.customer.addresses.get(id)` | `GET /api/v3/store/account/addresses/:id` | Get single address |
| `client.customer.addresses.create(data)` | `POST /api/v3/store/account/addresses` | Create address |
| `client.customer.addresses.update(id, data)` | `PATCH /api/v3/store/account/addresses/:id` | Update address |
| `client.customer.addresses.delete(id)` | `DELETE /api/v3/store/account/addresses/:id` | Delete address |
| `client.customer.orders.list(params)` | `GET /api/v3/store/account/orders` | Order history |
| `client.customer.creditCards.list()` | `GET /api/v3/store/account/credit_cards` | Saved cards |
| `client.customer.creditCards.delete(id)` | `DELETE /api/v3/store/account/credit_cards/:id` | Remove card |
| `client.customer.giftCards.list()` | `GET /api/v3/store/account/gift_cards` | Gift card balance |

## Market & Country Endpoints

| SDK Call | Endpoint | Used In |
|----------|----------|---------|
| `client.markets.list()` | `GET /api/v3/store/markets` | StoreContext, country validation |
| `client.markets.resolve(params)` | `GET /api/v3/store/markets/resolve` | Auto-detect market |
| `client.markets.countries.list()` | `GET /api/v3/store/markets/:id/countries` | Available countries |
| `client.countries.list()` | `GET /api/v3/store/countries` | Country list |
| `client.countries.get(id)` | `GET /api/v3/store/countries/:id` | Country detail (states) |

## CMS Endpoints

| SDK Call | Endpoint | Used In |
|----------|----------|---------|
| `client.policies.get(slug)` | `GET /api/v3/store/policies/:slug` | Policy pages (privacy, terms) |

## Webhook Endpoint

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/webhooks/spree` | POST | Receive Spree webhook events |

### Events Handled
- `order.completed` → Order confirmation email
- `order.canceled` → Cancellation email
- `order.shipped` → Shipment notification
- `customer.password_reset_requested` → Password reset email

## Auth Patterns

| Endpoint Type | Auth Required |
|---------------|---------------|
| Products, Categories, Markets, Countries | Publishable API key |
| Cart (guest) | Publishable API key + cart token |
| Cart (authenticated) | JWT + cart token |
| Customer (profile, orders, addresses) | JWT + customer scope |
| Checkout (guest) | Cart token + email |
| Checkout (authenticated) | JWT + cart token |
| Webhooks | Webhook secret (signature verification) |
