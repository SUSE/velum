source "https://rubygems.org"

gem "puma"
gem "rails", "4.2.10"

gem "jbuilder", "~> 2.5"
gem "jquery-rails"
gem "slim"
gem "font-awesome-rails"

# NOTE: this is no longer needed in Rails 5. See
# https://github.com/heroku/rails_stdout_logging#rails-5 for instructions on how
# to transition.
gem "rails_stdout_logging", group: [:development, :staging, :production]

gem "bcrypt", "~> 3.1.7"
gem "mysql2"

gem "gravatar_image_tag"
gem "devise"
gem "devise_ldap_authenticatable"
gem "net-ldap", require: "net/ldap"

gem "openid_connect"
gem "rake", "12.2.1"


group :assets do
  gem "sass-rails", "~> 5.0"
  gem "bootstrap-sass"
  gem "uglifier", ">= 1.3.0"
end

group :development, :test do
  gem "rspec-rails"
  gem "rubocop", "~> 0.51", require: false
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
