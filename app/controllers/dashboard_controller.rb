require "velum/suse_connect"
require "velum/autoyast_values"

# DashboardController shows the main page.
class DashboardController < ApplicationController
  include Discovery

  # TODO: move autoyast to its own controller (following a different logic flow). It would never get
  # authenticated (as login/password -- since it's machines requesting this endpoint). It would
  # never get redirected to setup the cluster, and it should actually read some security setting for
  # only serving the autoyast profile to a set of IP ranges (provided by the customer).
  skip_before_action :authenticate_user!, only: :autoyast
  skip_before_action :redirect_to_setup, only: :autoyast
  # make sure that access comes from a registered host
  before_action :host_warning, unless: :known_host?

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
    pollute_variables!(Velum::AutoyastValues.new)
    if @controller_node.blank?
      head :service_unavailable
    else
      render "autoyast.xml.erb", layout: false, content_type: "text/xml"
    end
  end

  # GET /assign_nodes
  def unassigned_nodes
    @unassigned_minions = Minion.unassigned_role
    @assigned_minions_hostnames = Minion.cluster_role.pluck(:fqdn)
  end

  # POST /assign_nodes
  def assign_nodes
    assigned = Minion.assign_roles roles: update_nodes_params, remote: true
    if assigned.values.include?(false)
      redirect_to assign_nodes_path,
                  flash: { error: "Failed to assign #{failed_assigned_nodes(assigned)}" }
    else
      Orchestration.run
      redirect_to authenticated_root_path
    end
  end

  private

  def update_nodes_params
    params.require(:roles).permit(worker: [], master: [])
  end

  def redirect_to_dashboard
    redirect_to root_path unless setup_done?
  end

  def failed_assigned_nodes(assigned)
    assigned.reject { |_name, success| success }.keys.join(", ")
  end

  def host_warning
    flash[:alert] = "You are accessing velum from an unregistered host (#{request.host}). " \
                    "It is advised to access velum via one of the registered hosts " \
                    "#{accessible_hosts.join(" or ")}"
  end

  # This method will copy *all* instance variables of the given object to the
  # current instance. No checks will be performed if a variable already exists -
  # the current value will be overwritten in that case.
  #
  # This copying right now is used to prevent nesting values in the template:
  # instead of writing `<%= other.var %>` it is possible to just write `<%= var
  # %>` again.
  #
  # @param other [Object] Any object with instance variables.
  def pollute_variables!(other)
    other.instance_variables.each do |var|
      instance_variable_set(var, other.instance_variable_get(var))
    end
  end
end
