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
    it "runs the update orchestration in async mode" do
      VCR.use_cassette("salt/update_orchestrate_async", record: :none) do
        _, hsh = described_class.update_orchestration
        expect(hsh["return"].count).to eq 1
      end
    end
  end

  describe "removal orchestration" do
    it "runs the removal orchestration in async mode" do
      VCR.use_cassette("salt/removal_orchestrate_async", record: :none) do
        _, hsh = described_class.removal_orchestration params: { target: "some-minion" }
        expect(hsh["return"].count).to eq 1
      end
    end
  end

  describe "force removal orchestration" do
    it "runs the force removal orchestration in async mode" do
      VCR.use_cassette("salt/force_removal_orchestrate_async", record: :none) do
        _, hsh = described_class.force_removal_orchestration params: { target: "some-minion" }
        expect(hsh["return"].count).to eq 1
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

  describe "#build_cloud_cluster" do
    let(:count) { rand(49) + 1 } # 1..50

    it "calls cloud.profile salt function the specified number of times" do
      VCR.use_cassette("salt/cloud_profile", record: :none, allow_playback_repeats: true) do
        responses = described_class.build_cloud_cluster(count)
        expect(responses.length).to eq(count)
        expect(responses).to all(be_a(Net::HTTPOK))
      end
    end
  end

  describe "remove_minion" do
    minion_id = "81ad05b9d7ae4d26a83c421b64ca1952"
    it "removes a minion" do
      VCR.use_cassette("salt/remove_minion", record: :none) do
        responses = described_class.remove_minion(minion_id: minion_id)
        expect(responses["return"][0]["data"]["success"]).to be(true)
      end
    end
  end

  describe "reject_minion" do
    minion_id = "81ad05b9d7ae4d26a83c421b64ca1952"
    it "rejects a minion" do
      VCR.use_cassette("salt/reject_minion", record: :none) do
        responses = described_class.reject_minion(minion_id: minion_id)
        expect(responses["return"][0]["data"]["success"]).to be(true)
      end
    end
  end
end
