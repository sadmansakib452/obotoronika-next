Run the database seeding process for the Spree Commerce backend.

Steps:
1. Run `spree seed` to populate essential seed data (stores, default settings, shipping methods, payment methods, admin user)
2. Run `spree sample-data` to load sample products, categories, taxonomies, option types, properties, and product images
3. Verify by opening http://localhost:3000/admin and checking that products appear in the admin panel
4. Check http://localhost:3000/api/v3/store/products — verify the API returns products

Default admin credentials: spree@example.com / spree123

If you see errors:
- Ensure Docker services are running: `npm run dev`
- Wait for all services to be healthy (postgres, redis, meilisearch)
- If Meilisearch is running, run `spree seed` after it's healthy for search indexing
