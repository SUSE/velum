# frozen_string_literal: true
source "https://rubygems.org"

gem "listen"
gem "puma", "~> 3.0"
gem "rails", "~> 5.0.0"

gem "jbuilder", "~> 2.5"
gem "jquery-rails"
gem "therubyracer", platforms: :ruby
gem "slim"
gem "font-awesome-rails"
gem "rails_stdout_logging", group: [:development, :staging, :production]

gem "bcrypt", "~> 3.1.7"
gem "mysql2"

gem "gravatar_image_tag"
gem "devise"
gem "kubeclient", "~> 2.3.0"

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

unless ENV["PHAROS_IGNORE_ASSETS"] == "yes"
  gem "sass-rails", "~> 5.0"
  gem "bootstrap-sass"
  gem "uglifier", ">= 1.3.0"
  gem "jquery-turbolinks"
  gem "turbolinks"
end

# In order to create the Gemfile.lock required for packaging
# meaning that it should contain only the production packages
# run:
#
# PACKAGING=yes bundle list

unless ENV["PACKAGING"] && ENV["PACKAGING"] == "yes"
  group :development, :test do
    gem "rspec-rails"
    gem "rubocop", "~> 0.46", require: false
    gem "brakeman", require: false
    gem "database_cleaner"
  end

  group :test do
    gem "shoulda"
    gem "vcr"
    gem "webmock", require: false
    gem "simplecov", require: false
    gem "capybara"
    gem "poltergeist", require: false
    gem "json-schema"
    gem "timecop"
    gem "codeclimate-test-reporter", "~> 1.0.0", require: nil
    gem "factory_girl_rails"
    gem "ffaker"
  end
end
