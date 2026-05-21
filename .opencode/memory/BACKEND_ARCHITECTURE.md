# Backend Architecture — Rails + Spree Commerce

## Application

- **Class:** `SpreeStarter::Application` (config/application.rb)
- **Framework:** Rails 8.1 (all frameworks enabled except test_unit)
- **Ruby:** 4.0.1
- **Database:** PostgreSQL 18
- **Job adapter:** Sidekiq (globally, set in application.rb)
- **Autoloading:** `lib/` is autoloaded (except assets/tasks); decorators auto-loaded via `app/**/*_decorator*.rb` pattern

## Routes (config/routes.rb)

```
/                       → Spree::Core::Engine (storefront)
/admin                  → Spree Admin Panel
/api/v3/store/          → Store API (public)
/api/v3/admin/          → Admin API (authenticated)
/sidekiq                → Sidekiq Web UI (admin-only, behind Devise auth)
/up                     → Health check (returns 200)
```

## Database (db/schema.rb — 100+ tables)

Key table groups:

| Domain | Tables |
|--------|--------|
| Products | spree_products, spree_variants, spree_prices, spree_option_types, spree_option_values, spree_properties, spree_product_properties, spree_prototypes |
| Orders | spree_orders, spree_line_items, spree_adjustments |
| Users | spree_users, spree_admin_users |
| Addresses | spree_addresses (with lat/lng) |
| Payments | spree_payments, spree_payment_methods, spree_payment_sources, spree_stripe_payment_intents, spree_adyen_payment_sessions, spree_paypal_checkout_orders |
| Shipping | spree_shipments, spree_shipping_methods, spree_shipping_rates |
| Inventory | spree_stock_items, spree_stock_locations, spree_stock_movements |
| Categories | spree_taxons (nested set with lft/rgt), spree_taxonomies |
| Discounts | spree_promotions, spree_promotion_rules, spree_promotion_actions, spree_coupon_codes |
| Gift Cards | spree_gift_cards, spree_gift_card_batches |
| Wishlists | spree_wishlists, spree_wished_items |
| Webhooks | spree_webhook_endpoints, spree_webhook_deliveries |
| Metadata | spree_metafields, spree_metafield_definitions (Shopify-like) |
| Multi-store | spree_stores (URLs, currencies, locales, SEO) |
| Multi-market | spree_markets, spree_market_countries |
| API Keys | spree_api_keys |
| Tags | spree_tags, spree_taggings |
| Translations | spree_product_translations, spree_taxon_translations (Mobility) |
| Policies | spree_policies (privacy, terms, etc.) |
| Search | PostgreSQL pg_trgm extension for fuzzy search |
| Auth | spree_refresh_tokens (JWT refresh), spree_invitations |
| Exports/Imports | spree_exports, spree_imports |

### Common Patterns Across Tables
- Soft deletes via `deleted_at` (paranoid pattern)
- `private_metadata` / `public_metadata` JSONB columns
- `store_id` for multi-tenancy
- Friendly ID slugs with locale support
- Mobility translation tables

## Initializers

### spree.rb (Central Config)
- `Spree.user_class = 'Spree::User'`
- `Spree.admin_user_class = 'Spree::AdminUser'`
- 18 named Sidekiq queues: default, spree_events, spree_exports, spree_images, spree_imports, spree_products, spree_reports, spree_variants, spree_taxons, spree_stock_location_stock_items, spree_coupon_codes, spree_addresses, spree_gift_cards, spree_webhooks, spree_payment_webhooks, spree_api_keys, spree_search
- Meilisearch auto-activated when `MEILISEARCH_URL` env var is set
- Permissions: `:default` → DefaultCustomer, `:admin` → SuperUser
- Dependencies block ready for service swapping (cart, checkout, etc.)
- All registries commented out (shipping_methods, payment_methods, tax_rates, stock_splitters, adjusters, promotions, taxon_rules, exports, reports)

### cors.rb
- Dynamic origin validation from `Spree::AllowedOrigin` database table
- Development: normalizes origins, caches 5 min
- Production: exact match, caches 5 min
- Only applies to `/api/v3/admin/*`

### sentry.rb
- Only on `production`/`staging` with `SENTRY_DSN`
- 50% transaction sampling
- Excludes: RoutingError, RecordNotFound, Sidekiq retries, S3 missing files

### devise.rb
- Email regex, password length (defaults)
- Separate customer and admin user models

## Models (app/models/)

### Spree::User (customer)
- Inherits: `Spree.base_class`
- Includes: UserAddress, UserMethods, UserPaymentSource
- Devise: database_authenticatable, registerable, recoverable, rememberable, validatable

### Spree::AdminUser
- Same structure as User
- Includes: AdminUserMethods

### ApplicationRecord
- Standard `primary_abstract_class` base

## Customization Patterns (Order of Preference)

### 1. Events & Subscribers (Preferred)
Use for side effects — syncing, notifications, cache updates.
```ruby
# app/subscribers/my_order_subscriber.rb
module MyApp
  class OrderSubscriber < Spree::Subscriber
    subscribes_to 'order.complete'
    def handle(event)
      # React to order completion
    end
  end
end
```
Register in `config/initializers/spree.rb`:
```ruby
Rails.application.config.after_initialize do
  Spree.subscribers << MyApp::OrderSubscriber
end
```

### 2. Service Swapping (Dependencies)
Override Spree services by inheriting and registering:
```ruby
Spree.dependencies do |dependencies|
  dependencies.cart_add_item_service = 'MyApp::Cart::AddItem'
end
```

### 3. Extensions
Add to Gemfile, bundle install, run install generator:
```bash
bin/rails g spree_stripe:install
```

### 4. Decorators (Last Resort)
Only for structural changes (associations, validations, scopes):
```ruby
# app/models/spree/product_decorator.rb
module Spree::ProductDecorator
  def self.prepended(base)
    base.has_many :reviews
    base.validates :custom_field, presence: true
  end
end
Spree::Product.prepend Spree::ProductDecorator
```

## Conventions (from CLAUDE.md)
- All custom code goes in `app/` — never modify gem source
- Use `Spree.user_class` / `Spree.admin_user_class` — never reference Spree::User directly
- All Spree models are `Spree::` namespaced
- Use `Spree::Current.store`, `Spree::Current.currency`, `Spree::Current.locale` for request context
- Prefixed IDs in API (e.g., `prod_86Rf07xd4z`) — never expose raw database IDs
- CanCanCan for authorization, Ransack for filtering, Pagy for pagination

## Sidekiq (config/sidekiq.yml)
- Concurrency: `SIDEKIQ_CONCURRENCY` env var (default 25)
- Priority-weighted queues (higher = more priority):
  - Weight 5: default, spree_imports, spree_payment_webhooks, mailers
  - Weight 3: spree_events, spree_exports, spree_images, spree_products, spree_reports, spree_variants, spree_taxons, spree_stock_location_stock_items, spree_coupon_codes, spree_addresses, spree_gift_cards, spree_webhooks, spree_api_keys, spree_search
  - Weight 1: active_storage_analysis, active_storage_purge

## Testing (spec/)
- Framework: RSpec + spree_dev_tools + FactoryBot + DatabaseCleaner + Capybara (headless Chrome)
- Only 1 existing test: `spec/models/spree/product_spec.rb`
- Test DB: spree_test

## What's Missing (Needs Custom Code)
- No app/subscribers/ — empty
- No app/services/ — empty
- No decorator files (`*_decorator*.rb`) — empty
- No custom controllers beyond ApplicationController
- No custom models beyond User/AdminUser
- No custom factories in spec/factories/
- No request/controller/feature specs beyond the single product spec
