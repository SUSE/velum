module Velum
  # Helper methods for LDAP to appease rubocop
  class LDAP
    class << self
      def configure_ldap_tls!(ldap_config, conn_params)
        return unless ldap_config.key?("ssl")
        conn_params[:auth].merge!(
          encryption: ldap_config["ssl"].to_sym
        )
      end

      def fail_if_with(result, message)
        raise message unless result
      end
    end
  end
end
