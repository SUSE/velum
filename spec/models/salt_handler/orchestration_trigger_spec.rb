require "rails_helper"

describe SaltHandler::OrchestrationTrigger do
  let(:bootstrap_orchestration) do
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
                       tag:  "salt/run/20170706104527757673/new",
                       data: event_data)
  end

  let(:upgrade_orchestration) do
    event_data = {
      "fun_args" => ["orch.update", { "orchestration_jid" => "20170706104527757673" }],
      "jid"      => "20170706104527757673",
      "return"   => { "retcode" => 0 },
      "success"  => true,
      "_stamp"   => "2017-07-06T10:45:54.734096",
      "fun"      => "runner.state.orchestrate",
      "user"     => "root"
    }.to_json

    FactoryGirl.create(:salt_event,
                       tag:  "salt/run/20170706104527757673/new",
                       data: event_data)
  end

  let(:migration_orchestration) do
    event_data = {
      "fun_args" => [
        "orch.migration",
        {
          "pillar"            => { "migration" => true },
          "orchestration_jid" => "20170706104527757673"
        }
      ],
      "jid"      => "20170706104527757673",
      "return"   => { "retcode" => 0 },
      "success"  => true,
      "_stamp"   => "2017-07-06T10:45:54.734096",
      "fun"      => "runner.state.orchestrate",
      "user"     => "root"
    }.to_json

    FactoryGirl.create(:salt_event,
                       tag:  "salt/run/20170706104527757673/new",
                       data: event_data)
  end

  let(:removal_orchestration) do
    event_data = {
      "fun_args" => ["orch.removal", { "orchestration_jid" => "20170706104527757673" }],
      "jid"      => "20170706104527757673",
      "return"   => { "retcode" => 0 },
      "success"  => true,
      "_stamp"   => "2017-07-06T10:45:54.734096",
      "fun"      => "runner.state.orchestrate",
      "user"     => "root"
    }.to_json

    FactoryGirl.create(:salt_event,
                       tag:  "salt/run/20170706104527757673/new",
                       data: event_data)
  end

  let(:force_removal_orchestration) do
    event_data = {
      "fun_args" => ["orch.force-removal", { "orchestration_jid" => "20170706104527757673" }],
      "jid"      => "20170706104527757673",
      "return"   => { "retcode" => 0 },
      "success"  => true,
      "_stamp"   => "2017-07-06T10:45:54.734096",
      "fun"      => "runner.state.orchestrate",
      "user"     => "root"
    }.to_json

    FactoryGirl.create(:salt_event,
                       tag:  "salt/run/20170706104527757673/new",
                       data: event_data)
  end

  describe "process_event" do
    describe "with a bootstrap orchestration" do
      let(:handler) { described_class.new(bootstrap_orchestration) }

      it "creates the orchestration" do
        expect { handler.process_event }.to change { Orchestration.bootstrap.count }.from(0).to(1)
      end
    end
    describe "with upgrade orchestration" do
      let(:handler) { described_class.new(upgrade_orchestration) }

      it "creates the orchestration" do
        expect { handler.process_event }.to change { Orchestration.upgrade.count }.from(0).to(1)
      end
    end
    describe "with migration orchestration" do
      let(:handler) { described_class.new(migration_orchestration) }

      it "creates the orchestration" do
        expect { handler.process_event }.to change { Orchestration.migration.count }.from(0).to(1)
      end
    end
    describe "with removal orchestration" do
      let(:handler) { described_class.new(removal_orchestration) }

      it "creates the orchestration" do
        expect { handler.process_event }.to change { Orchestration.removal.count }.from(0).to(1)
      end
    end
    describe "with force removal orchestration" do
      let(:handler) { described_class.new(force_removal_orchestration) }

      it "creates the orchestration" do
        expect { handler.process_event }.to(
          change { Orchestration.force_removal.count }.from(0).to(1)
        )
      end
    end
  end
end
