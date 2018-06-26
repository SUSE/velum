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
  config.fixture_path = File.expand_path("../fixtures/", __FILE__)
  # If we want Capybara + DatabaseCleaner + Poltergeist to work correctly, we
  # have to just set this to false.
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

# Create a new file in the fixture directory.
#
# @param content [String] The content of the new file in string format
# @param full_path [Boolean] True if the full path should be returned, otherwise
# will return only the filename.
#
# @return The name of the new fixture created or the full_path if full_path is
# set to true.
def to_fixture_file(content, full_path: false)
  file_fixture_path = RSpec.configuration.fixture_path
  Tempfile.open("test_fixture", file_fixture_path) do |file|
    file.write(content)
    file.close
    if full_path
      file.path
    else
      File.basename(file)
    end
  end
end
