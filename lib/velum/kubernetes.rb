# frozen_string_literal: true

require "velum/salt"

module Velum
  # Kubernetes deals with the Kubernetes integration of this application.
  class Kubernetes
    attr_reader :client

    KubeConfig = Struct.new :host, :ca_crt, :client_crt, :client_key

    # Returns the Kubernetes apiserver configuration. It returns a KubeConfig struct.
    def self.kubeconfig
      ca_crt = Velum::Salt.read_file(targets: "ca", file: "/etc/pki/ca.crt").first
      client_crt = Velum::Salt.read_file(targets:     "roles:kube-master",
                                         target_type: "grain",
                                         file:        "/etc/pki/minion.crt").first
      client_key = Velum::Salt.read_file(targets:     "roles:kube-master",
                                         target_type: "grain",
                                         file:        "/etc/pki/minion.key").first
      host = Pillar.value pillar: :apiserver

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
