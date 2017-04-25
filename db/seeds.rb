# frozen_string_literal: true
# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the rails db:seed
# command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

def seed_development
  User.create email: "test@test.com", password: "password"
end

def seed_production
  # Nothing yet
end

case Rails.env
when "development", "test"
  seed_development
when "production"
  seed_production
end
