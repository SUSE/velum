# frozen_string_literal: true
require "rails_helper"

RSpec.describe DashboardController, type: :controller do
  let(:user)   { create(:user) }
  let(:minion) { create(:minion) }

  describe "GET /" do
    it "gets redirected if not logged in" do
      get :index
      expect(response.status).to eq 302
    end

    it "gets all the available minions" do
      sign_in user

      get :index
      expect(response.status).to eq 200
    end
  end
end
