# frozen_string_literal: true

require "velum/salt"

# SetupController is responsible for everything related to the bootstrapping
# process:
# welcoming, setting certain general settings, master selection, discovery and
# bootstrapping
class SetupController < ApplicationController
  include Discovery

  skip_before_action :redirect_to_setup
  before_action :redirect_to_dashboard
  before_action :check_empty_settings, only: :configure
  before_action :check_empty_roles, only: :set_roles

  def welcome
    @dashboard = Pillar.value(pillar: :dashboard) || request.host
    @http_proxy = Pillar.value pillar: :http_proxy
    @https_proxy = Pillar.value pillar: :https_proxy
    @no_proxy = Pillar.value(pillar: :no_proxy) || "localhost, 127.0.0.1"
  end

  def configure
    res = Pillar.apply(settings_params, required_pillars: required_pillars)
    if res.empty?
      redirect_to setup_worker_bootstrap_path
    else
      redirect_to setup_path, alert: res
    end
  end

  def worker_bootstrap
    @controller_node = Pillar.value pillar: :dashboard
  end

  def set_roles
    # rubocop:disable Rails/SkipsModelValidations:
    Minion.update_all role: nil
    # rubocop:enable Rails/SkipsModelValidations:
    assigned = Minion.assign_roles roles: update_nodes_params, remote: false
    if assigned.values.include?(false)
      redirect_to setup_discovery_path,
                  flash: { error: "Failed to assign #{failed_assigned_nodes(assigned)}" }
    else
      redirect_to setup_bootstrap_path
    end
  end

  def bootstrap
    @apiserver = Pillar.value(pillar: :apiserver) ||
      Minion.find_by(role: Minion.roles[:master]).fqdn
  end

  def do_bootstrap
    res = Pillar.apply(settings_params, required_pillars: required_pillars)
    unless res.empty?
      redirect_to setup_bootstrap_path, alert: res
      return
    end
    Pillar.find_or_create_by pillar: "api:etcd_version" do |pillar|
      pillar.value = "etcd3"
    end
    masters = Minion.where(role: Minion.roles[:master]).pluck :id
    workers = Minion.where(role: Minion.roles[:worker]).pluck :id
    assigned = Minion.assign_roles roles: { master: masters, worker: workers }, remote: true
    if assigned.values.include?(false)
      redirect_to setup_bootstrap_path,
                  flash: { error: "Failed to assign #{failed_assigned_nodes(assigned)}" }
    else
      Velum::Salt.orchestrate
      redirect_to root_path
    end
  end

  private

  def settings_params
    settings = params.require(:settings).permit(*Pillar.all_pillars.keys)
    if params["settings"]["enable_proxy"] == "disable"
      settings["proxy_systemwide"] = "false"
      settings["http_proxy"] = ""
      settings["https_proxy"] = ""
      settings["no_proxy"] = ""
    end
    settings
  end

  def update_nodes_params
    params.require(:roles)
  end

  def redirect_to_dashboard
    redirect_to root_path if setup_done?
  end

  def failed_assigned_nodes(assigned)
    assigned.select { |_name, success| !success }.keys.join(", ")
  end

  def check_empty_settings
    return if valid_settings?
    redirect_to setup_path, alert: "Please fill out all necessary form fields"
  end

  def check_empty_roles
    return if params.try(:[], "roles").try(:[], "master")
    redirect_to setup_discovery_path, alert: "Please select a master node"
  end

  def valid_settings?
    required_pillars.none? { |param| settings_params[param].blank? }
  end

  def required_pillars
    case action_name
    when "configure"
      [:dashboard]
    when "do_bootstrap"
      [:apiserver]
    end
  end
end
