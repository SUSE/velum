# frozen_string_literal: true
require "rails_helper"
require "pharos/salt_minion"

describe Pharos::SaltMinion do
  describe "minions" do
    it "fetches a single minion" do
      VCR.use_cassette("salt/fetch_minion", record: :none) do
        expect(described_class.new(minion_id: "minion1").info).to include("kernel" => "Linux")
      end
    end
  end

  describe "minion roles" do
    context "has roles" do
      it "returns true for roles?" do
        VCR.use_cassette("salt/fetch_minion_with_roles", record: :none) do
          expect(described_class.new(minion_id: "minion1").roles?).to be true
        end
      end
    end

    context "has no roles" do
      it "return false for roles?" do
        VCR.use_cassette("salt/fetch_minion", record: :none) do
          expect(described_class.new(minion_id: "minion1").roles?).to be false
        end
      end

      it "assigns a role when called assign_role" do
        VCR.use_cassette("salt/assign_role_to_minion", record: :none) do
          expect(described_class.new(minion_id: "minion1").assign_role(role: :master)).to eq :master
        end
      end
    end
  end
end
