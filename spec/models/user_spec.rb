# frozen_string_literal: true
require "rails_helper"

describe User do
  subject { create(:user) }

  it { should validate_uniqueness_of(:name) }
end
