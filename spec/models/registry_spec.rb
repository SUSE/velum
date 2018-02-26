require "rails_helper"

describe Registry, type: :model do
  let(:registry)    { create(:registry) }
  let(:certificate) { create(:certificate) }

  let(:settings_params) do
    {
      "certificate" => certificate.certificate,
      "name"        => "suse_testing_mirror",
      "mirror_url"  => "https://local.registry"
    }
  end

  let(:invalid_settings_params)  { settings_params.dup.tap { |s| s["mirror_url"] = "baz" } }
  let(:empty_cert_params)        { settings_params.dup.tap { |c| c["certificate"] = nil } }

  before do
    CertificateService.create(service: registry, certificate: certificate)
    RegistryMirror.create(url: "https://local.registry") do |m|
      m.name = "suse_testing_mirror"
      m.registry_id = registry.id
    end
  end

  after do
    RegistryMirror.destroy_all
    CertificateService.destroy_all
  end

  it { is_expected.to validate_presence_of(:url) }
  it { is_expected.to validate_uniqueness_of(:url) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name) }

  # rubocop:disable RSpec/MultipleExpectations
  describe "#configure_suse_registry" do
    it "creates a mirror for the suse registry" do
      expect(described_class.configure_suse_registry(settings_params)).to be_an Array
      expect(RegistryMirror.find_by(url: settings_params["mirror_url"]).url)
        .to eq("https://local.registry")
      expect(Certificate.find_by(certificate: settings_params["certificate"]).certificate)
        .to include("BEGIN CERTIFICATE")
    end

    it "removes old certificate services attached to a registry mirror" do
      described_class.configure_suse_registry(settings_params)
      described_class.configure_suse_registry(empty_cert_params)
      expect(CertificateService.where(service_type: "RegistryMirror").count).to eq 0
    end

    context "when creating an invalid registry" do
      it "returns an error for url" do
        expect(described_class.configure_suse_registry(invalid_settings_params))
          .to include(/doesn't match a registry pattern/)
      end
    end
  end
  # rubocop:enable RSpec/MultipleExpectations
end
