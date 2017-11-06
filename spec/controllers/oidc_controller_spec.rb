# frozen_string_literal: true

require "rails_helper"

# rubocop:disable ExampleLength,RSpec/AnyInstance,RSpec/VerifiedDoubles,RSpec/NamedSubject
RSpec.describe OidcController, type: :controller do
  let(:user)                 { create(:user) }
  let(:external_fqdn_pillar) { create(:external_fqdn_pillar) }
  let(:application_controller) { instance_double(ApplicationController) }
  let(:access_token) do
    instance_double(
      "access_token",
      id_token:      "bar",
      client:        OpenStruct.new(identifier: "client"),
      refresh_token: "jaoifujdsof"
    )
  end
  let(:decode_id) do
    instance_double(
      "decode_id",
      "verify!" =>    true,
      raw_attributes: "test@test.com",
      iss:            "https://issuer-url"
    )
  end
  let(:config) do
    instance_double(
      "oidc_config",
      scopes_supported:       ["foo"],
      jwks_uri:               "http://example.com/jwks",
      authorization_endpoint: "http://example.org/auth",
      token_endpoint:         "http://example.org/token",
      userinfo_endpoint:      "http://example.org/user",
      jwks:                   "xxxx.yyyy.zzzz"
    )
  end
  let(:kubeconfig) do
    double(
      Velum::Kubernetes,
      host:       "https://localhost:8000/login",
      ca_crt:     "ca cert",
      client_crt: "client crt",
      client_key: "client key"
    )
  end

  describe "GET /oidc" do
    it "returns a 302 if the orchestration didn't yet finish" do
      sign_in user
      setup_undone

      kubeconfig = double(
        Velum::Kubernetes,
        host:       "",
        ca_crt:     "ca cert",
        client_crt: "client crt",
        client_key: "client key"
      )
      allow(Velum::Kubernetes).to receive(:kubeconfig)
        .and_return(kubeconfig)

      allow(subject).to receive(:verify_host).and_return(true)

      get :index

      expect(response.status).to eq 302
      expect(response.header["Location"]).to eq "http://test.host/"
    end

    it "redirects to Dex if orchestration is done" do
      sign_in user
      setup_done
      external_fqdn_pillar

      allow(Velum::Kubernetes).to receive(:kubeconfig)
        .and_return(kubeconfig)

      allow(subject).to receive(:verify_host).and_return(true)

      allow(OpenIDConnect::Discovery::Provider::Config).to receive(:discover!)
        .and_return(config)

      get :index

      expect(response.status).to eq 302
      expect(response.header["Location"]).to include "/auth"
    end
  end

  describe "GET /oidc/done" do
    render_views

    before do
      setup_done
      external_fqdn_pillar
      sign_in user
    end

    it "generates a kubeconfig if auth succeeds" do
      allow(subject).to receive(:verify_host).and_return(true)

      allow_any_instance_of(OpenIDConnect::Client).to receive(:access_token!)
        .and_return(access_token)

      allow(Velum::Kubernetes).to receive(:kubeconfig)
        .and_return(kubeconfig)

      allow(OpenIDConnect::Discovery::Provider::Config).to receive(:discover!)
        .and_return(config)

      allow_any_instance_of(OpenIDConnect::Client).to receive(:authorization_code=)
      allow(OpenIDConnect::ResponseObject::IdToken).to receive(:decode)
        .and_return(decode_id)

      get :done, code: "v5v3q7kzhgrctd6qfdpvvo5uz"

      expect(response.status).to eq 200
    end

    it "logs out if velum is accessed from a non registered host" do
      allow_any_instance_of(OpenIDConnect::Client).to receive(:access_token!)
        .and_return(access_token)

      allow(Velum::Kubernetes).to receive(:kubeconfig)
        .and_return(kubeconfig)

      allow(application_controller).to receive(:accessible_hosts)
        .and_return(["http://some.illegal.host"])

      get :done, code: "v5v3q7kzhgrctd6qfdpvvo5uz"

      expect(flash.alert).to match(/You have been logged out/)
      expect(response.status).to eq 302
    end

    it "redirects to the dashboard if the id token has an invalid nonce" do
      allow(subject).to receive(:verify_host).and_return(true)

      allow_any_instance_of(OpenIDConnect::Client).to receive(:access_token!)
        .and_return(access_token)

      allow(Velum::Kubernetes).to receive(:kubeconfig)
        .and_return(kubeconfig)

      allow(OpenIDConnect::Discovery::Provider::Config).to receive(:discover!)
        .and_return(config)

      allow_any_instance_of(OpenIDConnect::Client).to receive(:authorization_code=)
      allow(OpenIDConnect::ResponseObject::IdToken).to receive(:decode)
        .and_raise(OpenIDConnect::ResponseObject::IdToken::InvalidNonce, "Invalid Nonce")

      get :done, code: "v5v3q7kzhgrctd6qfdpvvo5uz"

      expect(response.status).to eq 302
      expect(flash.alert).to match(/Invalid Nonce/)
    end
  end

  describe "GET /kubeconfig" do
    before do
      setup_done
      external_fqdn_pillar
      allow_any_instance_of(OidcController).to receive(:lookup_config)
      allow_any_instance_of(OidcController).to receive(:verify_host).and_return(true)
    end

    it "downloads the kubeconfig file" do
      get :kubeconfig, email: "test@test.com", client_id: "client-id", client_secret: "secret",
                       id_token: "token", idp_issuer_url: "https://issuer-url",
                       refresh_token: "token"

      expect(response.status).to eq 200
    end
  end
end
# rubocop:enable ExampleLength,RSpec/AnyInstance,RSpec/VerifiedDoubles,RSpec/NamedSubject
