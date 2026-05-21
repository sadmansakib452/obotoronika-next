---
name: testing
description: Testing conventions for both backend (RSpec) and storefront (Vitest). Test coverage rules, file naming, mocking patterns, and test workflow. Load when writing or running tests.
license: MIT
compatibility: opencode
metadata:
  audience: all-developers
  workflow: testing
---

# Testing Conventions

## Backend Testing (RSpec)

### Setup
```bash
# Full suite
bundle exec rspec

# Specific directory
bundle exec rspec spec/models/

# Specific file
bundle exec rspec spec/models/spree/product_spec.rb

# Specific test (line number)
bundle exec rspec spec/models/spree/product_spec.rb:15
```

### File Naming
- Model specs: `spec/models/spree/product_spec.rb`
- Service specs: `spec/services/my_app/cart/add_item_spec.rb`
- Subscriber specs: `spec/subscribers/my_order_subscriber_spec.rb`
- Request specs: `spec/requests/api/products_spec.rb`
- Decorator specs: `spec/models/spree/product_decorator_spec.rb`

### Test Structure
```ruby
require "rails_helper"

RSpec.describe Spree::Product, type: :model do
  subject { build(:product) }

  # Happy path
  it "is valid with valid attributes" do
    expect(subject).to be_valid
  end

  # Error cases
  it "is invalid without a name" do
    subject.name = nil
    expect(subject).not_to be_valid
    expect(subject.errors[:name]).to include("can't be blank")
  end

  # Edge cases
  it "handles empty string for description" do
    subject.description = ""
    expect(subject).to be_valid
  end
end
```

### Coverage Rules
- **Every service method:** 2-3 test cases minimum
- **Happy path:** Assert the expected outcome
- **Error cases:** Invalid inputs, missing data, auth failures
- **Edge cases:** Empty strings, nil, boundary values, large inputs
- **Decorators:** Test associations, validations, scopes
- **Subscribers:** Test the handler logic (mock the event payload)

### FactoryBot
Spree's factories are available via `spree_dev_tools`. Use them:
```ruby
let(:product) { create(:product) }
let(:order) { create(:completed_order_with_totals) }
let(:user) { create(:user) }
```

Custom factories go in `spec/factories/`:
```ruby
# spec/factories/reviews.rb
FactoryBot.define do
  factory :review do
    association :product, factory: :product
    association :user, factory: :user
    rating { 5 }
    body { "Great product!" }
    approved { true }
  end
end
```

### Database Cleaner
Pre-configured with transaction strategy. Each test rolls back automatically.

### Authentication in Tests
```ruby
# Sign in as user
sign_in(user)

# Sign in as admin
sign_in(admin_user)

# Make API request with auth
get "/api/v3/store/products", headers: auth_headers(user)
```

---

## Storefront Testing (Vitest + React Testing Library)

### Setup
```bash
# Full suite
npm run test

# Watch mode
npm run test:watch
```

### File Naming
- Server actions: `src/lib/data/__tests__/cart.test.ts`
- Components: `src/components/products/__tests__/ProductCard.test.tsx`
- Contexts: `src/contexts/__tests__/CartContext.test.tsx`
- Pages: `src/app/*/__tests__/page.test.tsx`

### Mocking SDK (Server Action Tests)
```typescript
import { vi, describe, it, expect, beforeEach } from "vitest";

vi.mock("@/lib/spree");

describe("getProducts", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("returns products on success", async () => {
    const mockProducts = {
      data: [
        { id: "prod_1", attributes: { name: "Test Product" } },
      ],
      pagination: { current_page: 1, total_pages: 1 },
    };

    const client = await getClient();
    (client as any).products = {
      list: vi.fn().mockResolvedValue(mockProducts),
    };

    const result = await getProducts({ per_page: 12 });
    expect(result.success).toBe(true);
    expect(result.data.data).toHaveLength(1);
  });

  it("returns error on failure", async () => {
    const client = await getClient();
    (client as any).products = {
      list: vi.fn().mockRejectedValue(new Error("Network error")),
    };

    const result = await getProducts({ per_page: 12 });
    expect(result.success).toBe(false);
    expect(result.error).toBeDefined();
  });
});
```

### Component Tests (React Testing Library)
```typescript
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { ProductCard } from "../ProductCard";

describe("ProductCard", () => {
  const product = {
    id: "prod_1",
    attributes: {
      name: "Test Product",
      price: { amount: "29.99", currency: "USD" },
      images: [{ url: "/test.jpg", alt: "Test" }],
    },
  };

  it("renders product name and price", () => {
    render(<ProductCard product={product} basePath="/us/en" />);
    expect(screen.getByText("Test Product")).toBeInTheDocument();
    expect(screen.getByText("$29.99")).toBeInTheDocument();
  });

  it("calls onClick when add to cart button clicked", async () => {
    const user = userEvent.setup();
    const onAddToCart = vi.fn();

    render(<ProductCard product={product} basePath="/us/en" onAddToCart={onAddToCart} />);
    await user.click(screen.getByRole("button", { name: /add to cart/i }));

    expect(onAddToCart).toHaveBeenCalledWith("prod_1");
  });
});
```

### Coverage Rules
- **Server actions:** Happy path + error case per action
- **Components:** Renders correctly + user interaction works
- **Edge cases:** Empty data, null values, boundary inputs
- **Error handling:** Components gracefully handle error states

---

## Test Workflow

1. Write tests BEFORE or alongside implementation
2. Run tests after each step
3. All tests MUST pass before declaring step complete
4. Fix any failures immediately — don't accumulate
5. Run full suite before presenting to user:
   - Backend: `bundle exec rspec`
   - Storefront: `npm run check && npm run test`
