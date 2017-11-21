# frozen_string_literal: true

source "https://rubygems.org"

gem "puma"
gem "rails", "4.2.7.1"

gem "jbuilder", "~> 2.5"
gem "jquery-rails"
gem "slim"
gem "font-awesome-rails"

# NOTE: this is no longer needed in Rails 5. See
# https://github.com/heroku/rails_stdout_logging#rails-5 for instructions on how
# to transition.
gem "rails_stdout_logging", group: %i(development staging production)

gem "bcrypt", "~> 3.1.7"
gem "mysql2"

gem "gravatar_image_tag"
gem "devise"
gem "kubeclient", "~> 2.3.0"
gem "devise_ldap_authenticatable"
gem "net-ldap", require: "net/ldap"

gem "openid_connect"

# Assets group.
#
# Do not set it or set it to no when precompiling the assets.
#
# IGNORE_ASSETS="no" RAILS_ENV=production bundle exec rake assets:precompile
#
# Set IGNORE_ASSETS to YES when creating the Gemfile.lock for
# production after having precompiled the assets
# run:
#
# IGNORE_ASSETS=yes bundle list

unless ENV["IGNORE_ASSETS"] == "yes"
  gem "sass-rails", "~> 5.0"
  gem "bootstrap-sass"
  gem "uglifier", ">= 1.3.0"
end

# In order to create the Gemfile.lock required for packaging
# meaning that it should contain only the production packages
# run:
#
# PACKAGING=yes bundle list

unless ENV["PACKAGING"] && ENV["PACKAGING"] == "yes"
  group :development, :test do
    gem "rspec-rails"
    gem "rubocop", "~> 0.49", require: false
    gem "brakeman", require: false
    gem "database_cleaner"
    gem "pry"
    gem "pry-nav"
  end

  group :test do
    gem "shoulda"
    gem "vcr"
    gem "webmock", require: false
    gem "simplecov", require: false
    gem "capybara", "~> 2.14.3"
    gem "poltergeist", "~> 1.15.0", require: false
    gem "json-schema"
    gem "timecop"
    gem "codeclimate-test-reporter", "~> 1.0.0", require: nil
    gem "factory_girl_rails"
    gem "ffaker"
    gem "rubocop-rspec"
  end
end
