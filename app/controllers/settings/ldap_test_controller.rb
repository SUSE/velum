require "net/ldap"
require "json"
require "openssl"
require "base64"
require "velum/ldap_mock"

# LdapTestController is used to validate LDAP Connector settings before saving
class Settings::LdapTestController < ApplicationController
  def render_result(result_hash, test_pass, message)
    result_hash[:result] = { test_pass: test_pass, message: message }
    render json: result_hash
  end

  def build_tls_options(pem_string)
    decoded_pem = Base64.decode64(pem_string)
    cert = OpenSSL::X509::Certificate.new(decoded_pem)
    cert_store = OpenSSL::X509::Store.new
    cert_store.add_cert(cert)
    {
      # This flag causes OpenSSL to check the validity of the server certificate
      verify_mode: OpenSSL::SSL::VERIFY_PEER,
      cert_store:  cert_store
    }
  end

  def get_auth_hash(params)
    auth_hash = if params[:anon_bind] == "true"
      {
        method: :anonymous
      }
    else
      {
        method:   :simple,
        username: params[:dn],
        password: params[:pass]
      }
    end
    auth_hash
  end

  # Returns LDAP object or a mock object for RSpec tests
  def get_ldap(result_hash, params)
    begin
      tls = if params[:start_tls] == "true"
        :start_tls
      else
        :simple_tls
      end

      tls_options = build_tls_options(params[:cert])
      auth_hash = get_auth_hash(params)
      ldap = if params[:mock] == "true" # Inject mock LDAP object if rspec is configured for mock
        Velum::LDAPMock.new(params, auth_hash, tls)
      # :nocov:
      else
        Net::LDAP.new host:       params[:host],
                      port:       params[:port],
                      auth:       auth_hash,
                      encryption: { method: tls, tls_options: tls_options }
        # :nocov:
      end
    rescue OpenSSL::X509::CertificateError
      render_result(result_hash, false, "Invalid certificate, check format and try again")
      ldap = nil
    # :nocov:
    rescue StandardError
      render_result(result_hash, false, "Unspecified certificate error.")
      ldap = nil
      # :nocov:
    end
    ldap
  end

  # Searches LDAP connection for users for settings validation
  def user_search(result_hash, ldap, base_dn, filter_string)
    filter = Net::LDAP::Filter.construct(filter_string)
    attrs = ["mail", "cn", "sn", "objectclass"]
    user_search_records = ldap.search(
      base:          base_dn,
      filter:        filter,
      attributes:    attrs,
      return_result: true
    )
    if !user_search_records.empty?
      render_result(result_hash, true, "Connection with LDAP Server successful. Search found " \
      "#{user_search_records.length} users")
    else
      render_result(result_hash, false, "Could not find users with baseDN=#{base_dn} and " \
      "filter=#{filter_string}")
    end
  rescue Net::LDAP::FilterSyntaxInvalidError
    render_result(result_hash, false, "User Search parameters contain syntax errors, please " \
      "check User Search form inputs and try again")
  # :nocov:
  rescue StandardError
    render_result(result_hash, false, "Unspecified User Search error, please check User " \
    "Search form inputs and try again")
    # :nocov:
  end

  def create
    result_hash = { initial_bind: {}, user_search: {}, result: {} }
    ldap = get_ldap(result_hash, params)

    return unless ldap

    # Initial bind with DN to test connection to LDAP server
    begin
      bind_result = ldap.bind
      unless bind_result
        render_result(result_hash, false, "Failed to bind to LDAP server: " \
        "#{ldap.get_operation_result.message}")
        return
      end
    rescue Net::LDAP::Error
      render_result(result_hash, false, "Check that host/port are correct and reachable.")
      return
    end
    user_search(result_hash, ldap, params[:base_dn], params[:filter])
  end
end
