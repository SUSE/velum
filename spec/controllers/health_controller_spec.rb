require "rails_helper"

RSpec.describe HealthController, type: :controller do
  describe "GET /_health" do
    it "gets an 200 response" do
      get :index
      expect(response.status).to eq 200
    end
  end
end
