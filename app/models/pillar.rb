# frozen_string_literal: true
# Pillar represents a pillar value on Salt.
#
# This can override already existing pillar values, or create completely new ones.
#
# For example, given that we have on our static pillar:
#
#   certificate_information:
#     subject_properties:
#       C: DE
#       O: SUSE
#
# We could override them by creating the following Pillar records:
#
#   Pillar.create pillar: "certificate_information:subject_properties:C", value: "FR"
#   Pillar.create pillar: "certificate_information:subject_properties:O", value: "My Company"
#
# Lists can be represented as collisions. So, creating the following Pillar records:
#
#   Pillar.create pillar: "my_service:extra_ips", value: "127.0.0.1"
#   Pillar.create pillar: "my_service:extra_ips", value: "127.0.0.2"
#
# Would match the following YAML representation:
#
#   my_service:
#     extra_ips:
#       - 127.0.0.1
#       - 127.0.0.2
#
# This is because how we configure our salt master using this table as an external pillar. For
# further information you can visit:
#   - https://github.com/kubic-project/velum/blob/master/docs/salt.md
#   - https://github.com/kubic-project/salt/blob/master/config/master.d/returner.conf
class Pillar < ApplicationRecord
  validates :pillar, presence: true
  validates :value, presence: true

  scope :global, -> { where minion_id: nil }

  PROTECTED_PILLARS = [:dashboard, :apiserver].freeze

  class << self
    def value(pillar:)
      Pillar.find_by(pillar: all_pillars[pillar]).try(:value)
    end

    def all_pillars
      {
        dashboard:             "dashboard",
        apiserver:             "api:server:external_fqdn",
        cluster_cidr:          "cluster_cidr",
        cluster_cidr_min:      "cluster_cidr_min",
        cluster_cidr_max:      "cluster_cidr_max",
        cluster_cidr_len:      "cluster_cidr_len",
        services_cidr:         "services_cidr",
        api_cluster_ip:        "api:cluster_ip",
        dns_cluster_ip:        "dns:cluster_ip",
        proxy_systemwide:      "proxy:systemwide",
        http_proxy:            "proxy:http",
        https_proxy:           "proxy:https",
        no_proxy:              "proxy:no_proxy",
        ldap_host:             "ldap:host",
        ldap_port:             "ldap:port",
        ldap_bind_dn:          "ldap:bind_dn",
        ldap_bind_pw:          "ldap:bind_pw",
        ldap_domain:           "ldap:domain",
        ldap_group_dn:         "ldap:group_dn",
        ldap_people_dn:        "ldap:people_dn",
        ldap_base_dn:          "ldap:base_dn",
        ldap_admin_group_dn:   "ldap:admin_group_dn",
        ldap_admin_group_name: "ldap:admin_group_name",
        ldap_tls_method:       "ldap:tls_method",
        ldap_mail_attribute:   "ldap:mail_attribute"
      }
    end

    # Apply the given pillars into the database. It returns an array with the
    # encountered errors.
    def apply(pillars, required_pillars: [], unprotected_pillars: [])
      errors = []

      Pillar.all_pillars.each do |key, pillar_key|
        next if !unprotected_pillars.include?(key) && pillars[key].blank?
        set_pillar key: key, pillar_key: pillar_key, value: pillars[key],
                   required_pillars: required_pillars, errors: errors
      end

      errors
    end

    private

    def set_pillar(key:, pillar_key:, value:, required_pillars:, errors:)
      optional_pillars = Pillar.all_pillars.keys - required_pillars
      # The following pillar keys can be blank, delete them if they are.
      if optional_pillars.include?(key) && value.blank?
        Pillar.destroy_all pillar: pillar_key
      else
        pillar = Pillar.find_or_initialize_by(pillar: pillar_key).tap do |pillar_|
          pillar_.value = value
        end
        unless pillar.save
          exp = pillar.errors.empty? ? "" : ": #{pillar.errors.messages[:value].first}"
          errors << "'#{key}' could not be saved#{exp}."
        end
      end
    end
  end
end
