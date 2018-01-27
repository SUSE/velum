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

  context "when in EC2 framework" do
    let(:custom_instance_type) { "custom-instance-type" }
    let(:subnet_id) { "subnet-9d4a7b6c" }
    let(:security_group_id) { "sg-903004f8" }

    let(:expected_response) do
      {
        registries: [],
        cloud:      {
          framework: "ec2",
          profiles:  {
            cluster_node: {
              size:               custom_instance_type,
              network_interfaces: [
                {
                  DeviceIndex:              0,
                  AssociatePublicIpAddress: false,
                  SubnetId:                 subnet_id,
                  SecurityGroupId:          security_group_id
                }
              ]
            }
          }
        }
      }
    end

    before do
      create(:ec2_pillar)
      create(
        :pillar,
        pillar: "cloud:profiles:cluster_node:size",
        value:  custom_instance_type
      )
      create(
        :pillar,
        pillar: "cloud:profiles:cluster_node:network_interfaces:SubnetId",
        value:  subnet_id
      )
      create(
        :pillar,
        pillar: "cloud:profiles:cluster_node:network_interfaces:SecurityGroupId",
        value:  security_group_id
      )
    end

    it "has remote registries and respective mirrors" do
      get :show
      expect(json).to eq(expected_response)
    end
  end
end
