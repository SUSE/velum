require "rails_helper"

RSpec.describe "db/schema" do
  describe "salt_events.alter_time" do
    let(:column) { SaltEvent.columns.find { |column| column.name == "alter_time" } }

    it "defaults to CURRENT_TIMESTAMP" do
      expect(column.default).to eq("current_timestamp()").or eq("CURRENT_TIMESTAMP")
    end

    it "is not nullable" do
      expect(column.null).to be_falsey
    end
  end

  describe "salt_returns.alter_time" do
    class SaltReturn < ApplicationRecord; end

    let(:column) { SaltReturn.columns.find { |column| column.name == "alter_time" } }

    it "defaults to CURRENT_TIMESTAMP" do
      expect(column.default).to eq("current_timestamp()").or eq("CURRENT_TIMESTAMP")
    end

    it "is not nullable" do
      expect(column.null).to be_falsey
    end
  end
end
