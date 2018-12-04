require "rails_helper"

describe Minion do
  let(:minions) do
    described_class.create! [
      { minion_id: SecureRandom.hex, fqdn: "master.example.com" },
      { minion_id: SecureRandom.hex, fqdn: "worker0.example.com" },
      { minion_id: SecureRandom.hex, fqdn: "worker1.example.com" }
    ]
  end

  let(:reboot_needed_grains) do
    { "tx_update_reboot_needed" => true,
      "tx_update_failed"        => false }
  end

  let(:reboot_failed_grains) do
    { "tx_update_reboot_needed" => false,
      "tx_update_failed"        => true }
  end

  it { is_expected.to validate_uniqueness_of(:minion_id) }

  describe ".update_grains" do
    context "when reboot needed" do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Velum::SaltMinion).to receive(:info).and_return(reboot_needed_grains)
        # rubocop:enable RSpec/AnyInstance
      end

      it "updates the minions" do
        expect { described_class.update_grains }.to(change { described_class.needs_update.count })
      end
    end

    context "when reboot failed" do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Velum::SaltMinion).to receive(:info).and_return(reboot_failed_grains)
        # rubocop:enable RSpec/AnyInstance
      end

      it "updates the minions" do
        expect { described_class.update_grains }.to(change { described_class.needs_update.count })
      end
    end
  end

  # rubocop:disable RSpec/ExampleLength
  describe ".assign_roles" do
    context "when a master role cannot be assigned remotely" do
      before do
        minions
      end

      it "returns a hash with the master fqdn false" do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(described_class).to receive(:assign_role)
          .with(:master, remote: true).and_return(false)
        allow_any_instance_of(described_class).to receive(:assign_role)
          .with(:worker, remote: true).and_return(true)
        # rubocop:enable RSpec/AnyInstance
        expect(
          described_class.assign_roles(
            roles:  {
              master: [described_class.second.id],
              worker: described_class.all[2..-1].map(&:id)
            },
            remote: true
          )
        ).to eq(
          minions[0].minion_id => false,
          minions[1].minion_id => true,
          minions[2].minion_id => true
        )
      end
    end

    context "when a minion role cannot be assigned remotely" do
      before do
        minions
      end

      it "returns a hash with the minion fqdns false" do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(described_class).to receive(:assign_role)
          .with(:master, remote: true).and_return(true)
        allow_any_instance_of(described_class).to receive(:assign_role)
          .with(:worker, remote: true).and_return(false)
        # rubocop:enable RSpec/AnyInstance
        expect(
          described_class.assign_roles(
            roles:  {
              master: [described_class.second.id],
              worker: described_class.all[2..-1].map(&:id)
            },
            remote: true
          )
        ).to eq(
          minions[0].minion_id => true,
          minions[1].minion_id => false,
          minions[2].minion_id => false
        )
      end
    end

    context "when a default role cannot be assigned remotely" do
      before do
        minions
      end

      it "returns a hash with the default_role fqdn false" do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(described_class).to receive(:assign_role)
          .with(:master, remote: true) do
          # rubocop:disable Rails/SkipsModelValidations
          minions[0].update_column :role, described_class.roles[:master]
          # rubocop:enable Rails/SkipsModelValidations
        end
        allow_any_instance_of(described_class).to receive(:assign_role)
          .with(:worker, remote: true).and_return(false)
        # rubocop:enable RSpec/AnyInstance
        expect(
          described_class.assign_roles(
            roles: {
              master: [described_class.second.id]
            }, default_role: :worker, remote: true
          )
        ).to eq(
          minions[0].minion_id => true,
          minions[1].minion_id => false,
          minions[2].minion_id => false
        )
      end
    end

    context "when default_role is set" do
      before do
        minions
      end

      it "assigns the default role to the rest of the available minions" do
        described_class.assign_roles(
          roles:        {
            master: [described_class.second.id]
          },
          default_role: :worker
        )

        expect(described_class.cluster_role.map(&:role).sort).to eq(["master", "worker", "worker"])
      end
    end

    context "when default_role is not set" do
      before do
        minions
      end

      it "assigns the minion role to the rest of the available minions" do
        described_class.assign_roles(
          roles: {
            master: [described_class.second.id],
            worker: described_class.all[2..-1].map(&:id)
          }
        )

        expect(described_class.cluster_role.map(&:role)).to eq(["master", "worker", "worker"])
      end
    end

    context "when explicit worker role is set" do
      before do
        minions
      end

      it "assigns the worker role to specific minions" do
        described_class.assign_roles(
          roles: {
            master: [described_class.second.id],
            worker: described_class.all[2..-1].map(&:id)
          }
        )

        expect(described_class.cluster_role.last.role).to eq("worker")
      end
    end

    it "returns a hash of the minions that were assigned a role" do
      minions
      roles = described_class.assign_roles(
        roles: { master: [described_class.second.id], worker: described_class.all[2..-1].map(&:id) }
      )

      expect(roles).to eq(
        minions[0].minion_id => true,
        minions[1].minion_id => true,
        minions[2].minion_id => true
      )
    end
  end

  context "with some roles assigned" do
    let(:minion) { create(:minion, role: described_class.roles[:master]) }

    it "returns true when calling assign_role" do
      expect(minion.assign_role(:worker)).to be true
    end

    it "updates the role in the database" do
      minion.assign_role :worker
      expect(minion.role).to eq("worker")
    end
  end

  context "with no roles assigned" do
    let(:minion) { create(:minion, role: nil) }

    before { allow(minion.salt).to receive(:assign_role).and_return(true) }

    it "returns true when calling assign_role" do
      expect(minion.reload.assign_role(:master)).to be true
    end

    it "updates the role in the database" do
      minion.assign_role(:master)
      expect(minion.reload.role).to eq("master")
    end

    it "updates the highstate column to 'not_applied' if not remote" do
      minion.update!(highstate: :applied)
      expect { minion.assign_role(:master) }
        .to change { minion.reload.highstate }.from("applied")
                                              .to("not_applied")
    end

    it "updates the highstate column to 'pending' if remote" do
      minion.update!(highstate: :applied)
      expect { minion.assign_role(:master, remote: true) }
        .to change { minion.reload.highstate }.from("applied")
                                              .to("pending")
    end

    context "when role fails to be assigned on the remote" do
      before do
        allow(minion.salt).to receive(:assign_role) do
          raise Velum::SaltApi::SaltConnectionException
        end
      end

      it "does not save the role in the database" do
        expect(minion.assign_role(:master, remote: true)).to be false
        expect(minion.reload.role).to be_nil
      end
    end
  end
  # rubocop:enable RSpec/ExampleLength

  describe "#mark_pending_update" do
    before do
      minions
      described_class.second.assign_role :master, remote: false
      described_class.all[2..-1].each { |minion| minion.assign_role :worker, remote: false }
      # rubocop:disable Rails/SkipsModelValidations
      described_class.update_all highstate: described_class.highstates[:applied]
      # rubocop:enable Rails/SkipsModelValidations
      described_class.update([described_class.second.id, described_class.third.id,
                              described_class.fourth.id],
                             [{ tx_update_reboot_needed: true, tx_update_failed: false },
                              { tx_update_reboot_needed: true, tx_update_failed: false },
                              { tx_update_reboot_needed: false, tx_update_failed: true }])
    end

    context "when an update is needed" do
      it "sets the highstate of the upgradable minions as pending" do
        expect { described_class.mark_pending_update }.to change {
          described_class.cluster_role.applied.count
        }.from(3).to(1)
      end
    end
  end

  describe "#mark_pending_migration" do
    before do
      minions
      described_class.second.assign_role :master, remote: false
      described_class.all[2..-1].each { |minion| minion.assign_role :worker, remote: false }
      # rubocop:disable Rails/SkipsModelValidations
      described_class.update_all highstate: described_class.highstates[:applied]
      # rubocop:enable Rails/SkipsModelValidations
      described_class.update([described_class.second.id, described_class.third.id,
                              described_class.fourth.id],
                             [{ tx_update_migration_available: true, tx_update_failed: false },
                              { tx_update_migration_available: true, tx_update_failed: false },
                              { tx_update_migration_available: true, tx_update_failed: false }])
    end

    context "when a migration is needed" do
      it "sets the highstate of the migratable minions as pending" do
        expect { described_class.mark_pending_migration }.to change {
          described_class.cluster_role.applied.count
        }.from(3).to(0)
      end
    end
  end

  describe "#mark_pending_bootstrap!" do
    before do
      minions
      described_class.second.assign_role :master, remote: false
      described_class.all[2..-1].each { |minion| minion.assign_role :worker, remote: false }
      # rubocop:disable Rails/SkipsModelValidations
      described_class.update_all highstate: described_class.highstates[:applied]
      # rubocop:enable Rails/SkipsModelValidations
    end

    context "when a bootstrap is triggered" do
      it "sets the highstate of all minions as pending" do
        expect { described_class.mark_pending_bootstrap! }.to change {
          described_class.cluster_role.pending.count
        }.from(0).to(3)
      end
    end
  end

  describe "#mark_pending_removal" do
    before do
      minions
      # rubocop:disable Rails/SkipsModelValidations
      described_class.unassigned_role.update_all role: described_class.roles[:worker]
      # rubocop:enable Rails/SkipsModelValidations
    end

    let(:minion_ids) { [described_class.cluster_role.first.minion_id] }

    context "when a minion is marked as pending removal" do
      it "updates the minion to have pending_removal state" do
        expect do
          described_class.mark_pending_removal(minion_ids: minion_ids)
        end.to change { described_class.cluster_role.pending_removal.count }.from(0).to(1)
      end
    end
  end

  describe "#remove_minion" do
    before do
      minions
    end

    let(:minion_ids) { [described_class.unassigned_role.first.minion_id] }

    context "when a minion is marked for removal" do
      it "updates the minion to have pending_removal state" do
        expect do
          described_class.remove_minion(minion_ids[0])
        end.to change { described_class.unassigned_role.count }.from(3).to(2)
      end
    end
  end
end
