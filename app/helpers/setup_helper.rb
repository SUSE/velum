# frozen_string_literal: true
require "yaml"

# SetupHelper contains all the setup view helpers.
module SetupHelper
  # https://www.iso.org/iso-3166-country-codes.html
  def country_codes
    YAML.load_file(Rails.root.join("config", "country_codes.yml"))["iso"][3166]["codes"]
        .to_a.map(&:reverse)
  end
end
