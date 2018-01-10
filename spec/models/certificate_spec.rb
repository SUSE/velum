require "rails_helper"

describe Certificate do
  it { is_expected.to have_many(:certificate_services) }
  it { is_expected.to validate_presence_of(:certificate) }
end
