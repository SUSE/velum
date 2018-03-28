require "velum/salt_api"
require "securerandom"

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

    # Trigger salt-cloud to construct a cluster
    def self.build_cloud_cluster(count)
      instance_names = (1..count).collect { "caasp-node-" + SecureRandom.hex(4) }
      instance_names.collect do |instance_name|
        perform_request(
          endpoint: "/",
          method:   "post",
          data:     {
            client: "local_async",
            tgt:    "admin",
            fun:    "cloud.profile",
            arg:    ["cluster_node", instance_name]
          }
        )
      end
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
                                    match:  "all" })
      JSON.parse(res.body)["return"].first["data"]["return"]["minions_pre"]
    end

    # Accepts a minion into the cluster
    def self.accept_minion(minion_id: "")
      res = perform_request(endpoint: "/", method: "post",
                            data: { client: "wheel",
                                    fun:    "key.accept",
                                    match:  minion_id })
      JSON.parse(res.body)["return"].first["data"]["return"]["minions"]
    end

    # Returns the list of jobs
    def self.jobs
      res = perform_request(endpoint: "/jobs", method: "get")
      JSON.parse(res.body)["return"]
    end

    # Returns information about a job
    def self.job(jid:)
      res = perform_request(endpoint: "/jobs/#{jid}", method: "get")
      JSON.parse(res.body)
    end

    # Call the salt orchestration.
    def self.orchestrate
      run_async_orchestration orchestration: "kubernetes"
    end

    # Call the update orchestration
    def self.update_orchestration
      run_async_orchestration orchestration: "update"
    end

    # Call the removal orchestration
    def self.removal_orchestration(params:)
      run_async_orchestration orchestration: "removal", params: params
    end

    # Call the force removal orchestration
    def self.force_removal_orchestration(params:)
      run_async_orchestration orchestration: "force-removal", params: params
    end

    def self.run_async_orchestration(orchestration:, params: nil)
      res = perform_request(endpoint: "/run", method: "post",
                            data: { client: "runner_async",
                                    fun:    "state.orchestrate",
                                    mods:   "orch.#{orchestration}",
                                    pillar: params })
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
