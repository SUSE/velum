# frozen_string_literal: true
require "simplecov"
require "webmock/rspec"
require "vcr"

SimpleCov.minimum_coverage 100
SimpleCov.start "rails"

VCR.configure do |c|
  c.cassette_library_dir = "spec/vcr_cassettes"
  c.hook_into :webmock
  c.ignore_localhost = false

  # So code coverage reports can be submitted to codeclimate.com
  c.ignore_hosts "codeclimate.com"
  # This is a test request used by Capybara to check if the server has finished
  # booting.
  # https://devmaheshwari.wordpress.com/2013/09/19/using-webmock-and-vcr-with-cucumber/
  c.ignore_request do |request|
    request.uri =~ /__identify__/
  end

  # To debug when a VCR goes wrong.
  # c.debug_logger = $stdout
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.before :all do
    ENV["VELUM_SALT_HOST"] ||= "127.0.0.1"
    ENV["VELUM_SALT_PORT"] ||= "8000"
  end

  config.order = :random
end
