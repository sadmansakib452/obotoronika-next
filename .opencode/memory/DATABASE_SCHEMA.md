# Database Schema — Core Tables & Relationships

## Overview

PostgreSQL 18 database with 100+ tables. Extensions: `plpgsql`, `pg_trgm` (fuzzy search).

## Core E-Commerce Tables

### Products
```
spree_products
├── name, description, slug (friendly_id)
├── available_on, make_active_at, deleted_at (soft delete)
├── status, meta_title, meta_description
├── store_id (multi-tenancy)
├── private_metadata, public_metadata (JSONB)
├── variants_count, media_count
└── has_one: spree_product_translation (Mobility)

spree_variants
├── sku, barcode, weight, height, width, depth
├── cost_price, dealer_price, cost_currency
├── position, track_inventory
├── product_id → spree_products
├── deleted_at, private_metadata, public_metadata
└── has_many: spree_prices

spree_prices
├── amount, currency, country_iso
├── variant_id → spree_variants
├── price_list_id → spree_price_lists
├── compare_at_amount, display_compare_at_amount
└── deleted_at
```

### Orders
```
spree_orders
├── number (prefixed ID), state (state machine: cart → address → delivery → payment → complete)
├── item_total, total, adjustment_total, included_tax_total
├── currency, email, channel, user_id → spree_users
├── store_id, market_id
├── billing_address_id, shipping_address_id → spree_addresses
├── token (guest cart token)
├── completed_at, canceled_at, deleted_at
├── private_metadata, public_metadata
└── has_many: spree_line_items, spree_adjustments, spree_payments, spree_shipments

spree_line_items
├── quantity, price, cost_price, currency
├── variant_id, product_id
├── order_id → spree_orders
├── private_metadata, public_metadata
└── has_many: spree_adjustments
```

### Users
```
spree_users
├── email, encrypted_password
├── reset_password_token, reset_password_sent_at
├── remember_created_at
├── sign_in_count, current_sign_in_at, last_sign_in_at
├── deleted_at
└── has_many: spree_orders, spree_addresses, spree_wishlists

spree_admin_users
├── Same Devise columns as spree_users
├── first_name, last_name
└── Included: Spree::AdminUserMethods
```

### Addresses
```
spree_addresses
├── firstname, lastname, company
├── address1, address2, city
├── zipcode, phone
├── state_id → spree_states, country_id → spree_countries
├── label (home, work), alternative_phone
├── latitude, longitude
└── user_id → spree_users (nullable)
```

### Payments
```
spree_payments
├── amount, state, payment_method_id
├── source_type, source_id (polymorphic)
├── order_id → spree_orders
├── response_code, avs_response
└── private_metadata, public_metadata

spree_payment_methods
├── type (STI: Gateway, Check, StoreCredit, etc.)
├── name, description, active, available_to_admin, available_to_users
├── preferences (JSONB), stores (JSONB)
└── deleted_at

spree_stripe_payment_intents
├── payment_intent_id, amount, currency
├── payment_id → spree_payments
└── order_id → spree_orders

spree_paypal_checkout_orders
├── paypal_order_id, status, payer_id
├── payment_id → spree_payments
└── order_id → spree_orders
```

### Shipping
```
spree_shipments
├── number (prefixed ID), state
├── cost, tracking, shipped_at
├── order_id → spree_orders, stock_location_id
├── shipping_method_id
└── private_metadata, public_metadata

spree_shipping_methods
├── name, admin_name, code
├── calculator_type (FlatRate, FlexiRate, etc.)
├── zones, tax_category_id
└── deleted_at

spree_shipping_rates
├── cost, selected
├── shipment_id → spree_shipments
├── shipping_method_id
└── tax_rate_id
```

### Inventory
```
spree_stock_items
├── count_on_hand, backorderable, track_inventory
├── variant_id → spree_variants, stock_location_id
└── private_metadata, public_metadata

spree_stock_locations
├── name, default, active, backorderable_default
└── deleted_at

spree_stock_movements
├── quantity, action (received, shipped, adjusted)
├── stock_item_id, originator (polymorphic)
```

### Categories (Taxons)
```
spree_taxonomies
├── name, position, store_id
├── private_metadata, public_metadata
└── has_many: spree_taxons

spree_taxons
├── name, description, permalink
├── parent_id, lft, rgt, depth (nested set)
├── taxonomy_id, position
├── meta_title, meta_description
├── icon_file_name, deleted_at
├── private_metadata, public_metadata
└── has_one: spree_taxon_translation (Mobility)
```

### Promotions & Discounts
```
spree_promotions
├── name, description, code
├── usage_limit, expires_at
├── match_policy (all/any), advertise
└── has_many: spree_promotion_rules, spree_promotion_actions

spree_coupon_codes
├── code, promotion_id
├── usage_count, usage_limit
└── deleted_at
```

### Gift Cards
```
spree_gift_cards
├── code, current_value, original_value
├── variant_id, line_item_id
├── purchaser_id, redeemer_id
└── deleted_at
```

### Multi-Store & Multi-Market
```
spree_stores
├── name, url, code, default, default_currency
├── supported_currencies, supported_locales
├── meta_title, meta_description, seo_robots
├── facebook, twitter, instagram
├── logo_file_name, customer_support_email
├── custom_code_head, custom_code_body_start, custom_code_body_end
└── has_one: spree_store_translation (Mobility)

spree_markets
├── name, code, default_currency, default_locale
└── has_many: spree_market_countries, spree_market_products

spree_market_countries
├── market_id, country_id, default
└── display_name, position
```

## Webhooks & API Keys
```
spree_webhook_endpoints
├── url, secret, active
├── events (filter), subscriptions
├── api_key_id → spree_api_keys
└── deleted_at

spree_webhook_deliveries
├── webhook_endpoint_id, event, status
├── request_body (JSONB), response_body, response_code
└── created_at

spree_api_keys
├── token, type (publishable/secret)
├── user_id → spree_users, admin_user_id → spree_admin_users
└── deleted_at
```

## Custom Metadata (Shopify-like)
```
spree_metafield_definitions
├── namespace, key, value_type
└── owner_class (Product, Variant, Order, etc.)

spree_metafields
├── metafield_definition_id
├── resource_type, resource_id (polymorphic)
├── string_value, integer_value, boolean_value, json_value
```

## Extensions
```
spree_integrations (third-party integrations)
spree_invitations (admin invitations)
spree_digitals / spree_digital_links (digital products)
spree_exports / spree_imports (data import/export)
spree_reports (analytics reports)
spree_customer_groups (customer segmentation)
spree_gateway_customers (payment gateway profiles)
spree_refresh_tokens (JWT refresh)
```

## Common Column Patterns

| Pattern | Tables |
|---------|--------|
| `deleted_at` | Most major tables (paranoid/soft delete) |
| `private_metadata` + `public_metadata` (JSONB) | orders, products, variants, line_items, shipments, payments, taxons, taxonomies, stock_items, stock_transfers, tax_rates, stores |
| `store_id` | products, orders, taxonomies |
| `position` | Variants, taxons, option_values, menu_items |
| `slug` / friendly_id | Products, taxons |
| `prefixed IDs` | Orders (R), Products (prod_), Variants (var_), Shipments (H), Payments (P), Taxons (T), Users (U), Addresses (A) |
