require "spec_helper"
require "velum/secrets"

describe "create_secret_key_base" do
  key_base_dir = Pathname.new("/tmp/velum_secrets_spec")
  key_base_path = key_base_dir.join("key_base")

  after do
    FileUtils::rm_r key_base_dir
  end

  it "makes new key_base" do
    Velum.read_create_secret_key_base(key_base_path)
    content1 = key_base_path.read
    expect(content1.length).not_to eq 0
    Velum.read_create_secret_key_base(key_base_path)
    expect(key_base_path.read).to eq content1
  end
end
