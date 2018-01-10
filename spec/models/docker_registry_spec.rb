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

  let(:invalid_settings_params) do
    {
      "registries" => [
        {
          "docker_registry_url"         => "invalid-url",
          "docker_registry_certificate" => "CERT",
          "docker_registry_mirror"      => nil
        }
      ]
    }
  end

  it { is_expected.to validate_presence_of(:url) }
  it { is_expected.to validate_uniqueness_of(:url) }
  it { is_expected.to have_one(:certificate_service).dependent(:destroy) }
  it { is_expected.to have_one(:certificate).through(:certificate_service) }

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

    it "removes old registries" do
      described_class.apply(settings_params)
      described_class.apply("registries" => [])
      expect(described_class.count).to eq 0
    end

    context "when deleting a registry" do
      it "keeps the related certificate" do
        described_class.apply(settings_params)
        described_class.apply("registries" => [])
        expect(Certificate.count).to eq 1
      end
    end

    context "when creating an invalid registry" do
      it "returns an error" do
        expect(described_class.apply(invalid_settings_params))
          .to include(/doesn't match a docker registry pattern/)
      end
    end
  end
  # rubocop:enable RSpec/ExampleLength,RSpec/MultipleExpectations
end
