# frozen_string_literal: true

require "velum/kubernetes"
require "velum/suse_connect"

# DashboardController shows the main page.
class DashboardController < ApplicationController
  include Discovery

  rescue_from Minion::NonExistingNode, with: :node_not_found

  # TODO: move autoyast to its own controller (following a different logic flow). It would never get
  # authenticated (as login/password -- since it's machines requesting this endpoint). It would
  # never get redirected to setup the cluster, and it should actually read some security setting for
  # only serving the autoyast profile to a set of IP ranges (provided by the customer).
  skip_before_action :redirect_to_secure, only: :autoyast
  skip_before_action :authenticate_user!, only: :autoyast
  skip_before_action :redirect_to_setup, only: :autoyast

  # The index method is provided through the Discovery concern.
  alias index discovery

  before_action :redirect_to_dashboard, only: :unassigned_nodes

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

      # proxy related settings
      @proxy_systemwide = Pillar.value(pillar: :proxy_systemwide) == "true"
      @proxy_http       = Pillar.value(pillar: :http_proxy)
      @proxy_https      = Pillar.value(pillar: :https_proxy)
      @proxy_no_proxy   = Pillar.value(pillar: :no_proxy)

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

  # GET /assign_nodes
  def unassigned_nodes
    @unassigned_minions = Minion.unassigned_role
  end

  # POST /assign_nodes
  def assign_nodes
    assigned = Minion.assign_roles!(roles: update_nodes_params)

    respond_to do |format|
      if assigned.values.include?(false)
        message = "Failed to assign #{failed_assigned_nodes(assigned)}"
        flash[:error] = message
        format.html { redirect_to assign_nodes_path }
      else
        Velum::Salt.orchestrate
        format.html { redirect_to authenticated_root_path }
      end
    end
  end

  private

  def update_nodes_params
    params.require(:roles).permit(worker: [])
  end

  def redirect_to_dashboard
    redirect_to root_path unless setup_done?
  end

  def failed_assigned_nodes(assigned)
    assigned.select { |_name, success| !success }.keys.join(", ")
  end

  def node_not_found(exception)
    respond_to do |format|
      format.html do
        flash[:error] = exception.message
        redirect_to assign_nodes_path
      end
    end
  end
end
