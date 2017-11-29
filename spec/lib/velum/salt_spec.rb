require "rails_helper"
require "velum/salt"

describe Velum::Salt do
  describe "call" do
    it "returns the bare response object and its parsed body" do
      VCR.use_cassette("salt/request_no_args", record: :none) do
        res, hsh = described_class.call(action: "test.ping")
        expect(hsh).to eq JSON.parse(res.body)
      end
    end

    it "performs a request with no arguments" do
      VCR.use_cassette("salt/request_no_args", record: :none) do
        _, hsh = described_class.call(action: "test.ping")
        expect(hsh["return"][0]["local"]).to be_truthy
      end
    end
  end

  describe "minions" do
    it "fetches a list of minions" do
      VCR.use_cassette("salt/fetch_minions", record: :none) do
        expect(described_class.minions.size).to eq 2
      end
    end
  end

  describe "pending_minions" do
    it "fetches a list of pending minions" do
      VCR.use_cassette("salt/fetch_pending_minions", record: :none) do
        expect(described_class.pending_minions.size).to eq 1
      end
    end
  end

  describe "orchestration" do
    it "runs the orchestration in async mode" do
      VCR.use_cassette("salt/orchestrate_async", record: :none) do
        _, hsh = described_class.orchestrate
        expect(hsh["return"].count).to eq 1
      end
    end
  end

  describe "update orchestration" do
    it "runs the orchestration in async mode" do
      VCR.use_cassette("salt/update_orchestrate_async", record: :none) do
        _, hsh = described_class.update_orchestration
        expect(hsh["return"].count).to eq 1
      end
    end
  end

  describe "update_status" do
    it "returns the update status of the given nodes" do
      VCR.use_cassette("salt/update_status", record: :none) do
        needed, failed = described_class.update_status
        # In the VCR both values were set to true, so we can check this in a
        # single 'expect' statement.
        expect(needed.first["admin"] && failed.first["admin"]).to be_truthy
      end
    end
  end

  describe "jobs" do
    it "returns the list of jobs" do
      VCR.use_cassette("salt/job_list", record: :none) do
        expect(described_class.jobs).not_to be_empty
      end
    end

    it "shows one job details in particular" do
      VCR.use_cassette("salt/job_details", record: :none) do
        expect(described_class.job(jid: "20170907082713587615").keys).to eq ["info", "return"]
      end
    end
  end
end
