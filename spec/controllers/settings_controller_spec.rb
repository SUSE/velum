require "rails_helper"

RSpec.describe SettingsController, type: :controller do
  describe "GET #index" do
    it "redirects to settings_registries_path" do
      get :index
      expect(response).to have_http_status(302)
    end
  end
end
