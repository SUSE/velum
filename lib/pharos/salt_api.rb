# frozen_string_literal: true
require "net/http"

module Pharos
  # This class offers the integration between ruby and the Saltstack API.
  module SaltApi
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
        return client.token if client&.token
        token = perform_request(endpoint: "/login",
                                method:   "post",
                                data:     auth_details)["X-Auth-Token"]
        client&.token = token
        token
      end

      # Returns the authentication details for the current environment.
      def auth_details
        {
          username: ENV["PHAROS_SALT_USER"],
          password: ENV["PHAROS_SALT_PASSWORD"],
          eauth:    "pam"
        }.freeze
      end

      # Returns salt hostname for the current environment.
      def hostname
        "#{ENV["PHAROS_SALT_HOST"]}:#{ENV["PHAROS_SALT_PORT"]}"
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
      end
    end
  end
end
