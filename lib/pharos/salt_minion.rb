# frozen_string_literal: true
require "pharos/salt_api"

module Pharos
  # This class represents a salt minion
  class SaltMinion
    include SaltApi

    attr_accessor :minion_id

    ROLES_MAP = {
      master: ["kube-master", "etcd"],
      minion: ["kube-minion"]
    }.freeze

    # Initializes a new salt minion identified by mid.
    def initialize(minion_id:)
      @minion_id = minion_id
    end

    # Return information for this minion.
    def info
      res = perform_request(endpoint: "/minions/#{@minion_id}", method: "get")
      JSON.parse(res.body)["return"].first[@minion_id]
    end

    # Check if this minion has any role assigned.
    def roles?
      !info["roles"].blank?
    end

    # Assign role to this minion.
    def assign_role(role)
      append_grain key: "roles", val: ROLES_MAP[role]

      role
    end

    protected

    # Appends a grain with key and val to this minion.
    def append_grain(key:, val:)
      perform_request(endpoint: "/minions",
                      method:   "post",
                      data:     {
                        client: "local",
                        tgt:    @minion_id,
                        fun:    "grains.append",
                        kwarg:  { key: key, val: val }
                      })
      [key, val]
    end
  end
end
