# frozen_string_literal: true
require "rails_helper"
require "velum/salt_orchestration"

describe Velum::SaltOrchestration do
  let(:orchestration) do
    FactoryGirl.create :orchestration,
                       jid: "20170907170444487712"
  end

  it "fetches the orchestration info" do
    VCR.use_cassette("salt/orchestration_info", record: :none) do
      expect(described_class.new(orchestration: orchestration).info["return"].first.keys)
        .to include("freedom_master")
    end
  end

end
