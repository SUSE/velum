# Pillar represents a pillar value on Salt.
# rubocop:disable Metrics/ClassLength
class Pillar < ApplicationRecord
  validates :pillar, presence: true
  validates :value, presence: true, eviction: true

  scope :global, -> { where minion_id: nil }

  PROTECTED_PILLARS = [:dashboard, :apiserver, :dashboard_external_fqdn].freeze

  # update_or_remove! updates the current pillar with the given value. That
  # being said, if the given value is blank, then it will destroy this pillar.
  def update_or_remove!(val)
    val.blank? ? destroy : update_attributes!(value: val)
  end

  class << self
    def value(pillar:)
      Pillar.find_by(pillar: all_pillars[pillar]).try(:value)
    end

    def all_pillars
      simple_pillars.merge(cloud_pillars).merge(cpi_pillars)
    end

    def simple_pillars
      {
        dashboard:                     "dashboard",
        dashboard_external_fqdn:       "dashboard_external_fqdn",
        apiserver:                     "api:server:external_fqdn",
        cluster_cidr:                  "cluster_cidr",
        cluster_cidr_min:              "cluster_cidr_min",
        cluster_cidr_max:              "cluster_cidr_max",
        cluster_cidr_len:              "cluster_cidr_len",
        cni_plugin:                    "cni:plugin",
        flannel_backend:               "flannel:backend",
        cilium_image:                  "cilium:image",
        services_cidr:                 "services_cidr",
        api_cluster_ip:                "api:cluster_ip",
        dns_cluster_ip:                "dns:cluster_ip",
        proxy_systemwide:              "proxy:systemwide",
        http_proxy:                    "proxy:http",
        https_proxy:                   "proxy:https",
        no_proxy:                      "proxy:no_proxy",
        tiller:                        "addons:tiller",
        ldap_host:                     "ldap:host",
        ldap_port:                     "ldap:port",
        ldap_bind_dn:                  "ldap:bind_dn",
        ldap_bind_pw:                  "ldap:bind_pw",
        ldap_domain:                   "ldap:domain",
        ldap_group_dn:                 "ldap:group_dn",
        ldap_people_dn:                "ldap:people_dn",
        ldap_base_dn:                  "ldap:base_dn",
        ldap_admin_group_dn:           "ldap:admin_group_dn",
        ldap_admin_group_name:         "ldap:admin_group_name",
        ldap_tls_method:               "ldap:tls_method",
        ldap_mail_attribute:           "ldap:mail_attribute",
        dex_client_secrets_kubernetes: "dex:client_secrets:kubernetes",
        dex_client_secrets_velum:      "dex:client_secrets:velum",
        cloud_framework:               "cloud:framework",
        cloud_provider:                "cloud:provider",
        kubernetes_feature_gates:      "kubernetes:feature_gates",
        container_runtime:             "cri:chosen",
        api_audit_log_enabled:         "api:audit:log:enabled",
        api_audit_log_maxsize:         "api:audit:log:maxsize",
        api_audit_log_maxage:          "api:audit:log:maxage",
        api_audit_log_maxbackup:       "api:audit:log:maxbackup",
        api_audit_log_policy:          "api:audit:log:policy"
      }
    end

    # rubocop:disable Layout/AlignHash
    def cloud_pillars
      {
        azure_subscription_id:
          "cloud:providers:azure:subscription_id",
        azure_tenant_id:
          "cloud:providers:azure:tenant",
        azure_client_id:
          "cloud:providers:azure:client_id",
        azure_secret:
          "cloud:providers:azure:secret",
        cloud_storage_account:
          "cloud:profiles:cluster_node:storage_account",
        cloud_worker_type:
          "cloud:profiles:cluster_node:size",
        cloud_worker_subnet:
          "cloud:profiles:cluster_node:subnet",
        cloud_worker_security_group:
          "cloud:profiles:cluster_node:network_interfaces:SecurityGroupId",
        cloud_worker_net:
          "cloud:profiles:cluster_node:network",
        cloud_worker_resourcegroup:
          "cloud:profiles:cluster_node:resourcegroup"
      }
    end

    def cpi_pillars
      {
        cloud_openstack_auth_url:
          "cloud:openstack:auth_url",
        cloud_openstack_domain:
          "cloud:openstack:domain",
        cloud_openstack_domain_id:
          "cloud:openstack:domain_id",
        cloud_openstack_project:
          "cloud:openstack:project",
        cloud_openstack_project_id:
          "cloud:openstack:project_id",
        cloud_openstack_region:
          "cloud:openstack:region",
        cloud_openstack_username:
          "cloud:openstack:username",
        cloud_openstack_password:
          "cloud:openstack:password",
        cloud_openstack_subnet:
          "cloud:openstack:subnet",
        cloud_openstack_floating:
          "cloud:openstack:floating",
        cloud_openstack_lb_mon_retries:
          "cloud:openstack:lb_mon_retries",
        cloud_openstack_bs_version:
          "cloud:openstack:bs_version"
      }
    end
    # rubocop:enable Layout/AlignHash

    # Apply the given pillars into the database. It returns an array with the
    # encountered errors.
    def apply(pillars, required_pillars: [], unprotected_pillars: [])
      errors = []

      Pillar.all_pillars.each do |key, pillar_key|
        next if !unprotected_pillars.include?(key) && pillars[key].blank?
        errors = set_pillar key: key, pillar_key: pillar_key, value: pillars[key],
                            required_pillars: required_pillars, errors: errors
      end

      errors
    end

    private

    def set_pillar(key:, pillar_key:, value:, required_pillars:, errors:)
      optional_pillars = Pillar.all_pillars.keys - required_pillars
      value_ = value.to_s.strip
      # The following pillar keys can be blank, delete them if they are.
      if optional_pillars.include?(key) && value_.blank?
        Pillar.destroy_all pillar: pillar_key
      else
        pillar = Pillar.find_or_initialize_by(pillar: pillar_key).tap do |pillar_|
          pillar_.value = value_
        end
        unless pillar.save
          exp = pillar.errors.empty? ? "" : ": #{pillar.errors.messages[:value].first}"
          errors << "'#{key}' could not be saved#{exp}."
        end
      end
      errors
    end
  end
end
# rubocop:enable Metrics/ClassLength
