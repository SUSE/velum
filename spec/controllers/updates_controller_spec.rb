require "rails_helper"

RSpec.describe UpdatesController, type: :controller do
  before do
    user = create(:user)
    create(:master_minion)
    create(:worker_minion)
    setup_done
    sign_in user

    allow(::Velum::Salt).to receive(:call).and_return(true)
  end

  describe "reboot admin node" do
    it "returns a json response" do
      post :create
      expect(response.content_type).to eq "application/json"
    end

    it "does nothing if no update was needed" do
      post :create
      json = JSON.parse(response.body)
      expect(json["status"]).to eq "unknown"
    end

    # rubocop:disable RSpec/ExampleLength
    it "allows the node to reboot if an update is needed" do
      # rubocop:disable Rails/SkipsModelValidations
      Minion.where(minion_id: "admin").update_all(tx_update_reboot_needed: true,
                                                  tx_update_failed:        false)
      # rubocop:enable Rails/SkipsModelValidations
      post :create
      json = JSON.parse(response.body)
      expect(json["status"]).to eq "rebooting"
      expect(::Velum::Salt).to have_received(:call).once
    end

    it "allows the node to reboot if a previous update failed" do
      # rubocop:disable Rails/SkipsModelValidations
      Minion.where(minion_id: "admin").update_all(tx_update_reboot_needed: false,
                                                  tx_update_failed:        true)
      # rubocop:enable Rails/SkipsModelValidations
      post :create
      json = JSON.parse(response.body)
      expect(json["status"]).to eq "rebooting"
      expect(::Velum::Salt).to have_received(:call).once
    end
    # rubocop:enable RSpec/ExampleLength
  end
end
