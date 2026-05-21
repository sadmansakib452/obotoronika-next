# Customization Guide — Extending the Spree Codebase

## Backend Customization (Rails)

### Priority Order (MUST follow this)

1. **Events & Subscribers** — for side effects
2. **Service Swapping** — for business logic changes
3. **Extensions** — for new features via gems
4. **Decorators** — last resort, only for structural changes

### 1. Events & Subscribers (Preferred)

**Purpose:** React to model changes without touching Spree source code.
**Use for:** Syncing to external services, sending notifications, updating caches, analytics tracking.

**Where to create:** `backend/app/subscribers/`

```ruby
# Example: app/subscribers/my_order_subscriber.rb
module MyApp
  class OrderSubscriber < Spree::Subscriber
    subscribes_to 'order.complete'
    def handle(event)
      order = Spree::Order.find_by_prefix_id(event.payload['id'])
      ExternalService.notify(order)
    end
  end
end
```

**Register in** `config/initializers/spree.rb`:
```ruby
Rails.application.config.after_initialize do
  Spree.subscribers << MyApp::OrderSubscriber
end
```

**Available events:** order.complete, order.canceled, order.shipped, user.signup, product.created, variant.updated, payment.captured, shipment.ready, etc.

### 2. Service Swapping (Dependencies)

**Purpose:** Replace Spree's internal services with custom implementations.
**Use for:** Changing business logic flows (cart operations, checkout steps, pricing).

**Where to create:** `backend/app/services/`

```ruby
# Example: app/services/my_app/cart/add_item.rb
module MyApp
  module Cart
    class AddItem < Spree::Cart::AddItem
      def call(order:, variant:, quantity: nil, **options)
        ApplicationRecord.transaction do
          run :add_to_line_item
          run :my_custom_step
          run Spree.cart_recalculate_service
        end
      end

      def my_custom_step
        # Custom logic here
      end
    end
  end
end
```

**Register in** `config/initializers/spree.rb`:
```ruby
Spree.dependencies do |dependencies|
  dependencies.cart_add_item_service = 'MyApp::Cart::AddItem'
end
```

**Available dependencies:** cart_add_item_service, cart_remove_item_service, cart_update_item_service, cart_create_service, cart_recalculate_service, checkout_next_service, order_merger_service, coupon_code_handler, etc.

### 3. Extensions

**Purpose:** Add pre-built features via gems.
**Use for:** Payment gateways, shipping integrations, search providers, CMS features.

**How to add:**
```ruby
# Gemfile
gem 'spree_some_extension'
```

```bash
bundle install
bin/rails g spree_some_extension:install
```

**Existing extensions in project:** spree_i18n, spree_stripe, spree_adyen, spree_paypal_checkout

### 4. Decorators (Last Resort)

**Purpose:** Modify Spree model structure (associations, validations, scopes).
**When to use:** Only when no other option exists. Avoid for callbacks and side effects (use subscribers instead).

**Where to create:** `backend/app/models/spree/` (autoloaded via `*_decorator*.rb` pattern)

```ruby
# Example: app/models/spree/product_decorator.rb
module Spree
  module ProductDecorator
    def self.prepended(base)
      base.has_many :reviews, class_name: 'MyApp::Review', dependent: :destroy
      base.validates :custom_field, presence: true
      base.scope :featured, -> { where(featured: true) }
    end
  end

  Product.prepend ProductDecorator
end
```

**Auto-loading:** Config in `application.rb` loads all `app/**/*_decorator*.rb` files at prepare time.

### Adding Migrations

```bash
cd backend
bin/rails generate migration AddCustomFieldToProducts custom_field:string
bin/rails db:migrate
```

### Adding Controllers

```ruby
# backend/app/controllers/api/my_custom_controller.rb
module Api
  class MyCustomController < Spree::Api::V3::BaseController
    def index
      # Custom endpoint
    end
  end
end
```

### Adding Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount Spree::Core::Engine, at: '/'

  namespace :api do
    namespace :v3 do
      namespace :store do
        resources :my_custom, only: [:index]
      end
    end
  end
end
```

### Spree Configuration

All configuration in `config/initializers/spree.rb`:

- Preferences: `Spree.config { |config| config.my_setting = value }`
- Dependencies: `Spree.dependencies { |d| d.service_name = 'MyService' }`
- Permissions: `Spree::PermissionSets` for role-based access
- Registries: Shipping methods, payment methods, calculators, promotions, taxon rules, exports, reports

### Testing

```bash
# All tests
bundle exec rspec

# Specific file
bundle exec rspec spec/models/spree/product_spec.rb

# Specific directory
bundle exec rspec spec/models/
```

FactoryBot is pre-configured via spree_dev_tools. Custom factories go in `spec/factories/`.

## Storefront Customization (Next.js)

### Adding a New Page

1. Create page file: `apps/storefront/src/app/[country]/[locale]/(storefront)/my-page/page.tsx`
2. Server component:
```typescript
export default async function MyPage() {
  const data = await fetchData();
  return <MyComponent data={data} />;
}
```
3. If interactive, create a client component in `src/components/`
4. Add i18n messages in `messages/en.json` (and other locales)
5. Generate metadata using `src/lib/metadata/` patterns

### Adding a New Server Action

1. Create file: `apps/storefront/src/lib/data/my-feature.ts`
2. Use `"use server"` directive
3. Wrap with `actionResult()` or `withFallback()`:
```typescript
"use server";
import { getClient } from "@/lib/spree";
import { actionResult } from "./utils";

export async function myAction(params) {
  return actionResult(async () => {
    const client = await getClient();
    const result = await client.someResource.method(params);
    return { data: result };
  }, "Failed to perform action");
}
```
4. For read-heavy data, add `"use cache"`:
```typescript
export async function cachedMyData(params) {
  "use cache: remote";
  cacheLife("tenMinutes");
  cacheTag("my-data");
  // ...
}
```

### Adding a New Context

1. Create: `apps/storefront/src/contexts/MyContext.tsx`
2. Export provider and hook:
```typescript
"use client";
const MyContext = createContext<MyContextType | null>(null);

export function MyProvider({ children, initialData }: Props) {
  // State management
  return <MyContext.Provider value={value}>{children}</MyContext.Provider>;
}

export function useMyContext() {
  const ctx = useContext(MyContext);
  if (!ctx) throw new Error("useMyContext must be used within MyProvider");
  return ctx;
}
```
3. Add provider to `src/app/[country]/[locale]/layout.tsx` nesting order

### Adding a New Component

1. Create in `src/components/` (or subdirectory)
2. Server Component (default):
```typescript
// No "use client" directive
export async function MyServerComponent() {
  const data = await fetchData();
  return <div>{data.name}</div>;
}
```
3. Client Component (interactive):
```typescript
"use client";
import { useState } from "react";
export function MyClientComponent() {
  const [state, setState] = useState();
  return <button onClick={() => setState()}>Click</button>;
}
```

### Adding Payment Methods

The checkout already supports Stripe, Adyen, PayPal, and Direct (Check/COD). To add a new gateway:
1. Install the Spree extension gem in `backend/Gemfile`
2. Configure in `config/initializers/spree.rb`: `Spree.payment_methods << MyNewGateway`
3. Create storefront UI component in `src/components/checkout/`
4. Add to `PaymentSection.tsx` gateway selection
5. Create/complete payment session via `src/lib/data/payment.ts`

### Adding a New Locale

1. Create translation file: `messages/XX.json` (copy from `messages/en.json`)
2. Add locale to `src/i18n/request.ts` supported locales array
3. Add locale to backend store settings (admin panel)

### Code Quality

```bash
cd apps/storefront
npm run check         # Biome lint + format check
npm run format        # Auto-format
npm run test          # Vitest
npm run test:watch    # Vitest in watch mode
```

## Common Patterns to Follow

| Task | Backend Pattern | Storefront Pattern |
|------|----------------|-------------------|
| Side effect | Subscriber | Server Action |
| Business logic | Service swap | Server Action |
| UI component | N/A | Server Component (default) / Client Component (interactive) |
| Data fetching | ActiveRecord | "use server" + getClient() |
| Caching | Rails cache | "use cache" + cacheTag |
| Auth | CanCanCan + Devise | httpOnly cookies + JWT refresh |
| i18n | Mobility + spree_i18n | next-intl + static messages |
| Testing | RSpec + FactoryBot | Vitest + React Testing Library |
