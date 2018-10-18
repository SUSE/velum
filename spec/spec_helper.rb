require "simplecov"
require "webmock/rspec"
require "vcr"

SimpleCov.start("rails") do
  minimum_coverage 100
  coverage_dir "public/coverage"
end

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
  # Don't try to playback under the RFC6761 .invalid TLD (should always return NXDOMAIN)
  c.ignore_request do |request|
    URI(request.uri).host.end_with?(".invalid")
  end
  # Also ignore the .0 IP in RFC5737 test-net-1, and an invalid IP address
  c.ignore_hosts "192.0.2.0"
  c.ignore_hosts "1.2.3.256"

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

  config.before do
    allow(Rails.application.secrets).to receive(:internal_api).and_return(
      username: "test",
      password: "test"
    )
  end

  config.before do
    Minion.find_or_create_by(minion_id: "admin") do |minion|
      minion.fqdn = "admin"
      minion.role = :admin
      minion.highstate = :applied
    end
  end

  config.before :all do
    ENV["VELUM_SALT_HOST"] ||= "127.0.0.1"
    ENV["VELUM_SALT_PORT"] ||= "8000"
  end

  config.order = :random

  config.fail_fast = ENV["RSPEC_FAIL_FAST"] == "true"
end
