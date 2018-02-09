require "rails_helper"

describe RegistryMirror do
  it { is_expected.to validate_uniqueness_of(:url) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name) }
end
