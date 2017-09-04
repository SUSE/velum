# frozen_string_literal: true
require "rails_helper"

describe SaltHandler::Orchestration do

  describe "#tag_matcher" do
    it "raises an exception" do
      expect { described_class.tag_matcher }.to raise_error("no tag matcher specified")
    end
  end

end
