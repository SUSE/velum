# frozen_string_literal: true
require "rails_helper"

describe SaltHandler::MinionStart do
  let(:minion_id) do
    "3bcb66a2e50646dcabf779e50c6f3232"
  end

  let(:salt_event) do
    event_data = {
      "_stamp" => "2017-01-24T13:30:20.794326",
      "pretag" => nil, "cmd" => "_minion_event", "tag" => "minion_start",
      "data" => "Minion 3bcb66a2e50646dcabf779e50c6f3232 started at Tue Jan 24 13:30:20 2017",
      "id" => minion_id
    }.to_json

    FactoryGirl.create(:salt_event, tag: "minion_start", data: event_data)
  end

  let(:ca_salt_event) do
    event_data = {
      "_stamp" => "2017-01-24T13:30:20.794326",
      "pretag" => nil, "cmd" => "_minion_event", "tag" => "minion_start",
      "data" => "Minion ca started at Tue Jan 24 13:30:20 2017",
      "id" => "ca"
    }.to_json

    FactoryGirl.create(:salt_event, tag: "minion_start", data: event_data)
  end

  describe "process_event" do
    it "creates a new Minion when one with the specified id does not exist" do
      handler = described_class.new(salt_event)
      VCR.use_cassette("salt/process_event", record: :none) do
        expect { handler.process_event }.to change { Minion.where(minion_id: minion_id).count }
          .from(0).to(1)
      end
    end

    # rubocop:disable RSpec/ExampleLength
    it "does not create a new Minion if one with the specified id already exists" do
      handler = described_class.new(salt_event)
      FactoryGirl.create(:minion, minion_id: minion_id)

      VCR.use_cassette("salt/process_event", record: :none) do
        expect { handler.process_event }
          .not_to change { Minion.where(minion_id: minion_id).count }
      end
    end
    # rubocop:enable RSpec/ExampleLength

    it "does not create a new Minion if the event has id: 'ca'" do
      handler = described_class.new(ca_salt_event)

      VCR.use_cassette("salt/process_event", record: :none) do
        expect { handler.process_event }
          .not_to change { Minion.where(minion_id: "ca").count }
      end
    end
  end
end
