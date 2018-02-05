# frozen_string_literal: true

require "velum/salt"
require "velum/instance_type"

# SetupController is responsible for everything related to the bootstrapping
# process:
# welcoming, setting certain general settings, master selection, discovery and
# bootstrapping
# rubocop:disable Metrics/ClassLength
class SetupController < ApplicationController
  include Discovery

  skip_before_action :redirect_to_setup
  before_action :redirect_to_dashboard
  before_action :check_empty_settings, only: :configure
  before_action :check_empty_roles, only: :set_roles

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def welcome
    @dashboard = Pillar.value(pillar: :dashboard) || request.host
    @tiller = Pillar.value(pillar: :tiller) == "true"
    @http_proxy = Pillar.value pillar: :http_proxy
    @https_proxy = Pillar.value pillar: :https_proxy
    @no_proxy = Pillar.value(pillar: :no_proxy) || "localhost, 127.0.0.1"
    @proxy_systemwide = Pillar.value(pillar: :proxy_systemwide) || "false"
    @enable_proxy = proxy_enabled
    @cluster_cidr = Pillar.value(pillar: :cluster_cidr) || "172.16.0.0/13"
    @cluster_cidr_min = Pillar.value(pillar: :cluster_cidr_min) || "172.16.0.0"
    @cluster_cidr_max = Pillar.value(pillar: :cluster_cidr_max) || "172.23.255.255"
    @cluster_cidr_len = Pillar.value(pillar: :cluster_cidr_len) || "23"
    @services_cidr = Pillar.value(pillar: :services_cidr) || "172.24.0.0/16"
    @api_cluster_ip = Pillar.value(pillar: :api_cluster_ip) || "172.24.0.1"
    @dns_cluster_ip = Pillar.value(pillar: :dns_cluster_ip) || "172.24.0.2"
    @registry_mirror_url = Pillar.value(pillar: :suse_registry_mirror_url)
    @registry_mirror_cert = Pillar.value(pillar: :suse_registry_mirror_cert)
    @registry_mirror_enabled = @registry_mirror_url.present?
    @registry_mirror_cert_enabled = @registry_mirror_cert.present?
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def configure
    res = Pillar.apply(settings_params,
                       required_pillars:    required_pillars,
                       unprotected_pillars: unprotected_pillars)
    if res.empty?
      redirect_to setup_worker_bootstrap_path
    else
      redirect_to setup_path, alert: res
    end
  end

  def worker_bootstrap
    @controller_node = Pillar.value pillar: :dashboard

    return unless (cloud = Pillar.value(pillar: :cloud_framework))

    @instance_types = Velum::InstanceType.for(cloud)
    @cloud_cluster = CloudCluster.new(cloud_framework: cloud)
    case cloud
    when "ec2"
      @cloud_cluster.instance_type = Pillar.value(
        pillar: :cloud_worker_type
      ) || @instance_types.first.key
      @cloud_cluster.subnet_id = Pillar.value(
        pillar: :cloud_worker_subnet
      ) || "subnet-"
      @cloud_cluster.security_group_id = Pillar.value(
        pillar: :cloud_worker_security_group
      ) || "sg-"
    end
    render "worker_bootstrap_#{cloud}".to_sym
  end

  def build_cloud_cluster
    @cloud_cluster = CloudCluster.new(cloud_cluster_params)

    if @cloud_cluster.save
      Velum::Salt.build_cloud_cluster(@cloud_cluster.instance_count)
      redirect_to setup_discovery_path,
        notice: "Starting to build #{@cloud_cluster}..."
    else
      flash.keep
      redirect_to setup_worker_bootstrap_path,
        flash: { error: @cloud_cluster.errors.full_messages.to_sentence }
    end
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
    # TODO: Minion.find_by(role: Minion.roles[:admin]).fqdn ?
    @dashboard_external_fqdn = Pillar.value(pillar: :dashboard_external_fqdn) ||
      ""
  end

  def do_bootstrap
    res = Pillar.apply(settings_params,
                       required_pillars:    required_pillars,
                       unprotected_pillars: unprotected_pillars)
    unless res.empty?
      redirect_to setup_bootstrap_path, alert: res
      return
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
    if params["settings"]["suse_registry_mirror_enabled"] == "disable"
      settings["suse_registry_mirror_url"] = ""
      settings["suse_registry_mirror_cert"] = ""
    end
    if params["settings"]["suse_registry_mirror_cert_enabled"] == "disable"
      settings["suse_registry_mirror_cert"] = ""
    end
    Velum::LDAP.ldap_pillar_settings!(settings)
  end

  def cloud_cluster_params
    cloud_cluster = params.require(:cloud_cluster).permit(
      :instance_type,
      :instance_type_custom,
      :instance_count,
      :vnet_id,
      :subnet_id,
      :security_group_id,
      :publishsettings,
      :media_link
    )
    cloud_cluster["cloud_framework"] = Pillar.value(pillar: :cloud_framework)
    cloud_cluster
  end

  def update_nodes_params
    params.require(:roles)
  end

  def proxy_enabled
    (!@http_proxy.blank? &&
     !@https_proxy.blank? &&
     !@no_proxy.blank?) ||
      @proxy_systemwide == "true"
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
      [:apiserver, :dashboard_external_fqdn]
    end
  end

  def unprotected_pillars
    case action_name
    when "configure"
      [:proxy_systemwide, :http_proxy, :https_proxy, :no_proxy, :cluster_cidr, :cluster_cidr_min,
       :cluster_cidr_max, :cluster_cidr_len, :services_cidr, :api_cluster_ip, :dns_cluster_ip,
       :suse_registry_mirror_url, :suse_registry_mirror_cert]
    when "do_bootstrap"
      []
    end
  end
end
# rubocop:enable Metrics/ClassLength
