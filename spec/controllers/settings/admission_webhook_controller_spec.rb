require "rails_helper"

RSpec.describe Settings::AdmissionWebhookController, type: :controller do
  let(:user) { create :user }

  before do
    setup_done
    sign_in user
  end

  describe "GET #index" do
    before do
      get :index
    end

    # rubocop:disable RSpec/MultipleExpectations
    it "populates initial variables" do
      expect(assigns(:admission_webhook_enabled)).to eq(false)
      expect(assigns(:cert)).to be_nil
      expect(assigns(:key)).to be_nil
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe "POST #create" do
    let(:cert_file) { fixture_file_upload("admin.crt") }
    let(:key_file) { fixture_file_upload("admin.key") }

    context "when setting new admission webhook setting" do
      before do
        post :create, admission_webhook: {
          enabled:   "true",
          cert_file: cert_file,
          key_file:  key_file
        }
        # we need to move the cursor to the beginning so #read can work again as expected
        cert_file.rewind
        key_file.rewind
      end

      # rubocop:disable RSpec/MultipleExpectations
      it "saves the settings" do
        expect(Pillar.value(pillar: :api_admission_webhook_enabled)).to eq("true")
        expect(Pillar.value(pillar: :api_admission_webhook_cert)).to eq(cert_file.read)
        expect(Pillar.value(pillar: :api_admission_webhook_key)).to eq(key_file.read)
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    context "when enabled is 'false'" do
      before do
        post :create, admission_webhook: {
          enabled:   "false",
          cert_file: cert_file,
          key_file:  key_file
        }
        # we need to move the cursor to the beginning so #read can work again as expected
        cert_file.rewind
        key_file.rewind
      end

      # rubocop:disable RSpec/MultipleExpectations
      it "doesn't save the settings" do
        expect(Pillar.value(pillar: :api_admission_webhook_enabled)).to eq("false")
        expect(Pillar.value(pillar: :api_admission_webhook_cert)).to be_nil
        expect(Pillar.value(pillar: :api_admission_webhook_key)).to be_nil
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    context "when Pillar.apply returns an error" do
      before do
        allow(Pillar).to receive(:apply).and_return ["One error", "Another error"]
        post :create, admission_webhook: {
          enabled:   "true",
          cert_file: cert_file,
          key_file:  key_file
        }
      end

      it "returns unprocessable entity as http status" do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when invalid params" do
      before do
        post :create, admission_webhook: { enabled: "true" }
      end

      it "returns unprocessable entity as http status" do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
