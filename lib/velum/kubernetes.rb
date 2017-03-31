# frozen_string_literal: true

require "velum/salt"

module Velum
  # Kubernetes deals with the Kubernetes integration of this application.
  class Kubernetes
    attr_reader :client

    KubeConfig = Struct.new :host, :ca_crt, :client_crt, :client_key

    # Returns the Kubernetes apiserver configuration. It returns a KubeConfig struct.
    def self.kubeconfig
      _, ca_crt = Velum::Salt.call action:  "cmd.run",
                                   targets: "ca",
                                   arg:     "cat /etc/pki/ca.crt"
      _, apiserver_crt = Velum::Salt.call action:      "cmd.run",
                                          targets:     "roles:kube-master",
                                          target_type: "grain",
                                          arg:         "cat /etc/pki/minion.crt"
      _, apiserver_key = Velum::Salt.call action:      "cmd.run",
                                          targets:     "roles:kube-master",
                                          target_type: "grain",
                                          arg:         "cat /etc/pki/minion.key"
      host = Minion.master.applied.pluck(:hostname).first
      # rubocop:disable Style/RescueModifier
      ca_crt = ca_crt["return"].first.values.first rescue nil
      client_crt = apiserver_crt["return"].first.values.first rescue nil
      client_key = apiserver_key["return"].first.values.first rescue nil
      # rubocop:enable Style/RescueModifier
      KubeConfig.new host, ca_crt, client_crt, client_key
    end

    def initialize
      host = ENV["VELUM_KUBERNETES_HOST"]
      port = ENV["VELUM_KUBERNETES_PORT"]
      base = ENV["VELUM_KUBERNETES_CERT_DIRECTORY"]

      ssl = {
        client_cert: OpenSSL::X509::Certificate.new(File.read(File.join(base, "admin.crt"))),
        client_key:  OpenSSL::PKey::RSA.new(File.read(File.join(base, "admin.key"))),
        ca_file:     File.join(base, "ca.crt"),
        verify_ssl:  OpenSSL::SSL::VERIFY_NONE
        # verify_ssl:  OpenSSL::SSL::VERIFY_PEER
      }

      url = "https://#{host}:#{port}/api/"
      @client = Kubeclient::Client.new url, "v1", ssl_options: ssl
    end
  end
end
