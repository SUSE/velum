require "rails_helper"

RSpec.describe Settings::SystemCertificatesController, type: :controller do
  let(:user) { create(:user) }

  before do
    setup_done
    sign_in user
  end

  describe "GET #index" do
    let!(:certificate) { create(:system_certificate) }

    before do
      get :index
    end

    it "populates an array of system certificates" do
      expect(assigns(:system_certificates)).to match_array([certificate])
    end
  end

  describe "GET #new" do
    before do
      get :new
    end

    it "assigns a new system certificate to @system_certificate" do
      expect(assigns(:system_certificate)).to be_a_new(SystemCertificate)
    end

    it "assigns a new certificate to @cert" do
      expect(assigns(:cert)).to be_a_new(Certificate)
    end
  end

  describe "GET #edit" do
    let!(:certificate) { create(:certificate, certificate: "Cert") }
    let!(:system_certificate) { create(:system_certificate) }
    let!(:system_certificate_with_cert) { create(:system_certificate) }

    context "without certificate" do
      before do
        get :edit, id: system_certificate.id
      end

      it "assigns system_certificate to @system_certificate" do
        expect(assigns(:system_certificate)).not_to be_a_new(SystemCertificate)
      end

      it "assigns a new Certificate to @cert" do
        expect(assigns(:cert)).to be_a_new(Certificate)
      end
    end

    context "with certificate" do
      before do
        CertificateService.create!(service:     system_certificate_with_cert,
                                   certificate: certificate)
        get :edit, id: system_certificate_with_cert.id
      end

      it "assigns system_certificate to @system_certificate" do
        expect(assigns(:system_certificate)).not_to be_a_new(SystemCertificate)
      end

      it "assigns the existing certificate to @cert" do
        expect(assigns(:cert)).not_to be_a_new(Certificate)
      end
    end

    it "return 404 if system certificate does not exist" do
      get :edit, id: SystemCertificate.last.id + 1
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST #create" do
    it "can not save system certificate without name" do
      expect do
        post :create, system_certificate: { name: "", certificate: "cert" }
      end.not_to change(SystemCertificate, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "saves the system certificate in the database" do
      post :create, system_certificate: { name: "sca1", certificate: "cert" }
      system_certificate = SystemCertificate.find_by(name: "sca1")
      expect(system_certificate.name).to eq("sca1")
      expect(system_certificate.certificate.certificate).to eq("cert")
    end
  end

  describe "PATCH #update" do
    let!(:certificate) { create(:certificate, certificate: "C1") }
    let!(:system_certificate) { create(:system_certificate) }

    before do
      CertificateService.create!(service: system_certificate, certificate: certificate)
    end

    it "updates a system certificate" do
      system_certificate_params = { name: "new name" }
      put :update, id: system_certificate.id, system_certificate: system_certificate_params
      expect(SystemCertificate.find(system_certificate.id).name).to eq("new name")
    end
  end

  describe "DELETE #destroy" do
    let!(:system_certificate) { create(:system_certificate) }

    it "deletes a system certificate" do
      expect do
        delete :destroy, id: system_certificate.id
      end.to change(SystemCertificate, :count).by(-1)
    end
  end
end
