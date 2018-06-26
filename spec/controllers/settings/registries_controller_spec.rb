require "rails_helper"

RSpec.describe Settings::RegistriesController, type: :controller do
  let(:user) { create(:user) }
  let(:admin_cert_text) { file_fixture("admin.crt").read.strip }
  let(:pem_cert) { create(:certificate) }
  let(:pem_cert_text) { pem_cert.certificate.strip }
  let(:pem_cert_file) do
    fixture_file_upload(to_fixture_file(pem_cert.certificate), "application/x-x509-user-cert")
  end
  let(:empty_file) do
    fixture_file_upload(to_fixture_file(""), "text/plain")
  end

  before do
    setup_done
    sign_in user
  end

  describe "GET #index" do
    let!(:other) { create(:registry) }
    let!(:suse) do
      create(:registry, name: Registry::SUSE_REGISTRY_NAME, url: Registry::SUSE_REGISTRY_URL)
    end

    before do
      get :index
    end

    it "populates an array of registries" do
      expect(assigns(:registries)).to match_array([other])
    end

    it "hides SUSE registry from the collection" do
      expect(assigns(:registries)).not_to include(suse)
    end
  end

  describe "GET #show" do
    let!(:suse) do
      create(:registry, name: Registry::SUSE_REGISTRY_NAME, url: Registry::SUSE_REGISTRY_URL)
    end

    it "send 404 status if SUSE registry is accessed" do
      get :show, id: suse.id
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET #new" do
    before do
      get :new
    end

    it "assigns a new Registry to @certificate_holder" do
      expect(assigns(:certificate_holder)).to be_a_new(Registry)
    end

    it "assigns a new Certificate to @cert" do
      expect(assigns(:cert)).to be_a_new(Certificate)
    end
  end

  describe "GET #edit" do
    let!(:certificate) { create(:certificate, certificate: admin_cert_text) }
    let!(:registry) { create(:registry) }
    let!(:registry_with_cert) { create(:registry) }

    context "without certificate" do
      before do
        get :edit, id: registry.id
      end

      it "assigns registry to @registry" do
        expect(assigns(:registry)).not_to be_a_new(Registry)
      end

      it "assigns a new Certificate to @cert" do
        expect(assigns(:cert)).to be_a_new(Certificate)
      end
    end

    context "with certificate" do
      before do
        CertificateService.create!(service: registry_with_cert, certificate: certificate)
        get :edit, id: registry_with_cert.id
      end

      it "assigns registry to @registry" do
        expect(assigns(:registry)).not_to be_a_new(Registry)
      end

      it "assigns registry's certificate to @cert" do
        expect(assigns(:cert)).not_to be_a_new(Certificate)
      end
    end

    it "return 404 if registry does not exist" do
      get :edit, id: Registry.last.id + 1
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST #create" do
    context "without certificate" do
      it "saves the new registry in the database" do
        post :create, registry: { name: "r1", url: "http://local.lan" }
        registry = Registry.find_by(name: "r1")
        expect(registry.name).to eq("r1")
        expect(registry.url).to eq("http://local.lan")
      end

      it "does not save in db and return unprocessable entity status when invalid" do
        expect do
          post :create, registry: { url: "invalid" }
        end.not_to change(Registry, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with certificate" do
      it "saves the new registry in the database" do
        post :create, registry: { name: "r1", url: "http://local.lan", certificate: pem_cert_file }
        registry = Registry.find_by(name: "r1")
        expect(registry.name).to eq("r1")
        expect(registry.certificate.certificate).to eq(pem_cert_text)
      end

      it "does not save in db and return unprocessable entity status when invalid" do
        expect do
          post :create, registry: { name: "", url: "invalid", certificate: pem_cert_file }
        end.not_to change(Registry, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH #update" do
    let!(:certificate) { create(:certificate, certificate: admin_cert_text) }
    let!(:registry) { create(:registry) }
    let!(:registry_with_cert) { create(:registry) }

    before do
      CertificateService.create!(service: registry_with_cert, certificate: certificate)
    end

    it "updates a registry" do
      registry_params = { name: "updated name", url: registry.url }
      put :update, id: registry.id, registry: registry_params
      expect(Registry.find(registry.id).name).to eq("updated name")
    end

    it "creates a new certificate" do
      registry_params = { name: registry.name, url: registry.url, certificate: pem_cert_file }
      put :update, id: registry.id, registry: registry_params
      expect(registry.certificate.certificate).to eq(pem_cert_text)
    end

    # rubocop:disable RSpec/ExampleLength
    it "updates a certificate" do
      registry_params = {
        name:        registry_with_cert.name,
        url:         registry_with_cert.url,
        certificate: pem_cert_file
      }

      put :update, id: registry_with_cert.id, registry: registry_params
      expect(registry_with_cert.reload.certificate.certificate) .to eq(pem_cert_text)
    end
    # rubocop:enable RSpec/ExampleLength

    it "drops a certificate" do
      registry_params = { name: registry_with_cert.name, url: registry_with_cert.url }
      expect do
        put :update, id: registry_with_cert.id, registry: registry_params
      end.to change(Certificate, :count).by(-1)
    end

    it "return unprocessable entity status when invalid" do
      registry_params = { name: registry.name, url: "invalid" }
      put :update, id: registry.id, registry: registry_params
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE #destroy" do
    let!(:registry) { create(:registry) }

    it "deletes a Registry" do
      expect do
        delete :destroy, id: registry.id
      end.to change(Registry, :count).by(-1)
    end
  end
end
