require "rails_helper"

RSpec.describe SetupHelper, type: :helper do
  describe "#cloud_framework_value" do
    it "returns whatever value cloud:framework is set" do
      p = Pillar.create(pillar: "cloud:framework", value: "ec2")
      expect(cloud_framework_value).to eq("ec2")

      p.value = "gce"
      p.save
      expect(cloud_framework_value).to eq("gce")
    end
  end

  describe "#cloud_provider_options?" do
    it "returns true if has advanced settings available (e.g. openstack)" do
      Pillar.create(pillar: "cloud:framework", value: "openstack")
      expect(cloud_provider_options?).to eq(true)
    end

    it "returns false if no advanced settings available (e.g. gce)" do
      Pillar.create(pillar: "cloud:framework", value: "gce")
      expect(cloud_provider_options?).to eq(false)
    end
  end
end
