# frozen_string_literal: true
require "rails_helper"

describe Minion do
  subject(:minion) { create(:minion) }
  before           { allow(minion.salt).to receive(:assign_role) { true } }

  it { is_expected.to validate_uniqueness_of(:hostname) }

  context "with some salt roles assigned" do
    before { allow(minion.salt).to receive(:roles?) { true } }

    it "returns false when calling assign_role" do
      expect(minion.assign_role(role: :master)).to be false
    end

    it "does not update the role in the database" do
      expect(minion.role).to be_nil
    end
  end

  context "with no salt roles assigned" do
    before { allow(minion.salt).to receive(:roles?) { false } }

    it "returns true when calling assign_role" do
      expect(minion.assign_role(role: :master)).to be true
    end

    it "updates the role in the database" do
      minion.assign_role role: :master
      expect(minion.role).to eq("master")
    end

    context "role fails to be assigned on the remote" do
      before do
        allow(minion.salt).to receive(:assign_role) { raise Net::HTTPBadResponse }
      end

      it "saves the role locally" do
      end
    end
  end
end
