require "rails_helper"

RSpec.describe SaltController, type: :controller do
  let(:user) { create(:user) }
  let(:master_minion) do
    create :master_minion, tx_update_reboot_needed: true, tx_update_failed: true
  end
  let(:worker_minion) do
    create :worker_minion, tx_update_reboot_needed: true, tx_update_failed: false
  end

  before do
    sign_in user
  end

  describe "POST /update" do
    it "gets an 302 response" do
      VCR.use_cassette("salt/update_orch", record: :none) do
        post :update
        expect(response.status).to eq 302
      end
    end
  end

  describe "POST /accept-minion" do
    it "gets an 302 response" do
      VCR.use_cassette("salt/accept_node", record: :none) do
        post :accept_minion, minion_id: "81ad05b9d7ae4d26a83c421b64ca1952"
        expect(response.status).to eq 302
      end
    end
  end

  describe "POST /minions/*/remove-minion" do

    it "is not implemented in public cloud" do
      create(:ec2_pillar)

      post :remove_minion, minion_id: master_minion
      expect(response).to have_http_status(:not_implemented)
    end
  end

end
