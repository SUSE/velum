# frozen_string_literal: true
require "rails_helper"

RSpec.describe NodesController, type: :controller do
  let(:user)   { create(:user)   }
  let(:minion) { create(:minion) }

  describe "GET /nodes" do
    it "gets redirected if not logged in" do
      get :index
      expect(response.status).to eq 302
    end

    context "HTML rendering" do
      it "returns a 200 if logged in" do
        sign_in user

        get :index
        expect(response.status).to eq 200
      end

      it "renders with HTML if no format was specified" do
        sign_in user

        get :index
        expect(response["Content-Type"].include?("application/json")).to be_falsey
      end
    end

    context "JSON response" do
      it "renders with JSON when the format was specified" do
        sign_in user

        get :index, format: :json
        expect(response["Content-Type"].include?("application/json")).to be_truthy
      end

      it "gets all the available minions" do
        sign_in user
        minion.save

        get :index, format: :json
        expect(assigns(:minions)).to eq([minion])
      end
    end
  end

  describe "GET /nodes/:id" do
    it "gets redirected if not logged in" do
      get :index
      expect(response.status).to eq 302
    end

    context "known minion" do
      before { sign_in user }

      it "returns a 200 response" do
        get :show, params: { id: minion.id }
        expect(response.status).to eq 200
      end

      it "fetches the requested minion" do
        get :show, params: { id: minion.id }
        expect(assigns(:minion)).to eq(minion)
      end
    end

    it "returns a 404 for an unknown minion" do
      sign_in user

      expect do
        get :show, params: { id: minion.id + 1 }
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "POST /nodes/bootstrap" do
    let(:salt) { Pharos::Salt }
    before do
      sign_in user
      Minion.create! [{ hostname: "master" }, { hostname: "minion0" }]
    end

    it "calls the orchestration" do
      allow(salt).to receive(:orchestrate)
      VCR.use_cassette("salt/bootstrap", record: :none) do
        post :bootstrap
      end
      expect(salt).to have_received(:orchestrate)
    end

    it "gets redirected to the list of nodes" do
      VCR.use_cassette("salt/bootstrap", record: :none) do
        post :bootstrap
      end
      expect(response.status).to eq 302
    end
  end
end
