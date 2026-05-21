# my-store

A [Spree Commerce](https://spreecommerce.org) project.

## Getting Started

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed and running

### Start the backend

```bash
cd my-store
npx spree dev
```

Wait for the services to be healthy, then open:

- **Admin Dashboard:** http://localhost:3000/admin
  - Email: `spree@example.com`
  - Password: `spree123`
- **Store API:** http://localhost:3000/api/v3/store

### Start the storefront

```bash
cd apps/storefront
npm install
npm run dev
```

Open http://localhost:3001

## Customizing the Backend

The `backend/` directory contains a full Rails application with Spree installed. By default, the project uses a prebuilt Docker image. To switch to building from your local backend:

```bash
npx spree eject
```

This rebuilds the Docker image from `backend/` and restarts services. You can then:

- **Add gems** to `backend/Gemfile`
- **Override models** with decorators in `backend/app/models/`
- **Add controllers** in `backend/app/controllers/`
- **Configure Spree** in `backend/config/initializers/spree.rb`
- **Add migrations** with `cd backend && bin/rails generate migration`

## Spree CLI

This project uses [`@spree/cli`](https://www.npmjs.com/package/@spree/cli) to manage the backend.

### Services

| Command | Description |
|---------|-------------|
| `spree dev` | Start backend services and stream logs |
| `spree stop` | Stop backend services |
| `spree update` | Pull latest Spree image and restart (runs migrations automatically) |
| `spree eject` | Switch from prebuilt image to building from `backend/` |
| `spree logs` | View web server logs |
| `spree logs worker` | View background jobs logs |
| `spree console` | Open Rails console |

### Data

| Command | Description |
|---------|-------------|
| `spree seed` | Seed the database |
| `spree sample-data` | Load sample products, categories, images |

### Users & API Keys

| Command | Description |
|---------|-------------|
| `spree user create` | Create an admin user |
| `spree api-key create` | Create a publishable or secret API key |
| `spree api-key list` | List all API keys |
| `spree api-key revoke <token>` | Revoke an API key |

## Learn More

- [Spree Documentation](https://docs.spreecommerce.org)
- [Store API Reference](https://docs.spreecommerce.org/api-reference/store)
- [Spree GitHub](https://github.com/spree/spree)
