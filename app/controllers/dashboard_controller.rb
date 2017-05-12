# frozen_string_literal: true

require "velum/kubernetes"
require "velum/suse_connect"

# DashboardController shows the main page.
class DashboardController < ApplicationController
  include Discovery

  # TODO: move autoyast to its own controller (following a different logic flow). It would never get
  # authenticated (as login/password -- since it's machines requesting this endpoint). It would
  # never get redirected to setup the cluster, and it should actually read some security setting for
  # only serving the autoyast profile to a set of IP ranges (provided by the customer).
  skip_before_action :authenticate_user!, only: :autoyast
  skip_before_action :redirect_to_setup, only: :autoyast

  # The index method is provided through the Discovery concern.
  alias index discovery

  # Return the autoyast XML profile to bootstrap other worker nodes. They will read this response in
  # order to start an unattended installation of CaaSP.
  #
  # It will return the content of the autoyast profile along with a 200 HTTP response code if the
  # operation was successfull, or a 503 HTTP response code (service unavailable) if there was any
  # problem while contacting to the subscription backend.
  #
  # This method skips authentication (workers won't authenticate using the typical username/password
  # fields that customer uses) and also skips the redirection to the setup process (when a worker
  # asks for the autoyast profile we will either serve it, or return an error).
  def autoyast
    @controller_node = Pillar.value pillar: :dashboard
    if @controller_node.blank?
      head :service_unavailable
    else
      begin
        suse_connect_config = Rails.cache.fetch("SUSEConnect_config") do
          Velum::SUSEConnect.config
        end
        @suse_smt_url = suse_connect_config.smt_url
        @suse_regcode = suse_connect_config.regcode
        @do_registration = true
      rescue Velum::SUSEConnect::MissingRegCodeException,
             Velum::SUSEConnect::MissingCredentialsException
        @do_registration = false
      end
      ssh_key_file = "/var/lib/misc/ssh-public-key/id_rsa.pub"
      # rubocop:disable Style/RescueModifier
      @ssh_public_key = File.read(ssh_key_file) rescue nil
      # rubocop:enable Style/RescueModifier
      render "autoyast.xml.erb", layout: false, content_type: "text/xml"
    end
  rescue Velum::SUSEConnect::SCCConnectionException
    head :service_unavailable
  end

  # Return the kubeconfig file that allows the customer to use the cluster using the kubectl tool.
  #
  # If everything is successfull, the kubeconfig file will be served. Otherwise (e.g. the cluster is
  # not yet provisioned or is still being provisioned) it will redirect to the main page giving the
  # user feedback about the current situation.
  def kubectl_config
    kubeconfig = Velum::Kubernetes.kubeconfig
    @apiserver_host = kubeconfig.host
    @ca_crt = kubeconfig.ca_crt
    @client_crt = kubeconfig.client_crt
    @client_key = kubeconfig.client_key
    if [@apiserver_host, @ca_crt, @client_crt, @client_key].none?(&:blank?)
      response.headers["Content-Disposition"] = "attachment; filename=kubeconfig"
      render "kubeconfig.erb", layout: false, content_type: "text/yaml"
    else
      redirect_to root_path,
                  alert: "Provisioning did not yet finish. Please wait until the cluster is ready."
    end
  end
end
