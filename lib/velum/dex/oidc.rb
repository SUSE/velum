require "base64"

module Velum
  # This generates the JSON that SaltStack uses to list the OIDC connectors
  module Dex
    class << self
      def oidc_connectors_as_pillar
        DexConnectorOidc.all.map do |con|
          {
            type:          "oidc",
            id:            "oidc-" + con.id.to_s,
            name:          con.name,
            provider_url:  con.provider_url,
            client_id:     con.client_id,
            client_secret: con.client_secret,
            callback_url:  con.callback_url,
            basic_auth:    con.basic_auth
          }
        end
      end
    end
  end
end
