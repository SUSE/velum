# frozen_string_literal: true
require "rails_helper"

describe User do
  subject { user }

  ldap_class = Struct.new("LDAP") do
    def search(params = {}); end

    def modify(params = {}); end
  end

  let(:user) { create :user }
  let(:ldap) { ldap_class.new }
  let(:ldap_search_result) { [OpenStruct.new(userPassword: ["password"])] }
  let(:ldap_modify_args) do
    {
      dn:         user.send(:user_dn),
      operations: [
        [:replace, :userPassword, "{CRYPT}#{user.encrypted_password}"]
      ]
    }
  end

  it { is_expected.to validate_uniqueness_of(:email) }
  it { is_expected.to validate_presence_of(:email) }

  describe "#after_ldap_authentication" do
    before do
      allow(ldap).to receive(:search).and_return ldap_search_result
      allow(ldap).to receive(:modify)
      allow(user).to receive(:ldap).and_return ldap
    end

    context "when no encrypted password is present" do
      before do
        # rubocop:disable Rails/SkipsModelValidations
        user.update_column :encrypted_password, ""
        # rubocop:enable Rails/SkipsModelValidations
        user.after_ldap_authentication
      end

      it "migrates the current password" do
        expect(ldap).to have_received(:modify).with ldap_modify_args
      end
    end

    context "when an encrypted password is present" do
      before do
        user.after_ldap_authentication
      end

      it "does not migrate the current password" do
        expect(ldap).not_to have_received :modify
      end
    end
  end
end
