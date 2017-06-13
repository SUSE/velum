require "rails_helper"

describe Certificate, type: :model do
  it { is_expected.to validate_presence_of(:certificate) }
end
