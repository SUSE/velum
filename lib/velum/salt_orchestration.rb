# frozen_string_literal: true
require "velum/salt_api"

module Velum
  # This class represents a salt orchestration
  class SaltOrchestration
    include SaltApi

    attr_accessor :orchestration

    # Initializes a new salt orchestration backend matching orchestration
    def initialize(orchestration:)
      @orchestration = orchestration
    end

    # Return information for this orchestration
    def info
      res = perform_request(endpoint: "/jobs/#{@orchestration.jid}", method: "get")
      JSON.parse(res.body)
    end
  end
end
