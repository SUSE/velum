require "rails_helper"

RSpec.describe InternalApi::V1::PillarsController, type: :controller do
  include ApiHelper

  render_views

  let(:certificate) { Certificate.create certificate: "certificate" }
  let(:expected_flat_pillars_response) do
    {
      dashboard:  "dashboard.example.com",
      registries: []
    }
  end

  before do
    http_login
    request.accept = "application/json"
  end

  describe "GET /pillar" do
    before do
      Pillar.create pillar: "dashboard", value: "dashboard.example.com"
    end

    it "has the expected response status" do
      get :show
      expect(response.status).to eq 200
    end

    it "has the expected contents" do
      get :show
      expect(json).to match expected_flat_pillars_response
    end
  end

  context "when contains registries" do
    let(:expected_registries_response) do
      {
        registries: [
          {
            url:  "https://example.com",
            cert: "certificate"
          },
          {
            url:     "https://remote.registry.com",
            mirrors: [
              {
                url:  "http://mirror.local.lan",
                cert: "certificate"
              },
              {
                url:  "http://mirror2.local.lan",
                cert: nil
              }
            ]
          }
        ]
      }
    end

    before do
      DockerRegistry.create(url: "https://example.com", certificate: certificate)
      DockerRegistry.create(
        url:         "http://mirror.local.lan",
        mirror:      "https://remote.registry.com",
        certificate: certificate
      )
      DockerRegistry.create(url: "http://mirror2.local.lan", mirror: "https://remote.registry.com")
    end

    it "has remote registries and respective mirrors" do
      get :show
      expect(json).to match expected_registries_response
    end
  end
end
