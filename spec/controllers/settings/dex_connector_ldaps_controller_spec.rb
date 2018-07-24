require "rails_helper"

RSpec.describe Settings::DexConnectorLdapsController, type: :controller do
  let(:user) { create(:user) }

  before do
    setup_done
    sign_in user
  end

  describe "GET #index" do
    let!(:connector) { create(:dex_connector_ldap) }

    before do
      get :index
    end

    it "populates an array of ldap dex connectors" do
      expect(assigns(:ldap_connectors)).to match_array([connector])
    end
  end

  describe "GET #new" do
    before do
      get :new
    end

    it "assigns a new ldap dex connector to @certificate_holder" do
      expect(assigns(:certificate_holder)).to be_a_new(DexConnectorLdap)
    end

    it "assigns a new certificate to @cert" do
      expect(assigns(:cert)).to be_a_new(Certificate)
    end
  end

  describe "GET #edit" do
    let!(:certificate) { create(:certificate) }
    let!(:dex_connector_ldap) { create(:dex_connector_ldap) }
    let!(:dex_connector_ldap_with_cert) { create(:dex_connector_ldap) }

    context "without certificate" do
      before do
        get :edit, id: dex_connector_ldap.id
      end

      it "assigns dex_connector_ldap to @dex_connector_ldap" do
        expect(assigns(:dex_connector_ldap)).not_to be_a_new(DexConnectorLdap)
      end

      it "assigns a new Certificate to @cert" do
        expect(assigns(:cert)).to be_a_new(Certificate)
      end
    end

    context "with certificate" do
      before do
        CertificateService.create!(service:     dex_connector_ldap_with_cert,
                                   certificate: certificate)
        get :edit, id: dex_connector_ldap_with_cert.id
      end

      it "assigns dex_connector_ldap to @certificate_holder" do
        expect(assigns(:certificate_holder)).not_to be_a_new(DexConnectorLdap)
      end

      it "assigns the existing certificate to @cert" do
        expect(assigns(:cert)).not_to be_a_new(Certificate)
      end
    end

    it "return 404 if ldap connector does not exist" do
      get :edit, id: DexConnectorLdap.last.id + 1
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST #create" do
    it "can not save ldap connector with invalid field" do
      expect do
        post :create, dex_connector_ldap: { name:      "ldap_fail",
                                            start_tls: nil }
      end.not_to change(DexConnectorLdap, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    context "with ldap connector saved in the database" do
      let!(:certificate) { create(:certificate) }
      let(:dex_connector_ldap) { DexConnectorLdap.find_by(name: "ldap1") }

      before do
        post :create, dex_connector_ldap: { name:               "ldap1",
                                            host:               "test.com",
                                            port:               389,
                                            start_tls:          false,
                                            certificate:        certificate.certificate,
                                            bind_anon:          false,
                                            bind_dn:            "cn=admin,dc=example,dc=org",
                                            bind_pw:            "admin",
                                            username_prompt:    "Username",
                                            user_base_dn:       "dc=example,dc=org",
                                            user_filter:        "(objectClass=person)",
                                            user_attr_username: "uid",
                                            user_attr_id:       "uid",
                                            user_attr_email:    "mail",
                                            user_attr_name:     "fn",
                                            group_base_dn:      "dc=example,dc=org",
                                            group_filter:       "(objectClass=group)",
                                            group_attr_user:    "uid",
                                            group_attr_group:   "member",
                                            group_attr_name:    "name" }

      end
      it "saves the corrent name" do
        expect(dex_connector_ldap.name).to eq("ldap1")
      end
      it "saves the correct host" do
        expect(dex_connector_ldap.host).to eq("test.com")
      end
      it "saves the correct port" do
        expect(dex_connector_ldap.port).to eq(389)
      end
      it "saves the correct start_tls value" do
        expect(dex_connector_ldap.start_tls).to eq(false)
      end
      it "saves the correct certificate" do
        expect(dex_connector_ldap.certificate.certificate).to eq(certificate.certificate.strip)
      end
      it "saves the correct bind_anon value" do
        expect(dex_connector_ldap.bind_anon).to eq(false)
      end
      it "saves the correct bind_dn" do
        expect(dex_connector_ldap.bind_dn).to eq("cn=admin,dc=example,dc=org")
      end
      it "saves the correct bind_pw" do
        expect(dex_connector_ldap.bind_pw).to eq("admin")
      end
      it "saves the correct username_prompt" do
        expect(dex_connector_ldap.username_prompt).to eq("Username")
      end
      it "saves the correct user_base_dn" do
        expect(dex_connector_ldap.user_base_dn).to eq("dc=example,dc=org")
      end
      it "saves the correct user_filter" do
        expect(dex_connector_ldap.user_filter).to eq("(objectClass=person)")
      end
      it "saves the correct user_attr_username" do
        expect(dex_connector_ldap.user_attr_username).to eq("uid")
      end
      it "saves the correct user_attr_id" do
        expect(dex_connector_ldap.user_attr_id).to eq("uid")
      end
      it "saves the correct user_attr_email" do
        expect(dex_connector_ldap.user_attr_email).to eq("mail")
      end
      it "saves the correct user_attr_name" do
        expect(dex_connector_ldap.user_attr_name).to eq("fn")
      end
      it "saves the correct group_base_dn" do
        expect(dex_connector_ldap.group_base_dn).to eq("dc=example,dc=org")
      end
      it "saves the correct group_filter" do
        expect(dex_connector_ldap.group_filter).to eq("(objectClass=group)")
      end
      it "saves the correct group_attr_user" do
        expect(dex_connector_ldap.group_attr_user).to eq("uid")
      end
      it "saves the correct group_attr_group" do
        expect(dex_connector_ldap.group_attr_group).to eq("member")
      end
      it "saves the correct group_attr_name" do
        expect(dex_connector_ldap.group_attr_name).to eq("name")
      end
    end
  end

  describe "PATCH #update" do
    let!(:certificate) { create(:certificate) }
    let!(:dex_connector_ldap) { create(:dex_connector_ldap) }

    before do
      CertificateService.create!(service: dex_connector_ldap, certificate: certificate)
    end

    it "updates a ldap connector" do
      dex_connector_ldap_params = { name: "new name" }
      put :update, id: dex_connector_ldap.id, dex_connector_ldap: dex_connector_ldap_params
      expect(DexConnectorLdap.find(dex_connector_ldap.id).name).to eq("new name")
    end
  end

  describe "DELETE #destroy" do
    let!(:dex_connector_ldap) { create(:dex_connector_ldap) }

    it "deletes a ldap connector" do
      expect do
        delete :destroy, id: dex_connector_ldap.id
      end.to change(DexConnectorLdap, :count).by(-1)
    end
  end
end
