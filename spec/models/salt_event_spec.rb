# frozen_string_literal: true
require "rails_helper"

describe SaltEvent do
  describe ".process_next_event" do
    let(:leftover_event) do
      # not timed out
      FactoryGirl.create(
        :salt_event, worker_id: "this_worker", processed_at: nil,
        taken_at: (SaltEvent::PROCESS_TIMEOUT_MIN - 2).minutes.ago
      )
    end

    let(:timedout_event) do
      FactoryGirl.create(
        :salt_event, worker_id: "other_worker", processed_at: nil,
        taken_at: (SaltEvent::PROCESS_TIMEOUT_MIN + 2).minutes.ago
      )
    end

    let(:new_minion_event) do
      event_data = {
        "_stamp" => "2017-01-24T13:30:20.794326",
        "pretag" => nil, "cmd" => "_minion_event", "tag" => "minion_start",
        "data" => "Minion MyMinion started at Tue Jan 24 13:30:20 2017",
        "id" => "MyMinion"
      }.to_json

      FactoryGirl.create(:salt_event, tag: "minion_start", data: event_data)
    end

    it "processes new-minion events" do
      new_minion_event

      expect do
        described_class.process_next_event(worker_id: "MyWorker")
      end.to change { Minion.where(hostname: "MyMinion").count }.by(1)
    end

    it "processes irrelevant events" do
      FactoryGirl.create(:salt_event, tag: "nobody_cares_about_this_event")

      expect do
        described_class.process_next_event(worker_id: "MyWorker")
      end.to change { described_class.where(processed_at: nil).count }.from(1).to(0)
    end

    it "processes events not assigned to any worker" do
      event = FactoryGirl.create(:salt_event, worker_id: nil)
      expect do
        described_class.process_next_event(worker_id: "MyWorker")
      end.to change { event.reload.processed_at }.from(nil).to(Time)
    end

    it "processes events assigned to the same worker (leftovers from dying?)" do
      expect do
        described_class.process_next_event(worker_id: "this_worker")
      end.to change { leftover_event.reload.processed_at }.from(nil).to(Time)
    end

    it "processes events assigned to any worker but not completed for more"\
      "than PROCESS_TIMEOUT_MIN minutes" do
      expect { described_class.process_next_event(worker_id: "this_worker") }
        .to change { timedout_event.reload.processed_at }.from(nil).to(Time)

      expect(timedout_event.worker_id).to eq("this_worker")
    end
  end

  describe "#process" do
    let(:salt_event) do
      FactoryGirl.create(:salt_event, processed_at: nil)
    end

    it "updates the processed_at column" do
      expect { salt_event.process! }
        .to change { salt_event.processed_at }.from(nil).to(Time)
    end
  end

  describe "parsed_data" do
    let(:salt_event) { FactoryGirl.create(:salt_event) }

    it "parses the data as JSON" do
      parsed_data = salt_event.parsed_data

      expect(parsed_data.keys).to eq(["_stamp", "pretag", "cmd", "tag", "data", "id"])
    end
  end

  describe "handler" do
    it "must return an instance of SaltHandler::MinionStart when the tag is 'minion_start'" do
      handler = described_class.new(tag: "minion_start", data: "{}").handler

      expect(handler).to be_an_instance_of(SaltHandler::MinionStart)
    end

    it "must return an instance of SaltHandler::MinionHighstate" do
      salt_event = described_class.new(
        tag:  "salt/job/12345/ret/MyMinion",
        data: { fun: "state.highstate" }.to_json
      )

      expect(salt_event.handler).to be_an_instance_of(SaltHandler::MinionHighstate)
    end
  end
end
