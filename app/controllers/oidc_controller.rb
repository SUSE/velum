# frozen_string_literal: true

require "velum/kubernetes"

# OidcController is used for performing an OpenID Connect auth
# flow against Dex, allowing Velum to generate a complete kubeconfig
# file for a user, including their JWT token
class OidcController < ApplicationController
  # allow anyone to start this, the auth will happen inside
  # Dex.
  skip_before_action :authenticate_user!
  skip_before_action :redirect_to_setup

  # Skipping the CSRF validation just in case. If we add more methods, then
  # we'll need to add an "except" or an "only" clause to this.
  skip_before_action :verify_authenticity_token

  def new_nonce
    session[:nonce] = SecureRandom.hex(16)
  end

  def stored_nonce
    n = session.delete(:nonce)
    raise "Invalid Session" if n.nil?
    n
  end

  def issuer
    "https://#{Pillar.value(pillar: :apiserver)}:32000"
  end

  def client_id
    "caasp-cli"
  end

  def index
    lookup_config

    if @apiserver_host.blank?
      redirect_to root_path,
                  alert: "Provisioning did not yet finish. Please wait until the cluster is ready."
    else
      redirect_to authorization_uri(new_nonce)
    end
  end

  def decode_id(id_token)
    OpenIDConnect::ResponseObject::IdToken.decode(id_token, oidc_config.jwks)
  end

  def done
    client = client()
    client.authorization_code = params[:code]

    access_token = client.access_token!(:basic)
    id_token = decode_id(access_token.id_token)
    id_token.verify!(
      issuer:    issuer,
      client_id: client_id,
      nonce:     stored_nonce
    )

    lookup_config

    @access_token = access_token
    @id_token = id_token

    response.headers["Content-Disposition"] = "attachment; filename=kubeconfig"
    render "kubeconfig.erb", layout: false, content_type: "text/yaml"
  end

  def lookup_config
    kubeconfig = Velum::Kubernetes.kubeconfig
    @apiserver_host = kubeconfig.host
    @ca_crt = kubeconfig.ca_crt
    @client_crt = kubeconfig.client_crt
    @client_key = kubeconfig.client_key
  end

  def authorization_uri(nonce)
    client = client()
    client.authorization_uri(
      response_type: :code,
      nonce:         nonce,
      state:         nonce,
      scope:         [:openid, :profile, :email, :offline_access, :groups].collect(&:to_s)
    )
  end

  def oidc_config
    @oidc_config ||= OpenIDConnect::Discovery::Provider::Config.discover! \
      "https://#{Pillar.value(pillar: :apiserver)}:32000"
  end

  def client
    config = oidc_config

    @client ||= OpenIDConnect::Client.new(
      identifier:             client_id,
      secret:                 "swac7qakes7AvucH8bRucucH",
      scopes_supported:       config.scopes_supported,
      jwks_uri:               config.jwks_uri,
      authorization_endpoint: config.authorization_endpoint,
      token_endpoint:         config.token_endpoint,
      userinfo_endpoint:      config.userinfo_endpoint,
      redirect_uri:           url_for(controller: "oidc", action: "done")
    )
  end
end
