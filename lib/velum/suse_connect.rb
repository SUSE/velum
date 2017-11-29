require "net/http"
require "velum/http_exceptions"

module Velum
  # This class handles interaction with the SUSE Connect service (whether is the SCC or SMT).
  class SUSEConnect
    # Raised when there is a connection exception with the SMT/SCC service
    class SCCConnectionException < StandardError; end
    # Raised when an active registration code for CaaSP is missing
    class MissingRegCodeException < StandardError; end
    # Raised when no credentials were found for SCC service
    class MissingCredentialsException < StandardError; end

    DEFAULT_SMT_URL = "https://scc.suse.com".freeze

    SUSEConnectConfig = Struct.new :smt_url, :regcode

    class << self
      def config
        if smt_url == DEFAULT_SMT_URL
          SUSEConnectConfig.new smt_url, regcode
        else
          SUSEConnectConfig.new smt_url
        end
      end

      def smt_url_prefixes
        ["/run/secrets", "/etc"]
      end

      def smt_config_file_contents(prefix:)
        YAML.load_file File.join(prefix, "SUSEConnect")
      rescue StandardError
        nil
      end

      def smt_config
        smt_config = nil
        smt_url_prefixes.each do |prefix|
          smt_config ||= smt_config_file_contents prefix: prefix
        end
        smt_config || {}
      end

      def smt_url
        smt_config["url"] || DEFAULT_SMT_URL
      end

      def smt_insecure
        smt_config["insecure"] || false
      end

      def credentials_prefixes
        ["/run/secrets", "/etc/zypp"]
      end

      def credentials_file_contents(prefix:)
        File.read File.join(prefix, "credentials.d", "SCCcredentials")
      rescue StandardError
        nil
      end

      def credentials
        credentials_config = nil
        credentials_prefixes.each do |prefix|
          credentials_config ||= credentials_file_contents prefix: prefix
        end
        raise MissingCredentialsException if credentials_config.nil?
        {
          username: /^username=(.+)$/.match(credentials_config)[1],
          password: /^password=(.+)$/.match(credentials_config)[1]
        }
      end

      def regcode
        SUSEConnect.new(smt_url:      smt_url,
                        smt_insecure: smt_insecure,
                        credentials:  credentials).regcode
      end
    end

    # Initializes a SUSEConnect client.
    #
    # It takes `smt_url` which links to the SMT service to be used (by default is DEFAULT_SMT_URL),
    # smt_insecure (that allows for this connection to be insecure), and a credentials hash
    # including `:username` and `:password` keys.
    def initialize(smt_url: SUSEConnect::DEFAULT_SMT_URL, smt_insecure: false, credentials:)
      @smt_url = smt_url
      @smt_insecure = smt_insecure
      @credentials = credentials
    end

    # Obtains an active regcode for CaaSP.
    #
    # This method will retrieve an active and valid regcode for CaaSP using the credentials
    # provided when this instance was created.
    #
    # If no valid active regcode is found for CaaSP, `MissingRegCodeException` will be raised.
    #
    # If there is any kind of connectivity problem with SMT/SCC, `SCCConnectionException` will be
    # raised.
    def regcode
      result, all_activations = perform_request endpoint: "/connect/systems/activations",
                                                method:   "get"
      case result
      when Net::HTTPSuccess
        activated_caasp_regcodes = all_activations.select do |activation|
          activation["status"] == "ACTIVE" &&
            activation["service"]["product"]["identifier"] == "CAASP"
        end
        # rubocop:disable Style/RescueModifier
        regcode = activated_caasp_regcodes.first["regcode"] rescue nil
        # rubocop:enable Style/RescueModifier
        regcode || raise(MissingRegCodeException)
      else
        raise SCCConnectionException
      end
    end

    # Performs an HTTP request to the SCC server.
    #
    # Returns the response object.
    def perform_request(endpoint:, method:, data: {})
      uri = URI.join @smt_url, endpoint
      req = Net::HTTP.const_get(method.capitalize).new uri
      req.basic_auth @credentials[:username], @credentials[:password]
      req["Accept"]       = "application/json; charset=utf-8"
      req["Content-Type"] = "application/json; charset=utf-8"
      req.body = data.to_json if data.present?

      opts = { open_timeout: 2, use_ssl: uri.scheme == "https" }
      opts[:verify_mode] = OpenSSL::SSL::VERIFY_NONE if opts[:use_ssl] && @smt_insecure
      response = Net::HTTP.start(uri.hostname, uri.port, opts) { |http| http.request req }
      case response
      when Net::HTTPSuccess
        return response, JSON.parse(response.body)
      else
        return response, nil
      end
    rescue *HTTPExceptions::EXCEPTIONS => e
      raise SCCConnectionException, e
    end
  end
end
