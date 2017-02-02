# frozen_string_literal: true
require "rails_helper"

describe Minion do
  it { is_expected.to validate_uniqueness_of(:hostname) }

  describe ".assign_roles" do
    let(:minions) do
      FactoryGirl.create_list(:minion, 3, role: nil)
    end

    context "when there are not enough Minions" do
      it "raises NotEnoughMinions" do
        expect { described_class.assign_roles(roles: [:master, :minion]) }
          .to raise_error(Minion::NotEnoughMinions)
      end
    end

    context "when a role cannot be assigned" do
      before do
        minions
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(described_class).to receive(:assign_role).and_return(false)
        # rubocop:enable RSpec/AnyInstance
      end

      it "raises CouldNotAssignRole" do
        expect { described_class.assign_roles(roles: [:master]) }
          .to raise_error(Minion::CouldNotAssignRole)
      end
    end

    context "when default_role is set" do
      before do
        minions
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Pharos::SaltMinion).to receive(:assign_role)
          .and_return(true)
        # rubocop:enable RSpec/AnyInstance
      end

      it "assigns the default role to the rest of the available minions" do
        described_class.assign_roles(roles: [:master], default_role: :minion)

        expect(described_class.all.map(&:role).sort).to eq(["master", "minion", "minion"])
      end
    end

    context "when default_role is not set" do
      before do
        minions
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Pharos::SaltMinion).to receive(:assign_role)
          .and_return(true)
        # rubocop:enable RSpec/AnyInstance
      end

      it "assigns the default role to the rest of the available minions" do
        described_class.assign_roles(roles: [:master])

        expect(described_class.all.map(&:role)).to eq(["master", nil, nil])
      end
    end
  end

  context "with some roles assigned" do
    let(:minion) { create(:minion, role: :master) }

    before { allow(minion.salt).to receive(:assign_role) { true } }

    it "returns false when calling assign_role" do
      expect(minion.assign_role(:other_role)).to be false
    end

    it "does not update the role in the database" do
      expect(minion.role).to eq("master")
    end
  end

  context "with no roles assigned" do
    let(:minion) { create(:minion, role: nil) }

    before { allow(minion.salt).to receive(:assign_role) { true } }

    it "returns true when calling assign_role" do
      expect(minion.reload.assign_role(:master)).to be true
    end

    it "updates the role in the database" do
      minion.assign_role(:master)
      expect(minion.reload.role).to eq("master")
    end

    context "role fails to be assigned on the remote" do
      before do
        allow(minion.salt).to receive(:assign_role) do
          raise Pharos::SaltApi::SaltConnectionException
        end
      end

      it "does not save the role in the database" do
        expect(minion.assign_role(:master)).to be false
        expect(minion.reload.role).to be_nil
      end
    end
  end
end
