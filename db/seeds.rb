# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the rails db:seed
# command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

def seed_development
  # nothing yet
end

def seed_production
  # nothing yet
end

case Rails.env
when "test", "development"
  seed_development
when "production"
  seed_production
end
