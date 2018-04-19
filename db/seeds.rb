# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the rails db:seed
# command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

def find_or_create_admin_node
  Minion.find_or_create_by(minion_id: "admin") do |minion|
    minion.fqdn = "admin"
    minion.role = :admin
    minion.highstate = :applied
  end
end

def seed_development
  find_or_create_admin_node
end

def seed_production
  Registry.where(name: "SUSE").first_or_initialize.tap do |r|
    r.url = "https://registry.suse.com"
    r.save
  end
  find_or_create_admin_node
end

case Rails.env
when "development"
  seed_development
when "production"
  seed_production
end
