require "velum/salt"

module Velum
  # Kubernetes deals with the Kubernetes integration of this application.
  class Kubernetes
    KubeConfig = Struct.new :host, :ca_crt, :client_crt, :client_key

    # Returns the Kubernetes apiserver configuration. It returns a KubeConfig struct.
    def self.kubeconfig
      ca_crt = Velum::Salt.read_file(targets: "ca", file: "/etc/pki/ca.crt").first
      client_crt = Velum::Salt.read_file(targets:     "roles:kube-master",
                                         target_type: "grain",
                                         file:        "/etc/pki/kubectl-client-cert.crt").first
      client_key = Velum::Salt.read_file(targets:     "roles:kube-master",
                                         target_type: "grain",
                                         file:        "/etc/pki/kubectl-client-cert.key").first
      host = Pillar.value pillar: :apiserver

      KubeConfig.new host, ca_crt, client_crt, client_key
    end
  end
end
