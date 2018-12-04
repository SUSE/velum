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
  skip_before_action :redirect_to_dashboard,
                     only: [:worker_bootstrap, :build_cloud_cluster]
  before_action :check_empty_settings, only: :configure
  before_action :check_empty_roles, only: :set_roles

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
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
    @suse_registry_mirror = RegistryMirror.find_or_initialize_by(
      registry_id: Registry.find_by(name: Registry::SUSE_REGISTRY_NAME).try(:id)
    )
    @suse_registry_mirror_enabled = @suse_registry_mirror.persisted?
    @suse_registry_mirror_certificate_enabled = @suse_registry_mirror.certificate.present?

    # cloud settings
    @cloud_provider = Pillar.value(pillar: :cloud_provider)
    @cloud_openstack_auth_url = Pillar.value(pillar: :cloud_openstack_auth_url)
    @cloud_openstack_domain = Pillar.value(pillar: :cloud_openstack_domain)
    @cloud_openstack_domain_id = Pillar.value(pillar: :cloud_openstack_domain_id)
    @cloud_openstack_project = Pillar.value(pillar: :cloud_openstack_project)
    @cloud_openstack_project_id = Pillar.value(pillar: :cloud_openstack_project_id)
    @cloud_openstack_region = Pillar.value(pillar: :cloud_openstack_region)
    @cloud_openstack_username = Pillar.value(pillar: :cloud_openstack_username)
    @cloud_openstack_password = Pillar.value(pillar: :cloud_openstack_password)
    @cloud_openstack_subnet = Pillar.value(pillar: :cloud_openstack_subnet)
    @cloud_openstack_floating = Pillar.value(pillar: :cloud_openstack_floating)
    @cloud_openstack_lb_mon_retries = Pillar.value(pillar: :cloud_openstack_lb_mon_retries) || "3"
    @cloud_openstack_bs_version = Pillar.value(pillar: :cloud_openstack_bs_version) || "v2"
    @cloud_openstack_ignore_vol_az = Pillar.value(pillar: :cloud_openstack_ignore_vol_az) || "false"

    # container runtime setting
    @cri = Pillar.value(pillar: :container_runtime) || "docker"

    # allow adding system certificate: required if a user uses CPI with a
    # self-signed certificate
    @system_certificate = if session[:system_certificate_name].present?
      SystemCertificate.find_by(name: session[:system_certificate_name])
    else
      SystemCertificate.new
    end
    @cert = if @system_certificate.certificate.present?
      @system_certificate.certificate
    else
      Certificate.new
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize

  def configure
    res = Pillar.apply(settings_params,
                       required_pillars:    required_pillars,
                       unprotected_pillars: unprotected_pillars)
    registry_errors = Registry.configure_suse_registry(suse_registry_mirror_params)

    certificate_errors = create_system_certificate

    if [res, registry_errors, certificate_errors].all?(&:empty?)
      redirect_to setup_worker_bootstrap_path
    else
      redirect_to setup_path, alert: res + registry_errors + certificate_errors
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def worker_bootstrap
    @controller_node = Pillar.value pillar: :dashboard

    cloud = Pillar.value(pillar: :cloud_framework) || ""
    return if cloud.empty? || cloud == "openstack"

    @instance_types = Velum::InstanceType.for(cloud)
    @cloud_cluster = ClusterSizeSliderDecorator.new(
      CloudCluster.new(
        cloud_framework: cloud,
        instance_type:   (Pillar.value(pillar: :cloud_worker_type) || @instance_types.first.key)
      )
    )
    case cloud
    when "ec2"
      @cloud_cluster.subnet_id = Pillar.value(
        pillar: :cloud_worker_subnet
      ) || "subnet-"
      @cloud_cluster.security_group_id = Pillar.value(
        pillar: :cloud_worker_security_group
      ) || "sg-"
    end
    render "worker_bootstrap_#{cloud}".to_sym
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def build_cloud_cluster
    @cloud_cluster = CloudCluster.new(cloud_cluster_params)

    if @cloud_cluster.save
      @cloud_cluster.build!
      redirect_to (setup_done? ? root_path : setup_discovery_path),
        notice: "Starting to build #{@cloud_cluster}..."
    else
      flash.keep
      redirect_to (setup_done? ? root_path : setup_worker_bootstrap_path),
        flash: { error: @cloud_cluster.errors.full_messages.to_sentence }
    end
  end

  def set_roles
    # rubocop:disable Rails/SkipsModelValidations
    Minion.cluster_role.update_all role: nil
    # rubocop:enable Rails/SkipsModelValidations
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
      Orchestration.run
      redirect_to root_path
    end
  end

  private

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
  def settings_params
    settings = params.require(:settings)
                     .permit(*Pillar.all_pillars.keys,
                             system_certificate: [:name, :certificate, :current_cert])

    if params["settings"]["enable_proxy"] == "disable"
      settings["proxy_systemwide"] = "false"
      settings["http_proxy"] = ""
      settings["https_proxy"] = ""
      settings["no_proxy"] = ""
    end

    settings["dex_client_secrets_kubernetes"] = \
      Pillar.value(pillar: :dex_client_secrets_kubernetes) \
      || SecureRandom.uuid
    settings["dex_client_secrets_velum"] = Pillar.value(pillar: :dex_client_secrets_velum) \
      || SecureRandom.uuid

    if params["settings"]["cloud_provider"] == "disable"
      settings["cloud_provider"] = nil
    end

    if params["settings"]["cloud_provider"] == "disable" ||
        params["settings"]["cloud_provider"] != "openstack"
      Pillar.cpi_pillars.each_key do |k|
        settings[k.to_s] = nil if k.to_s.starts_with?("cloud_openstack")
      end
    end

    Velum::LDAP.ldap_pillar_settings!(settings)
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize

  def suse_registry_mirror_params
    if params["settings"]["suse_registry_mirror_enabled"].blank? ||
        params["settings"]["suse_registry_mirror_enabled"] == "disable"
      return []
    end

    parameters = params["settings"]["suse_registry_mirror"]

    if params["settings"]["suse_registry_mirror_certificate_enabled"] == "disable"
      parameters.delete :certificate
    end

    if params["settings"]["suse_registry_mirror_enabled"] == "enable"
      parameters["mirror_url"] = params["settings"]["suse_registry_mirror"]["url"]
    end

    parameters
  end

  def cloud_cluster_params
    cloud_cluster = params.require(:cloud_cluster).permit(
      :cloud_framework,
      :subscription_id,
      :instance_type, :instance_type_custom, :instance_count,
      :resource_group, :storage_account,
      :network_id, :subnet_id, :security_group_id
    )
    cloud_cluster["cloud_framework"] = Pillar.value(pillar: :cloud_framework)
    cloud_cluster
  end

  def update_nodes_params
    params.require(:roles)
  end

  def system_certificate_params
    settings_params[:system_certificate]
  end

  def proxy_enabled
    (@http_proxy.present? && @https_proxy.present? && @no_proxy.present?) ||
      @proxy_systemwide == "true"
  end

  def redirect_to_dashboard
    redirect_to root_path if setup_done?
  end

  def failed_assigned_nodes(assigned)
    assigned.reject { |_name, success| success }.keys.join(", ")
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
      [
        :proxy_systemwide,
        :http_proxy,
        :https_proxy,
        :no_proxy,
        :cloud_provider
      ].concat(Pillar.cpi_pillars.keys)
    when "do_bootstrap"
      []
    end
  end

  # Create a new SystemCertificate and remember the name.
  #
  # @return [String] A list of errors while attempting to create the
  #                  certificate and related objects
  def create_system_certificate
    return [] if system_certificate_params.blank? ||
        system_certificate_params.values.all?(&:blank?)
    errors = SystemCertificate.create_system_certificate(system_certificate_params)
    if errors.empty? &&
        SystemCertificate.exists?(name: system_certificate_params[:name])
      session[:system_certificate_name] = system_certificate_params[:name]
    end
    errors
  end
end
# rubocop:enable Metrics/ClassLength
