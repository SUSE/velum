ENV["RAILS_ENV"] ||= "test"

require "spec_helper"
require File.expand_path("../../config/environment", __FILE__)
require "rspec/rails"
require "devise"
require "ffaker"
require "factory_girl_rails"

# Raise exception for pending migrations after reading the schema.
ActiveRecord::Migration.maintain_test_schema!

# All the configuration that is specific for a gem (or set of related gems) has
# been pushed into individual files inside the `spec/support` directory.
Dir[Rails.root.join("spec", "support", "**", "*.rb")].each { |f| require f }

RSpec.configure do |config|
  # If we want Capybara + DatabaseCleaner + Poltergeist to work correctly, we
  # have to just set this to false.
  config.fixture_path = File.expand_path("../fixtures/", __FILE__)
  config.use_transactional_fixtures = false

  config.include JsonSpecHelper, type: :controller

  config.infer_spec_type_from_file_location!
  config.include FactoryGirl::Syntax::Methods
  config.infer_base_class_for_anonymous_controllers = true
end

# Backport of Rails5 file fixture
def file_fixture(fixture_name)
  file_fixture_path = RSpec.configuration.fixture_path
  path = Pathname.new(File.join(file_fixture_path, fixture_name))

  if path.exist?
    path
  else
    msg = "the directory '#{file_fixture_path}' does not contain a file named '#{fixture_name}'"
    raise ArgumentError, msg
  end
end
