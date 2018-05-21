require "rails_helper"

RSpec.describe Settings::AuditingController, type: :controller do
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
    it "populates the default values" do
      expect(assigns(:audit_enabled)).to eq("false")
      expect(assigns(:maxsize)).to eq(10)
      expect(assigns(:maxage)).to eq(15)
      expect(assigns(:maxbackup)).to eq(20)
      expect(assigns(:policy)).to eq("")
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe "POST #create" do
    context "when setting new valid audit settings" do
      before do
        post :create, audit: { enabled: "true", maxage: 20, maxsize: 20, maxbackup: 30,
                               policy:  "some\n\yaml\npolicy" }
      end

      # rubocop:disable RSpec/MultipleExpectations
      it "saves the new audit settings" do
        expect(Pillar.value(pillar: :api_audit_log_enabled)).to eq("true")
        expect(Pillar.value(pillar: :api_audit_log_maxage)).to eq("20")
        expect(Pillar.value(pillar: :api_audit_log_maxsize)).to eq("20")
        expect(Pillar.value(pillar: :api_audit_log_maxbackup)).to eq("30")
        expect(Pillar.value(pillar: :api_audit_log_policy)).to eq("some\nyaml\npolicy")
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    context "when setting new invalid audit settings" do
      before do
        allow(Pillar).to receive(:apply).and_return ["One error", "Another error"]
        post :create, audit: { enabled: "true", maxage: 20, maxsize: 20, maxbackup: 30,
                               policy:  "some\n\yaml\npolicy" }
      end

      # rubocop:disable RSpec/MultipleExpectations
      it "does not save the new audit settings" do
        expect(assigns(:audit_enabled)).to eq("false")
        expect(assigns(:maxsize)).to eq(10)
        expect(assigns(:maxage)).to eq(15)
        expect(assigns(:maxbackup)).to eq(20)
        expect(assigns(:policy)).to eq("")
      end
      # rubocop:enable RSpec/MultipleExpectations

      it "returns unprocessable entity as http status" do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
