# frozen_string_literal: true
require "rails_helper"
require "velum/salt"

describe Velum::SaltApi do
  let(:salt_api) { Class.new { include Velum::SaltApi } }

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

  context "when a HTTP/socket error happens" do
    before { allow(Net::HTTP).to receive(:start).and_raise(Errno::ECONNREFUSED) }

    it "raises SaltConnectionException" do
      expect do
        salt_api.perform_request(endpoint: "/minions/minion1", method: "get")
      end.to raise_error(Velum::SaltApi::SaltConnectionException)
    end
  end
end
