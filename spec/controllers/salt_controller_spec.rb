# frozen_string_literal: true
require "rails_helper"

RSpec.describe SaltController, type: :controller do
  let(:user)                 { create(:user) }
  let(:master_minion)        { create(:master_minion) }
  let(:worker_minion)        { create(:worker_minion) }
  let(:stubbed) do
    [
      [{ "admin" => "",   master_minion.minion_id => true, worker_minion.minion_id => true }],
      [{ "admin" => true, master_minion.minion_id => true, worker_minion.minion_id => ""   }]
    ]
  end
  before do
    sign_in user
    setup_stubbed_update_status!(stubbed: stubbed)
    allow(::Velum::Salt).to receive(:call).and_return(true)
  end

  describe "POST /update" do
    it "gets an 302 response" do
      VCR.use_cassette("salt/update_orch", record: :none) do
        post :update
        expect(response.status).to eq 302
      end
    end
  end
end
