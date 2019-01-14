require "rails_helper"

RSpec.describe SystemCertificate, type: :model do
  it { is_expected.to validate_presence_of(:name) }

  context "when a name was set" do
    it "accepts usual names" do
      cert = described_class.new(name: "test_file")
      expect(cert.valid?).to eq(true)
    end

    it "rejects dots in the name" do
      cert = described_class.new(name: "test.file")
      expect(cert.valid?).to eq(false)
    end

    it "rejects slashes in the name" do
      cert = described_class.new(name: "test/file")
      expect(cert.valid?).to eq(false)
    end
  end
end
