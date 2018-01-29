require_relative "boot"

require "rails/all"

bundler_groups = [:default, Rails.env]
if ENV["INCLUDE_ASSETS_GROUP"] == "yes" || Rails.env.test? || Rails.env.development?
  bundler_groups << :assets
end

Bundler.require(*bundler_groups)

module Velum
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
