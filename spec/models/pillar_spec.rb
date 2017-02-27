describe Pillar do
  subject { create(:pillar) }

  it { is_expected.to validate_presence_of(:pillar) }
  it { is_expected.to validate_presence_of(:value) }
end
