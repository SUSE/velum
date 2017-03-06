# frozen_string_literal: true
require "rails_helper"

RSpec.describe SetupController, type: :controller do
  let(:user)   { create(:user)   }
  let(:minion) { create(:minion) }

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
        expect(response["Content-Type"].include?("application/json")).to be_falsey
      end
    end
  end

  describe "POST /setup/bootstrap" do
    let(:salt) { Velum::Salt }
    context "when there are enough minions" do
      before do
        sign_in user
        Minion.create! [{ hostname: "master" }, { hostname: "minion0" }]
        # rubocop:disable RSpec/AnyInstance
        [:minion, :master].each do |role|
          allow_any_instance_of(Velum::SaltMinion).to receive(:assign_role).with(role)
            .and_return(role)
        end
        # rubocop:enable RSpec/AnyInstance
      end

      it "calls the orchestration" do
        allow(salt).to receive(:orchestrate)
        Minion.assign_roles!(roles: { master: Minion.first.id })
        VCR.use_cassette("salt/bootstrap", record: :none) { post :bootstrap }
        expect(salt).to have_received(:orchestrate)
      end

      it "gets redirected to the list of nodes" do
        VCR.use_cassette("salt/bootstrap", record: :none) do
          post :bootstrap
        end
        expect(response.status).to eq 302
      end
    end

    context "when there are not enough minions" do
      before { sign_in user }

      it "doesn't call the orchestration" do
        allow(salt).to receive(:orchestrate)
        post :bootstrap, roles: []
        expect(salt).to have_received(:orchestrate).exactly(0).times
      end

      it "gets redirected to the list of nodes" do
        VCR.use_cassette("salt/bootstrap", record: :none) do
          post :bootstrap
        end
        expect(response.status).to eq 302
        expect(response.redirect_url).to eq "http://test.host/nodes"
      end
    end
  end

end
