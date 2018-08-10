require "openssl"
require "net/ldap"

module Velum
  # LDAPMock is a mock object to test LDAP connectors without a server
  class LDAPMock
    attr_accessor :host, :port, :start_tls, :cert, :anon_bind, :dn, :pass, :ldap_mock_cfg

    def initialize(ldap_params, auth_hash, tls_method)
      @host = ldap_params[:host].downcase
      @port       = ldap_params[:port]
      @start_tls  = ldap_params[:start_tls]
      @cert       = ldap_params[:cert].tr(" \t\r\n", "")
      @anon_bind  = ldap_params[:anon_bind]
      @dn         = ldap_params[:dn].downcase
      @pass       = ldap_params[:pass]
      @base_dn    = ldap_params[:base_dn].downcase
      @filter     = ldap_params[:filter]

      @auth_hash = auth_hash
      @tls_method = tls_method

      @ldap_mock_cfg = load_ldap_mock
      check_cert
    end

    # Compares certs with space/tab/return/newline removed
    def check_cert
      # :nocov:
      raise OpenSSL::X509::CertificateError if cert.tr(" \t\r\n", "") != \
          ldap_mock_cfg["cert"].tr(" \t\r\n", "")
      # :nocov:
    end

    # Loads mock object properties from ldap_mock.yml
    def load_ldap_mock
      YAML.load_file(::Rails.root.join("config", "ldap_mock.yml"))
    end

    # Replicates "net/ldap" method
    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
    def bind
      raise Net::LDAP::Error unless host == ldap_mock_cfg["host"].downcase

      if start_tls == "true"
        raise Net::LDAP::Error unless port == ldap_mock_cfg["start_tls_port"].to_s
      else
        raise Net::LDAP::Error unless port == ldap_mock_cfg["simple_tls_port"].to_s
      end

      if anon_bind == "true"
        raise Net::LDAP::Error if ldap_mock_cfg["anon_bind"] != true
        return true
      end

      dn == ldap_mock_cfg["dn"].downcase && pass == ldap_mock_cfg["pass"]
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize

    # Replicates "net/ldap" method
    # rubocop:disable Naming/AccessorMethodName
    def get_operation_result
      os = OpenStruct.new
      os.message = "mock test message"
      os
    end
    # rubocop:enable Naming/AccessorMethodName

    # Replicates "net/ldap" method
    def search(base:, filter:, attributes:, return_result:)
      if base == ldap_mock_cfg["base_dn"].downcase &&
          filter == Net::LDAP::Filter.construct(ldap_mock_cfg["filter"])
        # attributes, return_result must be used to keep rubocop happy
        ["user0", "user1", attributes, return_result]
      else
        []
      end
    end
  end
end
