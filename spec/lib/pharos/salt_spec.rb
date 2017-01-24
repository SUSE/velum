# frozen_string_literal: true
require "rails_helper"
require "pharos/salt"

describe Pharos::Salt do
  before do
    ENV["PHAROS_SALT_HOST"] = "example.test.lan"
    ENV["PHAROS_SALT_PORT"] = "5900"
  end

  describe "call" do
    it "returns the bare response object and its parsed body" do
      VCR.use_cassette("salt/request_no_args", record: :none) do
        res, hsh = described_class.new.call("*", "test.ping")
        expect(hsh).to eq JSON.parse(res.body)
      end
    end

    it "performs a request with no arguments" do
      VCR.use_cassette("salt/request_no_args", record: :none) do
        _, hsh = described_class.new.call("*", "test.ping")
        expect(hsh["return"][0]["local"]).to be_truthy
      end
    end
  end

  describe "minions" do
    it "fetches a list of minions" do
      VCR.use_cassette("salt/fetch_minions", record: :none) do
        expect(described_class.new.minions.size).to eq 2
      end
    end

    it "fetches a single minion" do
      VCR.use_cassette("salt/fetch_minion", record: :none) do
        expect(described_class.new.minions(1).size).to eq 1
      end
    end
  end
end
