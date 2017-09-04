# frozen_string_literal: true
require "rails_helper"

describe SaltHandler::OrchestrationResult do
  let(:successful_orchestration_result) do
    event_data = {
      "fun_args" => ["orch.kubernetes", { "orchestration_jid" => "20170706104527757673" }],
      "jid"      => "20170706104527757673",
      "return"   => { "retcode" => 0 },
      "success"  => true,
      "_stamp"   => "2017-07-06T10:45:54.734096",
      "fun"      => "runner.state.orchestrate",
      "user"     => "root"
    }.to_json

    FactoryGirl.create(:salt_event,
                       tag:  "salt/run/20170706104527757673/ret",
                       data: event_data)
  end

  let(:mid_successful_orchestration_result) do
    event_data = {
      "fun_args" => ["orch.kubernetes", { "orchestration_jid" => "20170706104527757673" }],
      "jid"      => "20170706104527757673",
      "return"   => { "retcode" => 1 },
      "success"  => true,
      "_stamp"   => "2017-07-06T10:45:54.734096",
      "fun"      => "runner.state.orchestrate",
      "user"     => "root"
    }.to_json

    FactoryGirl.create(:salt_event,
                       tag:  "salt/run/20170706104527757673/ret",
                       data: event_data)
  end

  let(:failed_orchestration_result) do
    event_data = {
      "fun_args" => ["orch.kubernetes", { "orchestration_jid" => "20170706104527757673" }],
      "jid"      => "20170706104527757673",
      "return"   => { "retcode" => 1 },
      "success"  => false,
      "_stamp"   => "2017-07-06T10:45:54.734096",
      "fun"      => "runner.state.orchestrate",
      "user"     => "root"
    }.to_json

    FactoryGirl.create(:salt_event,
                       tag:  "salt/run/20170706104527757673/ret",
                       data: event_data)
  end

  describe "process_event" do
    let(:pending_minion) do
      FactoryGirl.create(:minion,
                         minion_id: "3bcb66a2e50646dcabf779e50c6f3232",
                         fqdn:      "minion0.k8s.local",
                         highstate: :pending)
    end

    let(:applied_minion) do
      FactoryGirl.create(:minion,
                         minion_id: "1d0f874813f1fbd59bd5f2cdae5c4621",
                         fqdn:      "minion1.k8s.local",
                         highstate: :applied)
    end

    before do
      pending_minion
      applied_minion
      FactoryGirl.create(:orchestration,
                         jid: "20170706104527757673")
    end

    describe "with a successful orchestration result" do
      let(:handler) { described_class.new(successful_orchestration_result) }
      it "does set pending minions to successful" do
        expect { handler.process_event }.to change { Minion.pending.count }.from(1).to(0)
      end
      it "does affect applied minions" do
        expect { handler.process_event }.to change { Minion.applied.count }.from(1).to(2)
      end
    end

    describe "with a mid-successful orchestration result" do
      let(:handler) { described_class.new(mid_successful_orchestration_result) }
      it "marks pending minions as failed" do
        expect { handler.process_event }.to change { pending_minion.reload.highstate }
          .from("pending").to("failed")
      end
      it "does not affect applied minions" do
        expect { handler.process_event }.not_to change { Minion.applied.count }.from(1)
      end
    end

    describe "with a failed orchestration result" do
      let(:handler) { described_class.new(failed_orchestration_result) }
      it "marks pending minions as failed" do
        expect { handler.process_event }.to change { pending_minion.reload.highstate }
          .from("pending").to("failed")
      end
      it "does not affect applied minions" do
        expect { handler.process_event }.not_to change { Minion.applied.count }.from(1)
      end
    end
  end
end
