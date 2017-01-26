# frozen_string_literal: true
require "pharos/salt_api"

module Pharos
  # This class allows to interact with global salt actions
  class Salt
    include SaltApi

    # This method is the entrypoint of any Salt call. It will simply apply the
    # given function 'fun' with the given arguments 'arg' to the given target
    # machines.
    #
    # Returns two values:
    #   - The response object.
    #   - A hash containing the parsed JSON response.
    def self.call(tgt:, fun:, arg: nil)
      hsh = { tgt: tgt, fun: fun, client: "local" }
      hsh[:arg] = arg if arg

      res = perform_request(endpoint: "/", method: "post", data: hsh)
      [res, JSON.parse(res.body)]
    end

    # Returns the minions as discovered by salt.
    def self.minions
      res = perform_request(endpoint: "/minions", method: "get")
      JSON.parse(res.body)["return"].first
    end

    # Call the salt orchestration.
    def self.orchestrate
      res = perform_request(endpoint: "/run", method: "post",
                            data: { client: "runner_async",
                                    fun:    "state.orchestrate",
                                    kwargs: { mods: "orch.kubernetes" } })
      [res, JSON.parse(res.body)]
    end
  end
end
