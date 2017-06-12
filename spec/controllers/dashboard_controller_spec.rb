# frozen_string_literal: true
require "rails_helper"

require "velum/suse_connect"

RSpec.describe DashboardController, type: :controller do
  let(:user)                 { create(:user) }
  let(:minion1)              { create(:minion) }
  let(:minion2)              { create(:minion) }
  let(:master_minion)        { create(:master_minion) }
  let(:worker_minion)        { create(:worker_minion) }
  let(:external_fqdn_pillar) { create(:external_fqdn_pillar) }
  let(:stubbed) do
    [
      [{ "admin" => "",   master_minion.minion_id => true, worker_minion.minion_id => true }],
      [{ "admin" => true, master_minion.minion_id => true, worker_minion.minion_id => ""   }]
    ]
  end

  before do
    minion1 && minion2 # Create two minions (no roles assigned)
    # rubocop:disable RSpec/AnyInstance
    [:minion, :master].each do |role|
      allow_any_instance_of(Velum::SaltMinion).to receive(:assign_role).with(role)
        .and_return(role)
    end
    # rubocop:enable RSpec/AnyInstance
    allow(Velum::Salt).to receive(:orchestrate)
  end

  describe "GET / via HTML" do
    it "gets redirected if not logged in" do
      get :index
      expect(response.status).to eq 302
    end

    it "gets redirected to setup initially" do
      sign_in user
      get :index
      expect(response.status).to eq 302
      expect(response.redirect_url).to eq "http://test.host/setup"
    end

    it "shows a simple monitoring when roles have already been assigned" do
      setup_stubbed_update_status!(stubbed: stubbed)

      sign_in user
      # Create a master minion and a worker minion
      master_minion && worker_minion
      get :index
      expect(response.status).to eq 200
    end
  end

  describe "GET / via JSON" do
    before do
      sign_in user
      # Create a master minion and a worker minion
      master_minion && worker_minion
      request.accept = "application/json"

      setup_stubbed_update_status!(stubbed: stubbed)
    end

    it "renders assigned and unassigned minions" do
      get :index
      expect(response).to have_http_status(:ok)
      ["assigned_minions", "unassigned_minions"].each do |key|
        expect(JSON.parse(response.body).key?(key)).to be true
      end
    end

    # rubocop:disable RSpec/ExampleLength
    # rubocop:disable RSpec/MultipleExpectations
    it "sets the update_status properly" do
      stubbed = [
        [{ "admin" => "", master_minion.minion_id => true, worker_minion.minion_id => true }],
        [{ "admin" => true, master_minion.minion_id => true, worker_minion.minion_id => "" }]
      ]
      allow(::Velum::Salt).to receive(:update_status).and_return(stubbed)

      get :index
      resp = JSON.parse(response.body)
      master = resp["assigned_minions"].find { |m| m["id"] == master_minion.id }
      worker = resp["assigned_minions"].find { |m| m["id"] == worker_minion.id }

      expect(resp["admin"]["update_status"]).to eq(Minion.statuses[:update_failed])
      expect(master["update_status"]).to eq(Minion.statuses[:update_failed])
      expect(worker["update_status"]).to eq(Minion.statuses[:update_needed])
    end
    # rubocop:enable RSpec/ExampleLength
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe "GET /autoyast" do
    before do
      Pillar.create pillar: "dashboard", value: "localhost"
      allow(Velum::SUSEConnect).to receive(:config).and_return(
        Velum::SUSEConnect::SUSEConnectConfig.new("https://scc.suse.com", "validregcode")
      )
    end

    context "no dashboard pillar is set" do
      before do
        Pillar.where(pillar: "dashboard").destroy_all
      end

      it "renders a 503 status and a blank page" do
        get :autoyast
        expect(response.body).to be_blank
        expect(response.status).to eq 503
      end
    end

    it "if not logged in serves the autoyast content" do
      VCR.use_cassette("suse_connect/caasp_registration_active", record: :none) do
        get :autoyast
        expect(response.status).to eq 200
      end
    end

    context "when logged in" do
      before do
        sign_in user
      end

      it "serves the autoyast content" do
        VCR.use_cassette("suse_connect/caasp_registration_active", record: :none) do
          get :autoyast
          expect(response.status).to eq 200
        end
      end
    end

    context "if the credentials are missing for SMT or SCC" do
      before do
        allow(Velum::SUSEConnect).to receive(:config).and_raise(
          Velum::SUSEConnect::MissingCredentialsException
        )
      end

      it "serves the autoyast content" do
        VCR.use_cassette("suse_connect/caasp_registration_active", record: :none) do
          get :autoyast
          expect(response.status).to eq 200
        end
      end
    end

    context "if the registration code is missing" do
      before do
        allow(Velum::SUSEConnect).to receive(:config).and_raise(
          Velum::SUSEConnect::MissingRegCodeException
        )
      end

      it "serves the autoyast content" do
        VCR.use_cassette("suse_connect/caasp_registration_active", record: :none) do
          get :autoyast
          expect(response.status).to eq 200
        end
      end
    end

    context "if there is a connectivity problem with SMT or SCC" do
      before do
        allow(Velum::SUSEConnect).to receive(:config).and_raise(
          Velum::SUSEConnect::SCCConnectionException
        )
      end

      it "renders a 503 status and a blank page" do
        VCR.use_cassette("suse_connect/caasp_registration_active", record: :none) do
          get :autoyast
          expect(response.body).to be_blank
          expect(response.status).to eq 503
        end
      end
    end
  end

  describe "GET /kubectl-config" do
    it "gets redirected if not logged in" do
      get :kubectl_config
      expect(response.status).to eq 302
    end

    context "YAML delivery" do
      before do
        sign_in user
        external_fqdn_pillar
        worker_minion
      end

      it "returns a 302 if the orchestration didn't yet finish" do
        VCR.use_cassette("kubeconfig/cluster_not_ready", record: :none) do
          get :kubectl_config
          expect(response.status).to eq 302
        end
      end

      it "renders the kubeconfig file if the orchestration did finish" do
        VCR.use_cassette("kubeconfig/cluster_ready", record: :none) do
          get :kubectl_config
          expect(response.status).to eq 200
        end
      end
    end
  end
end
