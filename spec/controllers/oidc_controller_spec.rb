# frozen_string_literal: true

require "rails_helper"

# rubocop:disable ExampleLength,MultipleExpectations,MessageSpies,RSpec/AnyInstance
RSpec.describe OidcController, type: :controller do
  let(:external_fqdn_pillar) { create(:external_fqdn_pillar) }

  describe "GET /oidc" do
    it "returns a 302 if the orchestration didn't yet finish" do
      VCR.use_cassette("kubeconfig/cluster_not_ready", record: :none) do
        setup_undone

        allow_any_instance_of(OidcController).to receive(:verify_host)
          .and_return(true)

        get :index

        expect(response.status).to eq 302
        expect(response.header["Location"]).to eq "http://test.host/"
      end
    end

    it "redirects to Dex if orchestration is done" do
      # VCR can do the salt stuff, we'll just mock Dex
      VCR.use_cassette("kubeconfig/cluster_ready", record: :none) do
        setup_done
        external_fqdn_pillar

        config = instance_double("config")
        expect(config).to receive(:scopes_supported).and_return(["foo"])
        expect(config).to receive(:jwks_uri).and_return("http://example.org/jwks")
        expect(config).to receive(:authorization_endpoint)
          .and_return("http://example.org/auth")
        expect(config).to receive(:token_endpoint).and_return("http://example.org/token")
        expect(config).to receive(:userinfo_endpoint).and_return("http://example.org/user")

        allow(OpenIDConnect::Discovery::Provider::Config).to receive(:discover!)
          .and_return(config)

        allow_any_instance_of(OidcController).to receive(:verify_host)
          .and_return(true)

        get :index

        expect(response.status).to eq 302
        expect(response.header["Location"]).to include "/auth"
      end
    end
  end

  describe "GET /done" do
    render_views

    before do
      setup_done
      external_fqdn_pillar
    end

    it "redirects you to the kubeconfig if auth succeeds" do
      # VCR can do the salt stuff, we'll just mock Dex
      VCR.use_cassette("kubeconfig/cluster_ready2", record: :none) do
        id_token1 = instance_double("id_token1")

        id_token2 = instance_double("id_token2")
        allow(id_token2).to receive(:verify!)
        allow(id_token2).to receive(:iss).and_return("https://issuer-url")
        allow(id_token2).to receive(:raw_attributes).and_return("email" => "test@test.com")

        expect(OpenIDConnect::ResponseObject::IdToken).to receive(:decode)
          .and_return(id_token2)

        config = instance_double("config")
        expect(config).to receive(:scopes_supported).and_return(["foo"])
        expect(config).to receive(:jwks_uri).and_return("http://example.org/jwks")
        expect(config).to receive(:authorization_endpoint)
          .and_return("http://example.org/auth")
        expect(config).to receive(:token_endpoint).and_return("http://example.org/token")
        expect(config).to receive(:userinfo_endpoint).and_return("http://example.org/user")
        expect(config).to receive(:jwks)

        allow(OpenIDConnect::Discovery::Provider::Config).to receive(:discover!)
          .and_return(config)
        allow(OpenIDConnect::ResponseObject::IdToken).to receive(:decode)

        access_token = instance_double("access_token")
        allow(access_token).to receive(:id_token).and_return(id_token1)
        allow(access_token).to receive(:client)
          .and_return(OpenStruct.new(identifier: "identifier", secret: "secret"))
        allow(access_token).to receive(:refresh_token).and_return("some-token")

        client = instance_double("client")
        expect(client).to receive(:access_token!).and_return(access_token)
        expect(client).to receive(:authorization_code=)

        expect(OpenIDConnect::Client).to receive(:new).and_return(client)

        allow_any_instance_of(OidcController).to receive(:verify_host)
          .and_return(true)

        get :done, { code: "v5v3q7kzhgrctd6qfdpvvo5uz" }, nonce: "foobar"

        expect(response.status).to eq 200
        expect(response.body).to match(/window.location.href/)
      end
    end

    it "logs out if velum is accessed from a non registered host" do
      # VCR can do the salt stuff, we'll just mock Dex
      VCR.use_cassette("kubeconfig/cluster_ready2", record: :none) do
        allow_any_instance_of(ApplicationController).to receive(:accessible_hosts)
          .and_return(["http://some.legal.host"])

        get :done, { code: "v5v3q7kzhgrctd6qfdpvvo5uz" }, nonce: "foobar"

        expect(flash.alert).to match(/You have been logged out/)
        expect(response.status).to eq 302
      end
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
# rubocop:enable ExampleLength,MultipleExpectations,MessageSpies,RSpec/AnyInstance
