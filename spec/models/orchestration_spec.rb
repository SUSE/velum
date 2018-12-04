require "rails_helper"

describe Orchestration do

  let(:orchestration) { create(:orchestration) }
  let(:upgrade_orchestration) { create(:upgrade_orchestration) }
  let(:migration_orchestration) { create(:migration_orchestration) }
  let(:removal_orchestration) { create(:removal_orchestration, params: { target: "some-minion" }) }
  let(:force_removal_orchestration) do
    create(:force_removal_orchestration, params: { target: "some-minion" })
  end

  context "when a bootstrap orchestration is ran" do
    before do
      allow(Velum::Salt).to receive(:orchestrate).and_return(
        [nil, { "return" => [{ "jid" => "20170706104527757674" }] }]
      )
    end

    it "spawns a new bootstrap orchestration" do
      expect { described_class.run kind: :bootstrap }.to(change { described_class.bootstrap.count })
      expect(Velum::Salt).to have_received(:orchestrate).once
    end

    it "updates all minions with roles" do
      allow(Minion).to receive :mark_pending_bootstrap
      orchestration.send :update_minions
      expect(Minion).to have_received :mark_pending_bootstrap
    end
  end

  context "when an upgrade orchestration is ran" do
    before do
      allow(Velum::Salt).to receive(:update_orchestration).and_return(
        [nil, { "return" => [{ "jid" => "20170706104527757674" }] }]
      )
    end

    it "spawns a new upgrade orchestration" do
      expect { described_class.run kind: :upgrade }.to(change { described_class.upgrade.count })
      expect(Velum::Salt).to have_received(:update_orchestration).once
    end

    it "updates all minions with roles" do
      allow(Minion).to receive :mark_pending_update
      upgrade_orchestration.send :update_minions
      expect(Minion).to have_received :mark_pending_update
    end
  end

  context "when a migration orchestration is ran" do
    before do
      allow(Velum::Salt).to receive(:migration_orchestration).and_return(
        [nil, { "return" => [{ "jid" => "20170706104527757674" }] }]
      )
    end

    it "spawns a new migration orchestration" do
      expect { described_class.run kind: :migration }.to(change { described_class.migration.count })
      expect(Velum::Salt).to have_received(:migration_orchestration).once
    end
  end

  context "when a removal orchestration is ran" do
    before do
      allow(Velum::Salt).to receive(:removal_orchestration).and_return(
        [nil, { "return" => [{ "jid" => "20170706104527757674" }] }]
      )
    end

    it "spawns a new removal orchestration" do
      expect { described_class.run kind: :removal, params: { target: "some-minion" } }.to(
        change { described_class.removal.count }
      )
      expect(Velum::Salt).to have_received(:removal_orchestration).once
    end

    it "updates the targeted minion as pending_removal" do
      allow(Minion).to receive(:mark_pending_removal).with(minion_ids: ["some-minion"])
      removal_orchestration.send :update_minions
      expect(Minion).to have_received(:mark_pending_removal).with(minion_ids: ["some-minion"])
    end
  end

  context "when a force removal orchestration is ran" do
    before do
      allow(Velum::Salt).to receive(:force_removal_orchestration).and_return(
        [nil, { "return" => [{ "jid" => "20170706104527757674" }] }]
      )
    end

    it "spawns a new force removal orchestration" do
      expect { described_class.run kind: :force_removal, params: { target: "some-minion" } }.to(
        change { described_class.force_removal.count }
      )
      expect(Velum::Salt).to have_received(:force_removal_orchestration).once
    end

    it "updates the targeted minion as pending_removal" do
      allow(Minion).to receive(:mark_pending_removal).with(minion_ids: ["some-minion"])
      force_removal_orchestration.send :update_minions
      expect(Minion).to have_received(:mark_pending_removal).with(minion_ids: ["some-minion"])
    end
  end

  context "when asking for the proxy" do
    it "returns the expected proxy" do
      expect(orchestration.salt).to be_a(Velum::SaltOrchestration)
    end
  end

  context "when the bootstrap orchestration is retryable" do
    context "when the last orchestration was successful" do
      before do
        FactoryGirl.create :orchestration,
                           kind:   described_class.kinds[:bootstrap],
                           status: described_class.statuses[:succeeded]
      end

      it "is not retryable" do
        expect(described_class).not_to be_retryable(kind: :bootstrap)
      end
    end

    context "when there is an orchestration ongoing" do
      before do
        FactoryGirl.create :orchestration,
                           kind:   described_class.kinds[:bootstrap],
                           status: described_class.statuses[:in_progress]
      end

      it "is not retryable" do
        expect(described_class).not_to be_retryable(kind: :bootstrap)
      end

      it "is not runnable" do
        expect(described_class).not_to be_runnable
      end
    end

    context "when the last orchestration was a failure" do
      before do
        FactoryGirl.create :orchestration,
                           kind:   described_class.kinds[:bootstrap],
                           status: described_class.statuses[:failed]
      end

      it "is retryable" do
        expect(described_class).to be_retryable(kind: :bootstrap)
      end
    end

    context "when the orchestration is a removal one" do
      before do
        FactoryGirl.create :orchestration,
                           kind:   described_class.kinds[:removal]
      end

      it "is not retryable" do
        expect(described_class).not_to be_retryable(kind: :removal)
      end
    end
  end

  context "when the upgrade orchestration is retryable" do
    context "when the last orchestration was successful" do
      before do
        FactoryGirl.create :orchestration,
                           kind:   described_class.kinds[:upgrade],
                           status: described_class.statuses[:succeeded]
      end

      it "is not retryable" do
        expect(described_class).not_to be_retryable(kind: :upgrade)
      end
    end

    context "when there is an orchestration ongoing" do
      before do
        FactoryGirl.create :orchestration,
                           kind:   described_class.kinds[:upgrade],
                           status: described_class.statuses[:in_progress]
      end

      it "is not retryable" do
        expect(described_class).not_to be_retryable(kind: :upgrade)
      end

      it "is not runnable" do
        expect(described_class).not_to be_runnable
      end
    end

    context "when the last orchestration was a failure" do
      before do
        FactoryGirl.create :orchestration,
                           kind:   described_class.kinds[:upgrade],
                           status: described_class.statuses[:failed]
      end

      it "is retryable" do
        expect(described_class).to be_retryable(kind: :upgrade)
      end
    end
  end
end
