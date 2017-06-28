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

    context "disable proxy settings" do
      let(:proxy_enabled_settings_params) do
        proxy_enabled = settings_params.dup
        proxy_enabled[:http_proxy]  = "squid.corp.net:3128"
        proxy_enabled[:https_proxy] = "squid.corp.net:3128"
        proxy_enabled[:no_proxy]    = "localhost"
        proxy_enabled
      end

      before do
        described_class.apply(proxy_enabled_settings_params)
      end

      it "removes proxy pillars when blank" do
        keys = [:http_proxy, :https_proxy, :no_proxy]

        keys.each do |key|
          expect(settings_params[key]).to be_nil
        end

        described_class.apply(settings_params)

        keys.each do |key|
          expect(described_class.find_by(pillar: key)).to be_nil
        end
      end
    end

  end
end
