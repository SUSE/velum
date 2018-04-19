require "rails_helper"

describe SaltHandler::OrchestrationResult do
  let(:orchestration) do
    FactoryGirl.create(:orchestration,
                       jid: "20170706104527757673")
  end

  let(:removal_orchestration) do
    FactoryGirl.create(:removal_orchestration,
                       jid:    "20170706104527757673",
                       params: { target: pending_removal_minion.minion_id })
  end

  let(:force_removal_orchestration) do
    FactoryGirl.create(:force_removal_orchestration,
                       jid:    "20170706104527757673",
                       params: { target: pending_removal_minion.minion_id })
  end

  let(:successful_orchestration_result) do
    event_data = {
      "fun_args" => ["orch.kubernetes", { "orchestration_jid" => orchestration.jid }],
      "jid"      => orchestration.jid,
      "return"   => { "retcode" => 0 },
      "success"  => true,
      "_stamp"   => "2017-07-06T10:45:54.734096",
      "fun"      => "runner.state.orchestrate",
      "user"     => "root"
    }.to_json

    FactoryGirl.create(:salt_event,
                       tag:  "salt/run/#{orchestration.jid}/ret",
                       data: event_data)
  end

  let(:removal_params) do
    { "pillar"            => { "target" => removal_orchestration.params["target"] },
      "orchestration_jid" => removal_orchestration.jid }
  end

  let(:successful_force_removal_orchestration_result) do
    event_data = {
      "fun_args" => ["orch.force-removal", removal_params],
      "jid"      => force_removal_orchestration.jid,
      "return"   => { "retcode" => 0 },
      "success"  => true,
      "_stamp"   => "2017-07-06T10:45:54.734096",
      "fun"      => "runner.state.orchestrate",
      "user"     => "root"
    }.to_json

    FactoryGirl.create(:salt_event,
                       tag:  "salt/run/#{force_removal_orchestration.jid}/ret",
                       data: event_data)
  end

  let(:failed_force_removal_orchestration_result) do
    event_data = {
      "fun_args" => ["orch.force-removal", removal_params],
      "jid"      => force_removal_orchestration.jid,
      "return"   => { "retcode" => 1 },
      "success"  => false,
      "_stamp"   => "2017-07-06T10:45:54.734096",
      "fun"      => "runner.state.orchestrate",
      "user"     => "root"
    }.to_json

    FactoryGirl.create(:salt_event,
                       tag:  "salt/run/#{force_removal_orchestration.jid}/ret",
                       data: event_data)
  end

  let(:successful_removal_orchestration_result) do
    event_data = {
      "fun_args" => ["orch.removal", removal_params],
      "jid"      => removal_orchestration.jid,
      "return"   => { "retcode" => 0 },
      "success"  => true,
      "_stamp"   => "2017-07-06T10:45:54.734096",
      "fun"      => "runner.state.orchestrate",
      "user"     => "root"
    }.to_json

    FactoryGirl.create(:salt_event,
                       tag:  "salt/run/#{removal_orchestration.jid}/ret",
                       data: event_data)
  end

  let(:mid_successful_orchestration_result) do
    event_data = {
      "fun_args" => ["orch.kubernetes", { "orchestration_jid" => orchestration.jid }],
      "jid"      => orchestration.jid,
      "return"   => { "retcode" => 1 },
      "success"  => true,
      "_stamp"   => "2017-07-06T10:45:54.734096",
      "fun"      => "runner.state.orchestrate",
      "user"     => "root"
    }.to_json

    FactoryGirl.create(:salt_event,
                       tag:  "salt/run/#{orchestration.jid}/ret",
                       data: event_data)
  end

  let(:failed_orchestration_result) do
    event_data = {
      "fun_args" => ["orch.kubernetes", { "orchestration_jid" => orchestration.jid }],
      "jid"      => orchestration.jid,
      "return"   => { "retcode" => 1 },
      "success"  => false,
      "_stamp"   => "2017-07-06T10:45:54.734096",
      "fun"      => "runner.state.orchestrate",
      "user"     => "root"
    }.to_json

    FactoryGirl.create(:salt_event,
                       tag:  "salt/run/#{orchestration.jid}/ret",
                       data: event_data)
  end

  let(:failed_removal_orchestration_result) do
    event_data = {
      "fun_args" => ["orch.removal", removal_params],
      "jid"      => removal_orchestration.jid,
      "return"   => { "retcode" => 1 },
      "success"  => false,
      "_stamp"   => "2017-07-06T10:45:54.734096",
      "fun"      => "runner.state.orchestrate",
      "user"     => "root"
    }.to_json

    FactoryGirl.create(:salt_event,
                       tag:  "salt/run/#{removal_orchestration.jid}/ret",
                       data: event_data)
  end

  describe "process_event" do
    let(:pending_minion) do
      FactoryGirl.create(:minion,
                         minion_id: "3bcb66a2e50646dcabf779e50c6f3232",
                         role:      :worker,
                         fqdn:      "minion0.k8s.local",
                         highstate: :pending)
    end

    let(:applied_minion) do
      FactoryGirl.create(:minion,
                         minion_id: "1d0f874813f1fbd59bd5f2cdae5c4621",
                         role:      :worker,
                         fqdn:      "minion1.k8s.local",
                         highstate: :applied)
    end

    let(:pending_removal_minion) do
      FactoryGirl.create(:minion,
                         minion_id: "60cd82bd1af545c2b2b073badc0b483e",
                         role:      :worker,
                         fqdn:      "minion2.k8s.local",
                         highstate: :pending_removal)
    end

    before do
      pending_minion
      applied_minion
    end

    describe "with a successful orchestration result" do
      let(:handler) { described_class.new(successful_orchestration_result) }

      it "does set pending minions to successful" do
        expect { handler.process_event }.to change { Minion.cluster_role.pending.count }
          .from(1).to(0)
      end
      it "does affect applied minions" do
        expect { handler.process_event }.to change { Minion.cluster_role.applied.count }
          .from(1).to(2)
      end
    end

    describe "with a mid-successful orchestration result" do
      let(:handler) { described_class.new(mid_successful_orchestration_result) }

      it "marks pending minions as applied" do
        expect { handler.process_event }.to change { pending_minion.reload.highstate }
          .from("pending").to("applied")
      end
      it "does affect applied minions" do
        expect { handler.process_event }.to change { Minion.cluster_role.applied.count }
          .from(1).to(2)
      end
    end

    describe "with a failed orchestration result" do
      let(:handler) { described_class.new(failed_orchestration_result) }

      it "marks pending minions as failed" do
        expect { handler.process_event }.to change { pending_minion.reload.highstate }
          .from("pending").to("failed")
      end
      it "does not affect applied minions" do
        expect { handler.process_event }.not_to change { Minion.cluster_role.applied.count }.from(1)
      end
    end

    describe "with a successful removal orchestration" do
      let(:handler) { described_class.new(successful_removal_orchestration_result) }

      before do
        FactoryGirl.create(:removal_orchestration,
                           jid:    "20170706104527757673",
                           params: { target: pending_removal_minion.minion_id })
      end

      it "destroys the minion with pending_removal state" do
        expect { handler.process_event }.to change { Minion.cluster_role.pending_removal.count }
          .from(1).to(0)
      end
    end

    describe "with a failed removal orchestration" do
      let(:handler) { described_class.new(failed_removal_orchestration_result) }

      before do
        FactoryGirl.create(:removal_orchestration,
                           jid:    "20170706104527757673",
                           params: { target: pending_removal_minion.minion_id })
      end

      it "marks the minion with removal_failed state if it failed" do
        expect { handler.process_event }.to change { Minion.cluster_role.removal_failed.count }
          .from(0).to(1)
      end
    end

    describe "with a successful force removal orchestration" do
      let(:handler) { described_class.new(successful_force_removal_orchestration_result) }

      before do
        FactoryGirl.create(:force_removal_orchestration,
                           jid:    "20170706104527757673",
                           params: { target: pending_removal_minion.minion_id })
      end

      it "destroys the minion with pending_removal state" do
        expect { handler.process_event }.to change { Minion.cluster_role.pending_removal.count }
          .from(1).to(0)
      end
    end

    describe "with a failed force removal orchestration" do
      let(:handler) { described_class.new(failed_force_removal_orchestration_result) }

      before do
        FactoryGirl.create(:force_removal_orchestration,
                           jid:    "20170706104527757673",
                           params: { target: pending_removal_minion.minion_id })
      end

      it "destroys the minion with pending_removal state" do
        expect { handler.process_event }.to change { Minion.cluster_role.pending_removal.count }
          .from(1).to(0)
      end
    end
  end
end
