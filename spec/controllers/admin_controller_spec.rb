# frozen_string_literal: true
require "rails_helper"

RSpec.describe AdminController, type: :controller do
  let(:user) { create(:user) }

  describe "GET /admin" do
    it "gets redirected if not logged in" do
      get :index
      expect(response.status).to eq 302
    end

    it "gets the index page properly" do
      sign_in user

      get :index
      expect(response.status).to eq 200
    end
  end
end
