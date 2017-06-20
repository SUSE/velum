
# frozen_string_literal: true
require "capybara/rails"
require "capybara/rspec"
require "capybara/poltergeist"

Capybara.register_driver :poltergeist do |app|
  options = {
    timeout:           3.minutes,
    js_errors:         false,
    phantomjs_options: [
      "--proxy-type=none",
      "--load-images=no"
    ]
  }
  # NOTE: uncomment the line below to get more info on the current run.
  # options[:debug] = true
  Capybara::Poltergeist::Driver.new(app, options)
end

Capybara.javascript_driver = :poltergeist

Capybara.configure do |config|
  config.javascript_driver = :poltergeist
  config.default_max_wait_time = 5
  config.match = :one
  config.exact_options = true
  config.ignore_hidden_elements = true
  config.visible_text_only = true
  config.default_selector = :css
end
