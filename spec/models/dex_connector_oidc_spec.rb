require "rails_helper"

describe DexConnectorOidc, type: :model do
  good_provider_url = "http://your.fqdn.here:5556/dex"
  mismatched_provider_url = "http://your.fqdn.here:5556/bad"
  malformed_urls = [
    "ftp://fqdn.is.invalid",
    "",
    "http:://x",
    "fqdn.is.invalid",
    "http://user:fqdn.is.invalid/"
  ]
  bad_but_well_formed_http_urls = [
    "http://fqdn.is.invalid",
    "http://user@fqdn.is.invalid/",
    "https://user:pass@fqdn.is.invalid/",
    # "https://192.0.2.0",      # RFC5737 TEST-NET-1, should trigger timeout
    "http://192.0.2.0:65537", # too-high port
    "https://1.2.3.256"       # invalid IP address
  ]

  VCR.use_cassette("oidc/validate_connector", allow_playback_repeats: true, record: :none) do
    subject(:connector) do
      described_class.new(
        name:          "oidc1",
        provider_url:  good_provider_url,
        callback_url:  good_provider_url,
        basic_auth:    true,
        client_id:     "client",
        client_secret: "secret_string"
      )
    end
  end

  [:name, :basic_auth, :client_id, :client_secret, :provider_url, :callback_url].each do |field|
    it "verifies " + field.to_s + " field" do
      VCR.use_cassette("oidc/validate_connector", allow_playback_repeats: true, record: :none) do
        expect(connector).to validate_presence_of(field)
      end
    end
  end

  malformed_urls.each do |bad_url|
    [:callback_url, :provider_url].each do |field|
      it "rejects non-nttp format URL '#{bad_url}' for " + field.to_s do
        VCR.use_cassette("oidc/validate_connector", allow_playback_repeats: true, record: :none) do
          connector[field] = bad_url
          expect(connector).not_to be_valid
        end
      end
    end
  end

  bad_but_well_formed_http_urls.each do |sketchy_url|
    it "accepts well-formed invalid issuer URL '#{sketchy_url}' for callback" do
      VCR.use_cassette("oidc/validate_connector", allow_playback_repeats: true, record: :none) do
        connector.callback_url = sketchy_url
        expect(connector).to be_valid
      end
    end
    it "rejects well-formed invalid issuer URL for issuer" do
      connector.provider_url = sketchy_url
      expect(connector).not_to be_valid
    end
  end

  [:callback_url, :provider_url].each do |field|
    it "accepts valid issuer URL for " + field.to_s do
      VCR.use_cassette("oidc/validate_connector", allow_playback_repeats: true, record: :none) do
        connector[field] = good_provider_url
        expect(connector).to be_valid
      end
    end
  end

  it "rejects mismatched issuer URL" do
    VCR.use_cassette("oidc/invalid_connector", allow_playback_repeats: true, record: :none) do
      connector[:provider_url] = mismatched_provider_url
      expect(connector).not_to be_valid
    end
  end

  # Using VCR seems to suppress the creation of SocketError, so raise it here.
  it "catches an elusive exception just for code coverage" do
    # rubocop:disable RSpec/MessageSpies
    expect(OidcProviderValidator).to receive(:validate_issuer?).and_raise(SocketError)
    # rubocop:enable RSpec/MessageSpies
    connector.provider_url = good_provider_url
    expect(connector).not_to be_valid
  end

  # Raise timeout error instead of making a connection actually time out
  it "catches a TimeoutError" do
    # rubocop:disable RSpec/MessageSpies
    expect(OidcProviderValidator).to receive(:validate_issuer?).and_raise(TimeoutError)
    # rubocop:enable RSpec/MessageSpies
    connector.provider_url = good_provider_url
    expect(connector).not_to be_valid
  end

  # Raise OpenSSL error instead of making a bad cert
  it "catches an OpenSSL Error" do
    # rubocop:disable RSpec/MessageSpies
    expect(OidcProviderValidator).to receive(:validate_issuer?).and_raise(OpenSSL::SSL::SSLError)
    # rubocop:enable RSpec/MessageSpies
    connector.provider_url = good_provider_url
    expect(connector).not_to be_valid
  end
end
