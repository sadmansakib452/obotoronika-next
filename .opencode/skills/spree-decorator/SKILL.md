---
name: spree-decorator
description: When and how to use decorators, subscribers, and service swapping in Spree Commerce. Load when modifying or extending Spree models, adding callbacks, or changing business logic.
license: MIT
compatibility: opencode
metadata:
  audience: backend-developers
  workflow: spree-customization
---

# Spree Decorator & Customization Patterns

## When to Use What (Priority Order)

This is the MANDATORY customization order for Spree Commerce. Never skip to decorators without considering the options above.

### 1. Events & Subscribers (PREFERRED)

**Use when:** You need to react to something that happened (side effects).
**Examples:** Send email on order complete, sync to external service, update analytics, clear caches.

```ruby
# app/subscribers/my_order_subscriber.rb
module MyApp
  class OrderSubscriber < Spree::Subscriber
    subscribes_to 'order.complete'

    def handle(event)
      order = Spree::Order.find_by_prefix_id(event.payload['id'])
      # Do side effect work here
    end
  end
end

# Register in config/initializers/spree.rb:
Rails.application.config.after_initialize do
  Spree.subscribers << MyApp::OrderSubscriber
end
```

**Available events:** `order.complete`, `order.canceled`, `order.shipped`, `user.signup`, `product.created`, `variant.updated`, `payment.captured`, `shipment.ready`, and many more from Spree core.

### 2. Service Swapping (Dependencies)

**Use when:** You need to CHANGE how something works (business logic).
**Examples:** Custom cart add logic, different checkout flow, custom pricing.

```ruby
# app/services/my_app/cart/add_item.rb
module MyApp
  module Cart
    class AddItem < Spree::Cart::AddItem
      def call(order:, variant:, quantity: nil, **options)
        ApplicationRecord.transaction do
          run :add_to_line_item
          run :my_custom_validation_step
          run Spree.cart_recalculate_service
        end
      end

      def my_custom_validation_step
        # Custom logic
      end
    end
  end
end

# Register in config/initializers/spree.rb:
Spree.dependencies do |dependencies|
  dependencies.cart_add_item_service = 'MyApp::Cart::AddItem'
end
```

**Available dependencies to swap:**
- `cart_add_item_service`, `cart_remove_item_service`, `cart_update_item_service`
- `cart_create_service`, `cart_recalculate_service`
- `checkout_next_service`, `order_merger_service`
- `coupon_code_handler`
- Many more — check Spree docs

### 3. Extensions

**Use when:** A pre-built gem exists for what you need.
**Examples:** Payment gateways, shipping integrations, search providers.

```ruby
# Gemfile
gem 'spree_stripe'
# Then:
# bundle install
# bin/rails g spree_stripe:install
```

Existing extensions in this project: `spree_i18n`, `spree_stripe`, `spree_adyen`, `spree_paypal_checkout`.

### 4. Decorators (LAST RESORT)

**Use ONLY when:** You need structural model changes (associations, validations, scopes).
**NEVER use for:** Callbacks, side effects (use subscribers), business logic changes (use service swapping).

```ruby
# app/models/spree/product_decorator.rb
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

**Auto-loading:** The application auto-loads all `app/**/*_decorator*.rb` files. File must contain `decorator` in its name.

## Why This Order Matters

- Decorators couple your code directly to Spree internals (class names, method signatures)
- When Spree upgrades, decorators are most likely to break
- Subscribers and service swapping work with Spree's public API, which is more stable
- Subscribers are the SAFEST — they only react to events, never change internal flow

## Rules to NEVER Break

1. Never modify gem source code (`backend/vendor/bundle/` or installed gem files)
2. Use `Spree.user_class` / `Spree.admin_user_class` instead of hardcoded class names
3. All custom code goes in `backend/app/`
4. Use `prepend` (not `include` or monkey-patching) for decorators
