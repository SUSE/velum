require "rails_helper"

RSpec.describe Orchestrations::MigrationController, type: :controller do
  let(:user) { create(:user) }

  before do
    sign_in user
    setup_done
    setup_stubbed_pending_minions!
    allow(Orchestration).to receive(:run).with(kind: :migration)
    Minion.create!(minion_id: SecureRandom.hex, fqdn: "minion0.k8s.local", role: "master")
    Minion.create!(minion_id: SecureRandom.hex, fqdn: "worker0.k8s.local", role: "worker")
    # rubocop:disable Rails/SkipsModelValidations
    Minion.cluster_role.update_all(
      tx_update_migration_available:     true,
      tx_update_migration_mirror_synced: true,
      tx_update_migration_notes:         "https://release-notes-url",
      tx_update_migration_newversion:    "SUSE CaaS Platform 3.1 x86_64"
    )
    # rubocop:enable Rails/SkipsModelValidations
  end

  describe "POST /orchestrations/migration via HTML" do
    context "when there is no orchestration to retry" do
      it "redirects to the root path" do
        post :create
        expect(response.redirect_url).to eq root_url
      end
    end

    context "when an orchestration can be retried" do
      before do
        FactoryGirl.create :migration_orchestration,
                           status: "failed"
      end

      it "spawns a new orchestration" do
        post :create
        expect(response.redirect_url).to eq root_url
        expect(Orchestration).to have_received(:run).once.with(kind: :migration)
      end
    end
  end

  # rubocop:disable RSpec/MessageChain
  describe "GET /orchestrations/migration/status via HTML" do
    context "when a migration orchestration is in progress" do
      it "renders a successful status" do
        allow(Orchestration).to receive_message_chain(:migration, :in_progress?).and_return(true)
        get :status
        expect(response.code).to eq "200"
      end
    end

    context "when a migration orchestration is not in progress" do
      it "renders a failed status to signal the reboot" do
        allow(Orchestration).to receive_message_chain(:migration, :in_progress?).and_return(false)
        get :status
        expect(response.code).to eq "500"
      end
    end
  end
  # rubocop:enable RSpec/MessageChain

  describe "POST /orchestrations/migration/check via HTML" do
    it "runs update-checker-migration" do
      allow(::Velum::Salt).to receive(:call)
      post :check_mirror
      expect(response.redirect_url).to eq root_url
    end
  end

  describe "POST /orchestrations/migration/reboot via HTML" do
    it "reboots the cluster nodes and finishes the migration" do
      allow(::Velum::Salt).to receive(:update_orchestration_after_product_migration)
      post :reboot_nodes
      expect(Minion.cluster_role.map(&:highstate).uniq.first).to eq "pending"
      expect(response.redirect_url).to eq root_url
    end
  end
end
