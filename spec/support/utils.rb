# frozen_string_literal: true
# A simple module containing some utility methods.
module Utils
  # Stubs the ::Velum::Salt.update_status method with the given data.
  def setup_stubbed_update_status!(stubbed: [[], []])
    allow(::Velum::Salt).to receive(:update_status).and_return(stubbed)
  end
end

RSpec.configure { |config| config.include Utils }
