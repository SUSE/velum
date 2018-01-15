require "rails_helper"

RSpec.describe Orchestrations::BootstrapController, type: :controller do
  let(:user)   { create(:user)   }
  let(:minion) { create(:minion) }

  before do
    sign_in user
    setup_done
    setup_stubbed_pending_minions!
    allow(Orchestration).to receive(:run).with(kind: :bootstrap)
  end

  describe "POST /orchestrations/bootstrap via HTML" do
    context "when there is no orchestration to retry" do
      it "redirects to the root path" do
        post :create
        expect(response.redirect_url).to eq root_url
        expect(Orchestration).not_to have_received(:run)
      end
    end

    context "when an orchestration can be retried" do
      before do
        FactoryGirl.create :orchestration,
                           status: "failed"
      end

      it "spawns a new orchestration" do
        post :create
        expect(response.redirect_url).to eq root_url
        expect(Orchestration).to have_received(:run).once.with(kind: :bootstrap)
      end
    end
  end
end
