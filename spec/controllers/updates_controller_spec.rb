# frozen_string_literal: true
require "rails_helper"

RSpec.describe UpdatesController, type: :controller do
  before do
    user = create(:user)
    create(:master_minion)
    create(:worker_minion)
    sign_in user
  end

  describe "reboot admin node" do
    it "does nothing if no update was needed" do
      stubbed = [[{ "admin" => "" }], [{ "admin" => "" }]]
      setup_stubbed_update_status!(stubbed: stubbed)

      post :create
      expect(flash[:error]).to eq "There's no need to update"
    end

    it "allows the node to reboot if an update is needed" do
      allow(::Velum::Salt).to receive(:call).and_return(true)
      stubbed = [[{ "admin" => true }], [{ "admin" => "" }]]
      setup_stubbed_update_status!(stubbed: stubbed)

      post :create
      expect(flash[:info]).to eq "Rebooting..."
    end

    it "allows the node to reboot if a previous update failed" do
      allow(::Velum::Salt).to receive(:call).and_return(true)
      stubbed = [[{ "admin" => "" }], [{ "admin" => true }]]
      setup_stubbed_update_status!(stubbed: stubbed)

      post :create
      expect(flash[:info]).to eq "Rebooting..."
    end
  end
end
