# frozen_string_literal: true
require "yaml"

# SetupHelper contains all the setup view helpers.
module SetupHelper
  # https://www.iso.org/iso-3166-country-codes.html
  # taken from https://coderwall.com/p/xww5mq/two-letter-country-code-regex
  def country_code_regex
    YAML.load_file(Rails.root.join("config", "country_codes.yml"))["iso"][3166]["regex"]
  end
end
