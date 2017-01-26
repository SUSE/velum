# frozen_string_literal: true
require "rails_helper"
require "pharos/salt"

describe Pharos::SaltApi do
  before do
    ENV["PHAROS_SALT_HOST"] = "127.0.0.1"
    ENV["PHAROS_SALT_PORT"] = "8000"
  end

  let(:salt_api) { Class.new { include Pharos::SaltApi } }

  it "the instance responds to token" do
    expect(salt_api.new).to respond_to(:token)
  end

  it "the instance responds to token=" do
    expect(salt_api.new).to respond_to(:token=)
  end

  context "given a client" do
    let(:client) { salt_api.new }

    it "has an empty token cache" do
      expect(client.token).to be_nil
    end

    it "saves the token in the client token cache" do
      VCR.use_cassette("salt/fetch_minion", record: :none) do
        client.perform_request(endpoint: "/minions/minion1", method: "get")
        expect(client.token).not_to be_nil
      end
    end
  end
end
