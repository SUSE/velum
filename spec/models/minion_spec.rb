# frozen_string_literal: true
require "rails_helper"

describe Minion do
  subject { FactoryGirl.create(:minion) }

  it { is_expected.to validate_uniqueness_of(:hostname) }
end
