require "rails_helper"

describe DexConnectorLdap, type: :model do
  describe "#configure_dex_ldap_connector" do
    let(:dex_connector_ldap) { create(:dex_connector_ldap) }
    let(:certificate)        { create(:certificate) }

    before do
      CertificateService.create(service: dex_connector_ldap, certificate: certificate)
    end

    after do
      CertificateService.destroy_all
    end

    it "creates a valid looking certificate" do
      expect(Certificate.find_by(certificate: certificate.certificate).certificate)
        .to include("BEGIN CERTIFICATE")
    end
  end
end
