require "rails_helper"

RSpec.describe MinionsController, type: :controller do
  before do
    user = create(:user)
    create(:master_minion)
    create(:worker_minion)
    setup_done
    sign_in user
  end

  describe "destroy minion" do
    let(:minion) { create(:worker_minion) }

    it "is not implemented in public cloud" do
      create(:ec2_pillar)

      delete :destroy, id: minion
      expect(response).to have_http_status(:not_implemented)
    end
  end
end
