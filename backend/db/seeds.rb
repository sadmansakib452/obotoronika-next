# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

Spree::Core::Engine.load_seed if defined?(Spree::Core)

# Set default store name to obotoronika (use .first because .default is broken during seed)
store = Spree::Store.first
if store
  store.update_columns(
    name: "obotoronika",
    seo_title: "obotoronika",
    meta_description: "obotoronika — your trusted e-commerce platform.",
  )
end

# Update default admin credentials
admin = Spree::AdminUser.first
if admin
  admin.email = "admin@obotoronika.com"
  admin.password = "admin123"
  admin.password_confirmation = "admin123"
  admin.save!
end
