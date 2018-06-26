require "rails_helper"

describe DexConnectorLdap, type: :model do
  subject { create(:dex_connector_ldap) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:port) }
  it { is_expected.to validate_numericality_of(:port).only_integer }
  it { is_expected.to validate_presence_of(:username_prompt) }
  it { is_expected.to validate_presence_of(:user_base_dn) }
  it { is_expected.to validate_presence_of(:user_filter) }
  it { is_expected.to validate_presence_of(:user_attr_username) }
  it { is_expected.to validate_presence_of(:user_attr_id) }
  it { is_expected.to validate_presence_of(:user_attr_email) }
  it { is_expected.to validate_presence_of(:user_attr_name) }
  it { is_expected.to validate_presence_of(:group_base_dn) }
  it { is_expected.to validate_presence_of(:group_filter) }
  it { is_expected.to validate_presence_of(:group_attr_user) }
  it { is_expected.to validate_presence_of(:group_attr_group) }
  it { is_expected.to validate_presence_of(:group_attr_name) }

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

  describe "#host_validations" do

    it { is_expected.to validate_presence_of(:host) }
  end

  describe "#bind_dn_validations" do

    context "when bind_anon is false" do
      let(:dex_connector_ldap) { create(:dex_connector_ldap, :regular_admin) }

      it { expect(dex_connector_ldap).to validate_presence_of(:bind_dn) }
    end

    context "when bind_anon is true" do

      it { is_expected.not_to validate_presence_of(:bind_dn) }
    end
  end

  describe "#bind_pw_validations" do

    context "when bind_anon is false" do
      let(:dex_connector_ldap) { create(:dex_connector_ldap, :regular_admin) }

      it { expect(dex_connector_ldap).to validate_presence_of(:bind_pw) }
    end

    context "when bind_anon is true" do

      it { is_expected.not_to validate_presence_of(:bind_pw) }
    end
  end
end
