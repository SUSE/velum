# frozen_string_literal: true
require "rails_helper"

# rubocop:disable RSpec/AnyInstance
RSpec.describe SetupController, type: :controller do
  let(:user)   { create(:user)   }
  let(:minion) { create(:minion) }
  let(:settings_params) do
    {
      dashboard:    "dashboard.example.com",
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

    context "previous configure with proxy settings" do
      let(:pillars) do
        {
          dashboard:        "dashboard.example.com",
          http_proxy:       "squid.corp.net:3128",
          https_proxy:      "squid.corp.net:3128",
          no_proxy:         "localhost",
          proxy_systemwide: "true"
        }
      end

      before do
        Pillar.apply(pillars, required_pillars: [:dashboard])

        sign_in user

        get :welcome
      end

      it "assigns @enable_proxy" do
        expect(assigns(:enable_proxy)).to eq(true)
      end

      it "assigns @proxy_systemwide" do
        expect(assigns(:proxy_systemwide)).to eq("true")
      end

      it "assigns @http_proxy" do
        expect(assigns(:http_proxy)).to eq("squid.corp.net:3128")
      end

      it "assigns @https_proxy" do
        expect(assigns(:https_proxy)).to eq("squid.corp.net:3128")
      end

      it "assigns @no_proxy" do
        expect(assigns(:no_proxy)).to eq("localhost")
      end
    end

    context "HTML rendering" do
      before do
        sign_in user

        get :welcome
      end

      it "returns a 200 if logged in" do
        expect(response.status).to eq 200
      end

      it "renders with HTML if no format was specified" do
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

  describe "POST /setup/discovery via HTML" do
    before do
      setup_done apiserver: false
      sign_in user
      Minion.create! [{ minion_id: SecureRandom.hex, fqdn: "master" },
                      { minion_id: SecureRandom.hex, fqdn: "worker0" }]
    end

    context "when the user successfully chooses the master" do
      it "sets the master" do
        post :set_roles, roles: { master: [Minion.first.id], worker: Minion.all[1..-1].map(&:id) }
        expect(Minion.first.role).to eq "master"
      end

      it "sets the other roles to minions" do
        post :set_roles, roles: { master: [Minion.first.id], worker: Minion.all[1..-1].map(&:id) }
        expect(Minion.where("fqdn REGEXP ?", "worker*").map(&:role).uniq).to eq ["worker"]
      end

      it "gets redirected to the bootstrap page" do
        post :set_roles, roles: { master: [Minion.first.id], worker: Minion.all[1..-1].map(&:id) }
        expect(response.redirect_url).to eq setup_bootstrap_url
        expect(response.status).to eq 302
      end
    end

    context "when the user fails to choose the master" do
      before do
        allow_any_instance_of(Minion).to receive(:assign_role).with(:master, remote: false)
          .and_return(false)
        allow_any_instance_of(Minion).to receive(:assign_role).with(:worker, remote: false)
          .and_return(true)
      end

      it "gets redirected to the discovery page" do
        post :set_roles, roles: { master: [Minion.first.id], worker: Minion.all[1..-1].map(&:id) }
        expect(flash[:error]).to be_present
        expect(response.redirect_url).to eq setup_discovery_url
      end
    end

    context "when the user bootstraps without selecting a master" do
      before do
        sign_in user
        Pillar.create pillar: "dashboard", value: "localhost"
      end

      it "warns and redirects to the setup" do
        post :set_roles, roles: {}
        expect(flash[:alert]).to be_present
        expect(response.redirect_url).to eq setup_discovery_url
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
        expect(response.redirect_url).to eq setup_worker_bootstrap_url
        expect(response.status).to eq 302
      end
    end

    context "when the user fails to configure the cluster" do
      before do
        setup_done apiserver: false
        sign_in user
        allow_any_instance_of(Pillar).to receive(:save).and_return(false)
      end

      it "gets redirected to the setup_worker_bootstrap_path with an error" do
        put :configure, settings: settings_params
        expect(flash[:alert]).to be_present
        expect(response.redirect_url).to eq setup_url
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
        expect(response.redirect_url).to eq setup_url
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

  describe "POST /setup/bootstrap" do
    before do
      sign_in user
      allow(Orchestration).to receive(:run)
      Minion.create! [{ minion_id: SecureRandom.hex, fqdn: "master", role: Minion.roles[:master] },
                      { minion_id: SecureRandom.hex, fqdn: "worker0", role: Minion.roles[:worker] }]
    end

    let(:settings_params) do
      {
        apiserver: "apiserver.example.com"
      }
    end

    context "when the pillar fails to save" do
      before do
        allow(Pillar).to receive(:apply).and_return(["apiserver could not be saved"])
      end

      it "redirects to bootstrap path and contains an alert" do
        post :do_bootstrap, settings: settings_params
        expect(flash[:alert]).to be_present
        expect(response.redirect_url).to eq setup_bootstrap_url
      end

      it "does not call the orchestration" do
        post :do_bootstrap, settings: settings_params
        expect(Orchestration).to have_received(:run).exactly(0).times
      end
    end

    context "when assigning roles fails on the remote end" do
      before do
        allow_any_instance_of(Velum::SaltMinion).to receive(:assign_role).and_return(false)
      end

      it "redirects to bootstrap path and contains an error" do
        post :do_bootstrap, settings: settings_params
        expect(flash[:error]).to be_present
        expect(response.redirect_url).to eq setup_bootstrap_url
      end

      it "does not call the orchestration" do
        post :do_bootstrap, settings: settings_params
        expect(Orchestration).to have_received(:run).exactly(0).times
      end
    end

    context "when assigning roles works on the remote end" do
      before do
        allow_any_instance_of(Velum::SaltMinion).to receive(:assign_role).and_return(true)
      end

      it "calls to the orchestration and redirects to the root path" do
        post :do_bootstrap, settings: settings_params
        expect(Orchestration).to have_received(:run).exactly(1).times
        expect(response.redirect_url).to eq root_url
      end
    end
  end
end
# rubocop:enable RSpec/AnyInstance
