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

    # This method uses salt-cloud in order to start a minion on EC2 using the
    # provided configuration.
    # Useful links:
    #  https://docs.saltstack.com/en/latest/topics/cloud/aws.html#getting-started-with-aws-ec2
    #  https://docs.saltstack.com/en/latest/ref/runners/all/salt.runners.cloud.html#salt.runners.cloud.create
    #  https://docs.saltstack.com/en/latest/ref/netapi/all/salt.netapi.rest_cherrypy.html
    #
    # Configuration keys and their meaning:
    # instances: the names of the minions to spawn. These will be the minion ids
    #   and the names of the instances as they appers in ec2 console.
    # instance_type: the instance type to use.
    # subnetid: the id of the subnet in which to spawn the minion. No subnet will be used it this is nil.
    # ssh_intefrace: set to public_ips if the master is ouside aws or to private_ips otherwise.
    def self.spawn_minion_ec2(conf)
      res = perform_request(endpoint: "/run", method: "post",
        data: {
          client: "runner_async",
          fun:    "cloud.create",
          kwargs: {
            provider: "ec2-provider",
            image: "ami-eada30fc",
            ssh_connect_timeout: 3600, # TODO lower this value
            ssh_username: "ec2-user",
            instances: conf[:instances],
            size: conf[:instance_type] || "t2.micro",
            minion: { master: conf[:master] },
            subnetid: conf[:subnetid], # TODO: does nil work?
            ssh_interface: conf[:ssh_interface]
          }
        })
      [res, JSON.parse(res.body)]
    end
  end
end
