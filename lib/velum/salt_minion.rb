# frozen_string_literal: true
require "velum/salt_api"

module Velum
  # This class represents a salt minion
  class SaltMinion
    include SaltApi

    attr_accessor :minion

    ROLES_MAP = {
      master: ["kube-master"],
      worker: ["kube-minion"]
    }.freeze

    # Initializes a new salt minion backend matching minion
    def initialize(minion:)
      @minion = minion
    end

    # Return information for this minion.
    def info
      res = perform_request(endpoint: "/minions/#{@minion.minion_id}", method: "get")
      JSON.parse(res.body)["return"].first[@minion.minion_id]
    end

    # Check if this minion has any role assigned.
    def roles?
      !info["roles"].blank?
    end

    # Assign role to this minion.
    def assign_role
      set_grain key: "roles", val: ROLES_MAP[@minion.role.to_sym]
      true
    end

    protected

    # Appends a grain with key and val to this minion.
    def set_grain(key:, val:)
      perform_request(endpoint: "/minions",
                      method:   "post",
                      data:     {
                        client: "local",
                        tgt:    @minion.minion_id,
                        fun:    "grains.setval",
                        kwarg:  { key: key, val: val }
                      })
      [key, val]
    end
  end
end
