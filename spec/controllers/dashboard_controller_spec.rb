# frozen_string_literal: true
require "rails_helper"

RSpec.describe DashboardController, type: :controller do
  let(:user)   { create(:user) }
  let(:minion) { create(:minion) }

  before do
    Minion.create! [{ hostname: "master" }, { hostname: "minion0" }]
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
      sign_in user
      Minion.assign_roles!(roles: { master: Minion.first.id, minion: Minion.all[1..-1].map(&:id) })
      get :index
      expect(response.status).to eq 200
    end
  end

  describe "GET / via JSON" do
    before do
      sign_in user
      Minion.assign_roles!(roles: { master: Minion.first.id, minion: Minion.all[1..-1].map(&:id) })
      request.accept = "application/json"
    end

    it "renders assigned and unassigned minions" do
      get :index
      expect(response).to have_http_status(:ok)
      ["assigned_minions", "unassigned_minions"].each do |key|
        expect(JSON.parse(response.body).key?(key)).to be true
      end
    end
  end
end
