require "rails_helper"

describe AdmissionWebhookForm do
  include ActionDispatch::TestProcess

  describe "validations" do
    let(:cert_file) { fixture_file_upload("admin.crt") }
    let(:ca_file) { fixture_file_upload("ca.crt") }
    let(:key_file) { fixture_file_upload("admin.key") }
    let(:empty_file) { fixture_file_upload("empty.txt") }
    let(:invalid_key_file) { fixture_file_upload("invalid.key") }

    it "returns false if certificate is absent" do
      form = described_class.new(enabled: "true")
      expect(form).to be_invalid
      expect(form.errors[:certificate]).to include("can't be blank")
    end

    it "returns false if key is absent" do
      form = described_class.new(enabled: "true")
      expect(form).to be_invalid
      expect(form.errors[:key]).to include("can't be blank")
    end

    it "returns false if certificate not x509" do
      form = described_class.new(enabled: "true", cert_file: key_file, key_file: key_file)
      expect(form).to be_invalid
    end

    it "returns true if certificate is x509 and key pem/der" do
      form = described_class.new(enabled: "true", cert_file: cert_file, key_file: key_file)
      expect(form).to be_valid
    end

    it "returns true if enabled is false" do
      form = described_class.new(enabled: "false", cert_file: "Test")
      expect(form).to be_valid
    end

    it "returns false if certificate file is empty" do
      form = described_class.new(enabled: "true", cert_file: empty_file, key_file: key_file)
      expect(form).to be_invalid
    end

    it "returns false if key file is empty" do
      form = described_class.new(enabled: "true", cert_file: cert_file, key_file: empty_file)
      expect(form).to be_invalid
    end

    it "returns false if key has an invalid pem/der format" do
      form = described_class.new(enabled: "true", cert_file: cert_file, key_file: invalid_key_file)
      expect(form).to be_invalid
      expect(form.errors[:key]).to include("is not a valid PEM/DER encoded key")
    end

    it "returns false if key doesn't match with cert" do
      form = described_class.new(enabled: "true", cert_file: ca_file, key_file: key_file)
      expect(form).to be_invalid
      expect(form.errors[:key]).to include("doesn't pair with the certificate")
    end

    it "returns false if enabled and no files" do
      form = described_class.new(enabled: "true")
      expect(form).to be_invalid
    end
  end

  describe "#key" do
    it "returns content of uploadad key file" do
      key_file = fixture_file_upload("admin.key")
      form = described_class.new(enabled: "false", key_file: key_file)
      key_content = key_file.read
      key_file.rewind
      expect(form.key).to eq(key_content)
    end

    it "returns nil if no uploaded file" do
      form = described_class.new(enabled: "true", key_file: nil)
      expect(form.key).to be_nil
    end
  end

  describe "#certificate" do
    it "returns content of uploadad cert file" do
      cert_file = fixture_file_upload("admin.crt")
      form = described_class.new(enabled: "false", cert_file: cert_file)
      cert_content = cert_file.read
      cert_file.rewind
      expect(form.certificate).to eq(cert_content)
    end

    it "returns nil if no uploaded file" do
      form = described_class.new(enabled: "true", cert_file: nil)
      expect(form.certificate).to be_nil
    end
  end
end
