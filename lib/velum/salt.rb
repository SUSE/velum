# frozen_string_literal: true
require "velum/salt_api"

module Velum
  # This class allows to interact with global salt actions
  class Salt
    include SaltApi

    # This method is the entrypoint of any Salt call. It will simply apply the
    # given function 'action' with the given arguments 'arg' to the given targets.
    #
    # Returns two values:
    #   - The response object.
    #   - A hash containing the parsed JSON response.
    def self.call(action:, targets: "*", target_type: "glob", arg: nil)
      hsh = { tgt: targets, fun: action, expr_form: target_type, client: "local" }
      hsh[:arg] = arg if arg

      res = perform_request(endpoint: "/", method: "post", data: hsh)
      [res, JSON.parse(res.body)]
    end

    # Returns the update status of the different minions.
    def self.update_status(targets: "*")
      needed = []
      failed = []

      req_data = { tgt: targets, fun: "cache.grains", client: "runner" }
      minions = perform_request(endpoint: "/", method: "post", data: req_data)

      JSON.parse(minions.body)["return"].each do |key, _|
        key.each do |minion, data|
          needed.push(minion) if data.fetch("tx_update_reboot_needed", false)
          failed.push(minion) if data.fetch("tx_update_failed", false)
        end
      end
      [needed, failed]
    end

    # Returns the minions as discovered by salt.
    def self.minions
      res = perform_request(endpoint: "/minions", method: "get")
      JSON.parse(res.body)["return"].first
    end

    # Returns the minions that have not been accepted into the cluster
    def self.pending_minions
      res = perform_request(endpoint: "/", method: "post",
                            data: { client: "wheel",
                                    fun:    "key.list",
                                    match:  "all",
                                    tgt:    "ca" })
      JSON.parse(res.body)["return"].first["data"]["return"]["minions_pre"]
    end

    # Accepts a minion into the cluster
    def self.accept_minion(minion_id: "")
      res = perform_request(endpoint: "/", method: "post",
                            data: { client: "wheel",
                                    fun:    "key.accept",
                                    match:  minion_id,
                                    tgt:    "ca" })
      JSON.parse(res.body)["return"].first["data"]["return"]["minions"]
    end

    # Call the salt orchestration.
    def self.orchestrate
      res = perform_request(endpoint: "/run", method: "post",
                            data: { client: "runner_async",
                                    fun:    "state.orchestrate",
                                    mods:   "orch.kubernetes" })
      [res, JSON.parse(res.body)]
    end

    # Call the update orchestration
    def self.update_orchestration
      res = perform_request(endpoint: "/run", method: "post",
                            data: { client: "runner_async",
                                    fun:    "state.orchestrate",
                                    mods:   "orch.update" })
      [res, JSON.parse(res.body)]
    end

    # Returns the contents of the given file.
    def self.read_file(targets: "*", target_type: "glob", file: nil)
      _, data = Velum::Salt.call action:      "cmd.run",
                                 targets:     targets,
                                 target_type: target_type,
                                 arg:         "cat #{file}"

      data["return"].map do |el|
        val = el.values.first

        # TODO: improve error handling...
        val && val.include?("No such file or directory") ? nil : val
      end
    end
  end
end
