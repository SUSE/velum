# frozen_string_literal: true
require "net/http"

module Pharos
  # This class offers the integration between ruby and the Saltstack API.
  class Salt
    def initialize
      @token    = nil
      @hostname = "#{ENV["PHAROS_SALT_HOST"]}:#{ENV["PHAROS_SALT_PORT"]}"
    end

    # This method is the entrypoint of any Salt call. It will simply apply the
    # given function 'fun' with the given arguments 'arg' to the given target
    # machines.
    #
    # Returns two values:
    #   - The response object.
    #   - A hash containing the parsed JSON response.
    def call(tgt, fun, arg = nil)
      login! unless @token

      hsh = { tgt: tgt, fun: fun, client: "local" }
      hsh[:arg] = arg if arg

      res = perform_request("/", "post", hsh)
      [res, JSON.parse(res.body)]
    end

    # Returns the minions as discovered by salt.
    def minions(mid = nil)
      login! unless @token

      id  = mid ? "/#{mid}" : ""
      res = perform_request("/minions#{id}", "get")
      JSON.parse(res.body)["return"].first
    end

    protected

    # Performs a log in request and sets the @token instance variable on success.
    def login!
      hsh = {
        username: ENV["PHAROS_SALT_USER"],
        password: "password",
        eauth:    "auto"
      }

      res = perform_request("/login", "post", hsh)
      @token = res["X-Auth-Token"]
    end

    # Performs an HTTP request to the Salt API server. This methods already sets
    # some headers like "X-Auth-Token" automatically.
    #
    # Returns the response object.
    def perform_request(endpoint, method, data = {})
      uri = URI.join("http://#{@hostname}", endpoint)

      req = Net::HTTP.const_get(method.capitalize).new(uri)
      req["Accept"]       = "application/json; charset=utf-8"
      req["Content-Type"] = "application/x-www-form-urlencoded"
      req["X-Auth-Token"] = @token if @token
      req.set_form_data(data)

      opts = { use_ssl: false, open_timeout: 2 }
      Net::HTTP.start(uri.hostname, uri.port, opts) { |http| http.request(req) }
    end
  end
end
