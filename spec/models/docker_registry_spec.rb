require "rails_helper"

describe DockerRegistry, type: :model do
  let(:settings_params) do
    {
      "registries" => [
        {
          "docker_registry_url"         => "http://some.reg.example.org:5000",
          "docker_registry_certificate" => "CERT",
          "docker_registry_mirror"      => nil
        }
      ]
    }
  end

  it { is_expected.to validate_presence_of(:url) }

  # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
  describe "#apply" do
    it "creates a certificate and a registry" do
      params =  settings_params["registries"].first
      expect(described_class.apply(settings_params)).to be_an Array
      expect(described_class.find_by(url: params["docker_registry_url"]).url)
        .to eq("http://some.reg.example.org:5000")
      expect(Certificate.find_by(certificate: params["docker_registry_certificate"]).certificate)
        .to eq("CERT")
    end

    it "does not create entries when params are empty" do
      expect(described_class.apply("registries" => [])).to be_an Array
      expect(described_class.all.empty?).to be true
      expect(Certificate.all.empty?).to be true
    end

    it "removes old registries and certificates" do
      described_class.apply(settings_params)
      described_class.apply("registries" => [])
      expect(described_class.all.empty?).to be true
      expect(Certificate.all.empty?).to be true
    end
  end
  # rubocop:enable RSpec/ExampleLength,RSpec/MultipleExpectations
end
