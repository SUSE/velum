# frozen_string_literal: true
require "net/http"

module Velum
  # This class offers the integration between ruby and the Saltstack API.
  module SaltApi
    class SaltConnectionException < StandardError; end

    HTTP_EXCEPTIONS = [
      SocketError,
      Errno::ETIMEDOUT,
      Net::ReadTimeout,
      Net::OpenTimeout,
      Net::ProtocolError,
      Errno::ECONNREFUSED,
      Errno::EHOSTDOWN,
      Errno::ECONNRESET,
      Errno::ENETUNREACH,
      Errno::EHOSTUNREACH,
      Errno::ECONNABORTED,
      OpenSSL::SSL::SSLError,
      EOFError
    ].freeze

    def self.included(base)
      base.extend(ClassMethods)
    end

    attr_accessor :token

    # Perform request to endpoint, with method and provided data
    def perform_request(endpoint:, method:, data: {})
      self.class.perform_request endpoint: endpoint,
                                 method:   method,
                                 data:     data,
                                 client:   self
    end

    # Defines class methods
    module ClassMethods
      # Performs a log in request and sets the @token instance variable on success at
      # client object.
      def login!(client:)
        return client.token if client.try(:token)
        token = perform_request(endpoint: "/login",
                                method:   "post",
                                data:     auth_details)["X-Auth-Token"]
        client.token = token if client

        token
      end

      # Returns the authentication details for the current environment.
      def auth_details
        {
          username: ENV["VELUM_SALT_USER"],
          password: ENV["VELUM_SALT_PASSWORD"],
          eauth:    "pam"
        }.freeze
      end

      # Returns salt hostname for the current environment.
      def hostname
        "#{ENV["VELUM_SALT_HOST"]}:#{ENV["VELUM_SALT_PORT"]}"
      end

      # Returns true if it is a tokenless request
      #
      # Some methods do not require a token and include the authentication directly
      # with the data body (https://docs.saltstack.com/en/latest/ref/netapi/all/salt.netapi.rest_cherrypy.html#run)
      def tokenless_request?(endpoint:, method:)
        (endpoint == "/run" && method.casecmp("post").zero?) || endpoint == "/login"
      end

      # Performs an HTTP request to the Salt API server. This methods already sets
      # some headers like "X-Auth-Token" automatically.
      #
      # Returns the response object.
      def perform_request(endpoint:, method:, data: {}, client: nil)
        is_tokenless_request = tokenless_request?(endpoint: endpoint, method: method)
        token = is_tokenless_request ? nil : login!(client: client)

        uri = URI.join("http://#{hostname}", endpoint)

        req = Net::HTTP.const_get(method.capitalize).new(uri)
        req["Accept"]       = "application/json; charset=utf-8"
        req["Content-Type"] = "application/json; charset=utf-8"

        if is_tokenless_request
          req.body = data.merge(auth_details).to_json
        else
          req["X-Auth-Token"] = token
          req.body = data.to_json unless data.blank?
        end

        opts = { use_ssl: false, open_timeout: 2 }
        Net::HTTP.start(uri.hostname, uri.port, opts) { |http| http.request(req) }
      rescue *HTTP_EXCEPTIONS
        # TODO: we might want to wrap the original exception inside the SaltConnectionException
        # so we can show detailed problems to the user in the future.
        raise SaltConnectionException
      end
    end
  end
end
