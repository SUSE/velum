require "rails_helper"

describe Orchestration do

  let(:orchestration) { FactoryGirl.create :orchestration }
  let(:upgrade_orchestration) { FactoryGirl.create :upgrade_orchestration }

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

    it "spawns a new bootstrap orchestration" do
      expect { described_class.run kind: :upgrade }.to(change { described_class.upgrade.count })
      expect(Velum::Salt).to have_received(:update_orchestration).once
    end

    it "updates all minions with roles" do
      allow(Minion).to receive :mark_pending_update
      upgrade_orchestration.send :update_minions
      expect(Minion).to have_received :mark_pending_update
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
