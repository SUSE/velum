require "rails_helper"

# rubocop:disable RSpec/ExampleLength
RSpec.describe Settings::RegistryMirrorsController, type: :controller do
  let(:user) { create(:user) }

  before do
    setup_done
    sign_in user

    create(:registry)
    create(:registry_mirror)
  end

  describe "GET #index" do
    it "populates an array of registry mirrors" do
      get :index
      expect(assigns(:grouped_mirrors)).to be_present
    end
  end

  describe "GET #new" do
    it "assigns a new RegistryMirror to @certificate_holder" do
      get :new
      expect(assigns(:certificate_holder)).to be_a(RegistryMirror)
      expect(assigns(:cert)).to be_a(Certificate)
    end

    it "assigns a new Certificate to @cert" do
      get :new
      expect(assigns(:cert)).to be_a(Certificate)
    end
  end

  describe "GET #edit" do
    let!(:certificate) { create(:certificate, certificate: "Cert") }
    let!(:registry_mirror) { create(:registry_mirror) }
    let!(:registry_mirror_with_cert) { create(:registry_mirror) }

    context "without certificate" do
      before do
        get :edit, id: registry_mirror.id
      end

      it "assigns registry mirror to @registry_mirror" do
        expect(assigns(:registry_mirror)).not_to be_a_new(Registry)
      end

      it "assigns a new Certificate to @cert" do
        expect(assigns(:cert)).to be_a_new(Certificate)
      end
    end

    context "with certificate" do
      before do
        CertificateService.create!(service: registry_mirror_with_cert, certificate: certificate)
        get :edit, id: registry_mirror_with_cert.id
      end

      it "assigns registry to @registry_mirror" do
        expect(assigns(:registry_mirror)).not_to be_a_new(Registry)
      end

      it "assigns registry mirror's certificate to @cert" do
        expect(assigns(:cert)).not_to be_a_new(Certificate)
      end
    end

    it "return 404 if registry does not exist" do
      get :edit, id: RegistryMirror.last.id + 1
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST #create" do
    let!(:registry) { create(:registry) }

    context "without certificate" do
      it "saves the new registry mirror in the database" do
        registry_mirror_params = {
          name:        "r1",
          url:         "http://local.lan",
          certificate: "cert",
          registry_id: registry.id
        }

        post :create, registry_mirror: registry_mirror_params
        registry_mirror = RegistryMirror.find_by(name: "r1")
        expect(registry_mirror.name).to eq("r1")
        expect(registry_mirror.url).to eq("http://local.lan")
      end

      it "does not save in db and return unprocessable entity status when invalid" do
        expect do
          post :create, registry_mirror: { url: "invalid", registry_id: registry.id }
        end.not_to change(RegistryMirror, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with certificate" do
      it "saves the new registry in the database" do
        registry_mirror_params = {
          name:        "r1",
          url:         "http://local.lan",
          certificate: "cert",
          registry_id: registry.id
        }

        post :create, registry_mirror: registry_mirror_params
        registry_mirror = RegistryMirror.find_by(name: "r1")
        expect(registry_mirror.name).to eq("r1")
        expect(registry_mirror.certificate.certificate).to eq("cert")
      end

      it "does not save in db and return unprocessable entity status when invalid" do
        registry_mirror_params = {
          name:        "r1",
          url:         "invalid",
          certificate: "cert",
          registry_id: registry.id
        }

        expect do
          post :create, registry_mirror: registry_mirror_params
        end.not_to change(RegistryMirror, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH #update" do
    let!(:certificate) { create(:certificate, certificate: "Cert") }
    let!(:registry_mirror) { create(:registry_mirror) }
    let!(:registry_mirror_with_cert) { create(:registry_mirror) }

    before do
      CertificateService.create!(service: registry_mirror_with_cert, certificate: certificate)
    end

    it "updates a registry mirror" do
      registry_mirror_params = { name: "updated name", url: registry_mirror.url }
      put :update, id: registry_mirror.id, registry_mirror: registry_mirror_params
      expect(RegistryMirror.find(registry_mirror.id).name).to eq("updated name")
    end

    it "creates a new certificate" do
      registry_mirror_params = {
        name:        registry_mirror.name,
        url:         registry_mirror.url,
        certificate: "C2"
      }

      put :update, id: registry_mirror.id, registry_mirror: registry_mirror_params
      expect(registry_mirror.certificate.certificate).to eq("C2")
    end

    it "updates a certificate" do
      registry_mirror_params = {
        name:        registry_mirror_with_cert.name,
        url:         registry_mirror_with_cert.url,
        certificate: "C4"
      }

      put :update, id: registry_mirror_with_cert.id, registry_mirror: registry_mirror_params
      expect(registry_mirror_with_cert.reload.certificate.certificate).to eq("C4")
    end

    it "drops a certificate" do
      registry_mirror_params = {
        name: registry_mirror_with_cert.name,
        url:  registry_mirror_with_cert.url
      }
      expect do
        put :update, id: registry_mirror_with_cert.id, registry_mirror: registry_mirror_params
      end.to change(Certificate, :count).by(-1)
    end

    it "return unprocessable entity status when invalid" do
      registry_mirror_params = { name: registry_mirror.name, url: "invalid" }
      put :update, id: registry_mirror.id, registry_mirror: registry_mirror_params
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE #destroy" do
    it "deletes a RegistryMirror" do
      expect do
        delete :destroy, id: RegistryMirror.first
      end.to(change { RegistryMirror.count })
    end
  end
end
# rubocop:enable RSpec/ExampleLength
