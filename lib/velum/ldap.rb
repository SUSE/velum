module Velum
  # Helper methods for LDAP to appease rubocop
  class LDAP
    class << self
      def configure_ldap_tls!(ldap_config, conn_params)
        return unless ldap_config.key?("ssl")
        conn_params.merge!(
          encryption: ldap_config["ssl"].to_sym
        )
      end

      def fail_if_with(result, message)
        raise message unless result
      end

      def ldap_config
        cfg = ::Devise.ldap_config || Rails.root.join("config", "ldap.yml")
        YAML.safe_load(ERB.new(File.read(cfg)).result)[Rails.env]
      end

      def ldap_pillar_settings!(settings)
        cfg = Velum::LDAP.ldap_config
        settings["ldap_host"] = cfg["host"]
        settings["ldap_port"] = cfg["port"]
        settings["ldap_bind_dn"] = cfg["admin_user"]
        settings["ldap_bind_pw"] = cfg["admin_password"]
        settings["ldap_domain"] = ENV["ldap_domain"] # Devise doesn't use this, but Dex does
        settings["ldap_group_dn"] = cfg["group_base"]
        settings["ldap_people_dn"] = cfg["base"]
        settings["ldap_base_dn"] = cfg["tree_base"]
        admin_dn_str = cfg["required_groups"][0]
        admin_dn = Net::LDAP::DN.new(admin_dn_str).to_a
        settings["ldap_admin_group_dn"] = admin_dn_str
        settings["ldap_admin_group_name"] = admin_dn[1]

        settings["ldap_tls_method"] = cfg["ssl"] if cfg.key?("ssl")
        settings["ldap_mail_attribute"] = cfg["attribute"]

        settings
      end
    end
  end
end
