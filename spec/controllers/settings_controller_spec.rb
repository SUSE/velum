require "rails_helper"

RSpec.describe SettingsController, type: :controller do
  let(:user) { create(:user) }

  before do
    setup_done
    sign_in user
  end

  describe "GET #index" do
    it "redirects to settings_registries_path" do
      get :index
      expect(response).to have_http_status(302)
    end
  end

  describe "POST #apply" do
    it "marks bootstrap as pending" do
      allow(Orchestration).to receive(:run).and_return(true)
      post :apply
      expect(Minion.pending.count).to eq(Minion.cluster_role.count)
    end

    it "doesn't allow multiple orchestrations" do
      allow(request).to receive(:referer).and_return("/")
      allow(Orchestration).to receive(:runnable?).and_return false
      post :apply
      expect(Minion.pending.count).to be_zero
      expect(response).to have_http_status(302)
    end

    it "redirects to settings_registries_path" do
      allow(Orchestration).to receive(:run).and_return(true)
      post :apply
      expect(response).to have_http_status(302)
    end
  end
end
