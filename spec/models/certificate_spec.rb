require "rails_helper"

RSpec.describe Certificate do
  it { is_expected.to have_many(:certificate_services) }
  it { is_expected.to validate_presence_of(:certificate) }

  context "when a certificate was passed" do
    it "accepts a PEM formatted certificate" do
      x509_cert = OpenSSL::X509::Certificate.new(create(:certificate).certificate)
      cert = described_class.new(certificate: x509_cert.to_pem)
      expect(cert.valid?).to eq(true)
    end

    it "accepts a PER formatted certificate" do
      x509_cert = OpenSSL::X509::Certificate.new(create(:certificate).certificate)
      cert = described_class.new(certificate: x509_cert.to_der)
      expect(cert.valid?).to eq(true)
    end

    it "errors when the text is not a X509 certificate" do
      cert = described_class.new(certificate: "No certificate")
      expect(cert.valid?).to eq(false)
    end
  end
end
