require "rails_helper"

RSpec.describe InternalApi::V1::PillarsController, type: :controller do
  include ApiHelper

  render_views

  let(:certificate) { Certificate.create certificate: "certificate" }
  let(:expected_response) do
    {
      dashboard:  "dashboard.example.com",
      registries: [
        {
          url:         "https://example.com",
          mirror:      nil,
          certificate: "certificate"
        }
      ]
    }
  end

  before do
    http_login
    request.accept = "application/json"
  end

  describe "GET /pillar" do
    before do
      Pillar.create pillar: "dashboard", value: "dashboard.example.com"
      DockerRegistry.create url: "https://example.com", certificate: certificate
    end

    it "has the expected response status" do
      get :show
      expect(response.status).to eq 200
    end

    it "has the expected contents" do
      get :show
      expect(json).to match expected_response
    end
  end

end
