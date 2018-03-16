require "rails_helper"

RSpec.describe SetupHelper, type: :helper do
  describe "#cloud_provider_value" do
    it "returns openstack by default" do
      expect(cloud_provider_value).to eq("openstack")
    end

    it "returns ec2 options when cloud:framework is aws" do
      Pillar.create(pillar: "cloud:framework", value: "ec2")
      expect(cloud_provider_value).to eq("ec2")
    end

    it "returns gce options when cloud:framework is gce" do
      Pillar.create(pillar: "cloud:framework", value: "gce")
      expect(cloud_provider_value).to eq("gce")
    end

    it "returns azure options when cloud:framework is azure" do
      Pillar.create(pillar: "cloud:framework", value: "azure")
      expect(cloud_provider_value).to eq("azure")
    end
  end
end
