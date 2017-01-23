# frozen_string_literal: true
require "rails_helper"

describe SaltHandler::MinionStart do
  let(:salt_event) do
    event_data = {
      "_stamp" => "2017-01-24T13:30:20.794326",
      "pretag" => nil, "cmd" => "_minion_event", "tag" => "minion_start",
      "data" => "Minion MyMinion started at Tue Jan 24 13:30:20 2017",
      "id" => "MyMinion"
    }.to_json

    FactoryGirl.create(:salt_event, tag: "minion_start", data: event_data)
  end

  describe "process_event" do
    it "creates a new Minion when one with the specified id does not exist" do
      handler = described_class.new(salt_event)
      expect { handler.process_event }
        .to change { Minion.where(hostname: "MyMinion").count }.from(0).to(1)
    end

    it "does not create a new Minion if one with the specified id already exists" do
      handler = described_class.new(salt_event)
      FactoryGirl.create(:minion, hostname: "MyMinion")

      expect { handler.process_event }
        .not_to change { Minion.where(hostname: "MyMinion").count }
    end
  end
end
