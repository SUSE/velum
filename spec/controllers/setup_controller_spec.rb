# frozen_string_literal: true
require "rails_helper"

# rubocop:disable RSpec/AnyInstance
RSpec.describe SetupController, type: :controller do
  let(:user)   { create(:user)   }
  let(:minion) { create(:minion) }
  let(:settings_params) do
    {
      dashboard:    "dashboard.example.com",
      apiserver:    "apiserver.example.com",
      enable_proxy: "disable"
    }
  end

  before do
    setup_stubbed_pending_minions!
  end

  describe "GET /" do
    it "gets redirected if not logged in" do
      get :welcome
      expect(response.status).to eq 302
    end

    context "HTML rendering" do
      it "returns a 200 if logged in" do
        sign_in user

        get :welcome
        expect(response.status).to eq 200
      end

      it "renders with HTML if no format was specified" do
        sign_in user

        get :welcome
        expect(response["Content-Type"].include?("text/html")).to be true
      end
    end
  end

  describe "GET /setup/worker-bootstrap via HTML" do
    before do
      sign_in user
      Pillar.create pillar: "dashboard", value: "localhost"
    end

    it "sets @controller_node to dashboard pillar value" do
      get :worker_bootstrap
      expect(assigns(:controller_node)).to eq("localhost")
    end
  end

  describe "POST /setup/bootstrap via HTML" do
    let(:salt) { Velum::Salt }
    before do
      sign_in user
      Minion.create! [{ minion_id: SecureRandom.hex, fqdn: "master" },
                      { minion_id: SecureRandom.hex, fqdn: "worker0" }]
    end

    context "when the minion doesn't exist" do
      it "renders an error with not_found" do
        post :bootstrap, roles: { master: [9999999] }
        expect(flash[:error]).to be_present
        expect(response.redirect_url).to eq "http://test.host/setup"
      end
    end

    context "when the user successfully chooses the master" do
      before do
        [:worker, :master].each do |role|
          allow_any_instance_of(Velum::SaltMinion).to receive(:assign_role).with(role)
            .and_return(role)
        end
        allow(salt).to receive(:orchestrate)
      end

      it "sets the master" do
        post :bootstrap, roles: { master: [Minion.first.id], worker: Minion.all[1..-1].map(&:id) }
        expect(Minion.first.role).to eq "master"
      end

      it "sets the other roles to minions" do
        post :bootstrap, roles: { master: [Minion.first.id], worker: Minion.all[1..-1].map(&:id) }
        expect(Minion.where("fqdn REGEXP ?", "worker*").map(&:role).uniq).to eq ["worker"]
      end

      it "calls the orchestration" do
        post :bootstrap, roles: { master: [Minion.first.id], worker: Minion.all[1..-1].map(&:id) }
        expect(salt).to have_received(:orchestrate)
      end

      it "gets redirected to the list of nodes" do
        post :bootstrap, roles: { master: [Minion.first.id], worker: Minion.all[1..-1].map(&:id) }
        expect(response.redirect_url).to eq "http://test.host/"
        expect(response.status).to eq 302
      end
    end

    context "when the user fails to choose the master" do
      before do
        [:worker, :master].each do |role|
          allow_any_instance_of(Velum::SaltMinion).to receive(:assign_role).with(role)
            .and_return(false)
        end
        allow(salt).to receive(:orchestrate)
      end

      it "gets redirected to the discovery page" do
        post :bootstrap, roles: { master: [Minion.first.id], worker: Minion.all[1..-1].map(&:id) }
        expect(flash[:error]).to be_present
        expect(response.redirect_url).to eq "http://test.host/setup/discovery"
      end

      it "doesn't call the orchestration" do
        post :bootstrap, roles: { master: [Minion.first.id], worker: Minion.all[1..-1].map(&:id) }
        expect(Velum::Salt).to have_received(:orchestrate).exactly(0).times
      end
    end

    context "when the user bootstraps without selecting a master" do
      before do
        sign_in user
      end

      it "warns and redirects to the setup_discovery_path" do
        put :bootstrap, settings: {}
        expect(flash[:alert]).to be_present
        expect(response.redirect_url).to eq "http://test.host/setup/discovery"
      end
    end
  end

  describe "POST /setup/bootstrap via JSON" do
    let(:salt) { Velum::Salt }
    before do
      sign_in user
      Minion.create! [{ minion_id: SecureRandom.hex, fqdn: "master" },
                      { minion_id: SecureRandom.hex, fqdn: "worker0" }]
      request.accept = "application/json"
    end

    context "when the minion doesn't exist" do
      it "renders an error with not_found" do
        post :bootstrap, roles: { master: [9999999] }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when the user successfully chooses the master" do
      before do
        [:worker, :master].each do |role|
          allow_any_instance_of(Velum::SaltMinion).to receive(:assign_role).with(role)
            .and_return(role)
        end
        allow(salt).to receive(:orchestrate)
      end

      it "sets the master" do
        post :bootstrap, roles: { master: [Minion.first.id], worker: Minion.all[1..-1].map(&:id) }
        expect(Minion.first.role).to eq "master"
      end

      it "sets the other roles to minions" do
        post :bootstrap, roles: { master: [Minion.first.id], worker: Minion.all[1..-1].map(&:id) }
        expect(Minion.where("fqdn REGEXP ?", "worker*").map(&:role).uniq).to eq ["worker"]
      end

      it "calls the orchestration" do
        post :bootstrap, roles: { master: [Minion.first.id], worker: Minion.all[1..-1].map(&:id) }
        expect(salt).to have_received(:orchestrate)
      end
    end

    context "when the user fails to choose the master" do
      before do
        [:worker, :master].each do |role|
          allow_any_instance_of(Velum::SaltMinion).to receive(:assign_role).with(role)
            .and_return(false)
        end
        allow(salt).to receive(:orchestrate)
      end

      it "returns unprocessable entity" do
        post :bootstrap, roles: { master: [Minion.first.id], worker: Minion.all[1..-1].map(&:id) }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "doesn't call the orchestration" do
        post :bootstrap, roles: { master: [Minion.first.id], worker: Minion.all[1..-1].map(&:id) }
        expect(Velum::Salt).to have_received(:orchestrate).exactly(0).times
      end
    end

    context "when the user bootstraps without selecting a master" do
      before do
        sign_in user
      end

      it "warns and redirects to the setup_discovery_path" do
        put :bootstrap, settings: {}
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PUT /setup via HTML" do
    context "when the user configures the cluster successfully" do
      before do
        sign_in user
        allow_any_instance_of(Pillar).to receive(:save).and_return(true)
      end

      it "gets redirected to the setup_worker_bootstrap_path" do
        put :configure, settings: settings_params
        expect(response.redirect_url).to eq "http://test.host/setup/worker-bootstrap"
        expect(response.status).to eq 302
      end
    end

    context "when the user fails to configure the cluster" do
      before do
        sign_in user
        allow_any_instance_of(Pillar).to receive(:save).and_return(false)
      end

      it "gets redirected to the setup_worker_bootstrap_path with an error" do
        put :configure, settings: settings_params
        expect(flash[:alert]).to be_present
        expect(response.redirect_url).to eq "http://test.host/setup"
      end
    end

    context "proxy disabled" do
      let(:no_proxy_settings) do
        s = settings_params.dup
        s["dashboard"]    = "dashboard"
        s["apiserver"]    = "api.k8s.corporate.net"
        s["enable_proxy"] = "disable"
        s
      end

      let(:proxy_disabled_plus_leftovers) do
        s = no_proxy_settings.dup
        s["http_proxy"] = "squid.corp.net:3128"
        s["https_proxy"] = "squid.corp.net:3128"
        s["no_proxy"] = "localhost"
        s["proxy_systemwide"] = "true"
        s["enable_proxy"] = "disable"
        s
      end

      before do
        sign_in user
      end

      it "disable proxy systemwide" do
        put :configure, settings: no_proxy_settings

        expect(Pillar.value(pillar: :proxy_systemwide)).to eq("false")
      end

      it "erases proxy fields left by the user" do
        # A user could enable proxy, add some data and then disable it
        # before hitting the "submit" button.
        # In this case the proxy settings are still sent to Rails, but
        # the "disable the proxy" setting must have precedence.
        put :configure, settings: proxy_disabled_plus_leftovers

        [:http_proxy, :https_proxy, :no_proxy].each do |key|
          expect(Pillar.find_by(pillar: Pillar.all_pillars[key])).to be_nil
        end

        # this must be set to false, even though the value specied by the user
        # was different
        expect(Pillar.value(pillar: :proxy_systemwide)).to eq("false")
      end

    end

    context "when the user doesn't specify any values" do
      before do
        sign_in user
      end

      it "warns and redirects to the setup_path" do
        put :configure, settings: Hash[settings_params.map { |k, _| [k, ""] }]
        expect(flash[:alert]).to be_present
        expect(response.redirect_url).to eq "http://test.host/setup"
      end
    end
  end

  describe "PUT /setup via JSON" do
    context "when the user configures the cluster successfully" do
      before do
        sign_in user
        allow_any_instance_of(Pillar).to receive(:save).and_return(true)
        request.accept = "application/json"
      end

      it "returns with 200" do
        put :configure, settings: settings_params
        expect(response).to have_http_status(:ok)
      end
    end

    context "when the user fails to configure the cluster" do
      before do
        sign_in user
        allow_any_instance_of(Pillar).to receive(:save).and_return(false)
        request.accept = "application/json"
      end

      it "returns unprocessable entity" do
        put :configure, settings: settings_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when the user doesn't specify any values" do
      before do
        sign_in user
        request.accept = "application/json"
      end

      it "returns unprocessable entity" do
        put :configure, settings: Hash[settings_params.map { |k, _| [k, ""] }]
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /setup/discovery" do
    before do
      sign_in user
      allow_any_instance_of(SetupController).to receive(:redirect_to_dashboard)
        .and_return(true)
      setup_stubbed_update_status!
    end

    it "shows the minions" do
      get :discovery
      expect(response.status).to eq 200
    end
  end
end
# rubocop:enable RSpec/AnyInstance
