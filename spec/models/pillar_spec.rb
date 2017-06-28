# coding: utf-8

describe Pillar do
  subject { create(:pillar) }

  it { is_expected.to validate_presence_of(:pillar) }
  it { is_expected.to validate_presence_of(:value) }

  describe "#apply" do
    let(:settings_params) do
      {
        dashboard: "dashboard.example.com",
        apiserver: "apiserver.example.com"
        proxy_systemwide: "false"
      }
    end

    it "returns an empty array when everything is fine" do
      res = described_class.apply(settings_params)
      expect(res).to be_empty
    end
  end
end
