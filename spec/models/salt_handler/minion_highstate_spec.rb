# frozen_string_literal: true
require "rails_helper"

describe SaltHandler::MinionHighstate do
  let(:salt_event) do
    event_data = {
      "fun_args" => [{ "queue" => false, "concurrent" => false, "saltenv" => "base" }],
      "jid"      => "20170201134300539551",
      "return"   => "some_return",
      "retcode"  => 0,
      "success"  => true,
      "cmd"      => "_return",
      "_stamp"   => "2017-02-01T13:43:00.348440",
      "fun"      => "state.highstate",
      "id"       => "3bcb66a2e50646dcabf779e50c6f3232",
      "out"      => "highstate"
    }.to_json

    FactoryGirl.create(:salt_event,
      tag:  "salt/job/20170201134101334637/ret/3bcb66a2e50646dcabf779e50c6f3232",
      data: event_data)
  end

  describe "process_event" do
    let(:handler) { described_class.new(salt_event) }
    let(:matching_minion) do
      FactoryGirl.create(:minion,
                         minion_id: "3bcb66a2e50646dcabf779e50c6f3232",
                         fqdn:      "minion0.k8s.local",
                         highstate: :pending)
    end
    let(:matching_minion_with_no_pending_highstate) do
      FactoryGirl.create(:minion,
                         minion_id: "18e57e95171048bfbd6346a22d4bbb2a",
                         fqdn:      "minion1.k8s.local",
                         highstate: :failed)
    end

    it "returns false if no matching Minion exists" do
      VCR.use_cassette("salt/process_event", record: :none) do
        expect(handler.process_event).to be(false)
      end
    end

    it "returns false if a matching Minion exists but has no pending highstate" do
      matching_minion_with_no_pending_highstate

      VCR.use_cassette("salt/process_event", record: :none) do
        expect(handler.process_event).to be(false)
      end
    end

    it "return true if a matching Minion with pending highstate exists" do
      matching_minion

      VCR.use_cassette("salt/process_event", record: :none) do
        expect(handler.process_event).to be(true)
      end
    end

    it "updates the matching Minion's highstate column" do
      matching_minion

      VCR.use_cassette("salt/process_event", record: :none) do
        expect { handler.process_event }
          .to change { matching_minion.reload.highstate }.from("pending").to("applied")
      end
    end
  end
end
