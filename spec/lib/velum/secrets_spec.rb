require "spec_helper"
require "velum/secrets"

describe "create_secret_key_base" do
  let(:key_base_path) { Pathname.new(File.join(Dir.tmpdir, "key_base.json")) }

  after do
    key_base_path.delete
  end

  context "when there is no key_base" do
    # rubocop:disable RSpec/MultipleExpectations
    it "creates a new key_base" do
      expect(key_base_path.exist?).to be false
      ret = Velum::Secrets.read_or_create_secret_key_base(key_base_path)
      expect(key_base_path.exist?).to be true
      expect(key_base_path.read).to eq ret
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  context "when there is a key_base" do
    it "returns the key_base" do
      Velum::Secrets.read_or_create_secret_key_base(key_base_path)
      ret = Velum::Secrets.read_or_create_secret_key_base(key_base_path)
      expect(ret).to eq key_base_path.read
    end
  end
end
