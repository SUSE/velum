require "rails_helper"

describe "Feature: Settings" do
  let!(:user) { create(:user) }

  before do
    setup_done
    login_as user, scope: :user
  end

  describe "#index" do
    it "redirects to settings_registries_path" do
      visit settings_path
      expect(page).to have_current_path(settings_registries_path)
    end
  end
end
