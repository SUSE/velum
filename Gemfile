source "https://rubygems.org"

gem "puma", "~> 3.11"
gem "rails", "~> 4.2.10"

gem "rake", "~> 12.2"
gem "minitest", "~> 5.10"

gem "jbuilder", "~> 2.5"
gem "jquery-rails", "~> 4.3"
gem "slim", "~> 3.0"
gem "font-awesome-rails", "~> 4.7"

# NOTE: this is no longer needed in Rails 5. See
# https://github.com/heroku/rails_stdout_logging#rails-5 for instructions on how
# to transition.
gem "rails_stdout_logging", "~> 0.0.5", group: [:development, :staging, :production]

gem "bcrypt", "~> 3.1.7"
gem "mysql2", "~> 0.4.10"

gem "gravatar_image_tag", "~> 1.2.0"
gem "devise", ">= 4.3"
gem "devise_ldap_authenticatable", "~> 0.8"
gem "net-ldap", "~> 0.11", require: "net/ldap"

gem "openid_connect", "~> 1.1"

group :assets do
  gem "sass-rails", "~> 5.0"
  gem "bootstrap-sass", "~> 3.3.7"
  gem "uglifier", "~> 4.1"
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
