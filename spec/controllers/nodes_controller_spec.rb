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
        get :show, id: minion.id
        expect(response.status).to eq 200
      end

      it "fetches the requested minion" do
        get :show, id: minion.id
        expect(assigns(:minion)).to eq(minion)
      end
    end

    it "returns a 404 for an unknown minion" do
      sign_in user

      expect do
        get :show, id: minion.id + 1
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "POST /nodes/bootstrap" do
    let(:salt) { Velum::Salt }
    context "when there are enough minions" do
      before do
        sign_in user
        Minion.create! [{ hostname: "master" }, { hostname: "minion0" }]
      end

      it "calls the orchestration" do
        allow(salt).to receive(:orchestrate)
        allow_any_instance_of(Velum::SaltMinion).to receive(:assign_role).with(:master)
          .and_return(:master)
        allow_any_instance_of(Velum::SaltMinion).to receive(:assign_role).with(:minion)
          .and_return(:minion)
        Minion.assign_roles!(roles: { Minion.first.hostname => ["master"] })
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

    context "when there are not enough minions" do
      before { sign_in user }

      it "doesn't call the orchestration" do
        allow(salt).to receive(:orchestrate)
        post :bootstrap
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

  # rubocop:disable RSpec/AnyInstance
  # rubocop:disable RSpec/ExampleLength
  # rubocop:disable RSpec/NestedGroups
  describe "PUT /nodes/update" do
    let(:role_payload) do
      {
        "master.example.com"  => ["master"],
        "minion0.example.com" => ["minion"],
        "minion1.example.com" => ["minion"]
      }
    end

    context "HTML rendering" do
      before do
        sign_in user
        Minion.create! [
          { hostname: "master.example.com" },
          { hostname: "minion0.example.com" },
          { hostname: "minion1.example.com" }
        ]
      end
      context "when the minion exists" do
        it "assigns the master role" do
          allow_any_instance_of(Velum::SaltMinion).to receive(:assign_role).with(:master)
            .and_return(:master)
          allow_any_instance_of(Velum::SaltMinion).to receive(:assign_role).with(:minion)
            .and_return(:minion)
          put :update_nodes, roles: role_payload
          expect(response.redirect_url).to eq "http://test.host/nodes"
          # check that all minions are set to minion role
          expect(Minion.where("hostname REGEXP ?", "minion*").map(&:role).uniq).to eq ["minion"]
        end

        it "fails to assign the master role" do
          allow_any_instance_of(Minion).to receive(:assign_role).with(:master).and_return(false)
          allow_any_instance_of(Minion).to receive(:assign_role).with(:minion).and_return(false)
          put :update_nodes, roles: role_payload
          expect(flash[:error]).to be_present
          expect(response.redirect_url).to eq "http://test.host/nodes"
        end

        it "fails to assign the minion role" do
          allow_any_instance_of(Minion).to receive(:assign_role).with(:master).and_return(true)
          allow_any_instance_of(Minion).to receive(:assign_role).with(:minion).and_return(false)
          put :update_nodes, roles: role_payload
          expect(flash[:error]).to be_present
          expect(response.redirect_url).to eq "http://test.host/nodes"
        end
      end

      context "when the minion doesn't exist" do
        it "fails to assign the master role" do
          put :update_nodes, roles: { "doesntexist" => ["master"] }
          expect(flash[:error]).to be_present
          expect(response.redirect_url).to eq "http://test.host/nodes"
        end
      end
    end

    context "JSON response" do
      before do
        sign_in user
        Minion.create! [
          { hostname: "master.example.com" },
          { hostname: "minion0.example.com" },
          { hostname: "minion1.example.com" }
        ]
        request.accept = "application/json"
      end
      context "when the minion exists" do
        it "assigns the master role" do
          allow_any_instance_of(Velum::SaltMinion).to receive(:assign_role).with(:master)
            .and_return(:master)
          allow_any_instance_of(Velum::SaltMinion).to receive(:assign_role).with(:minion)
            .and_return(:minion)
          put :update_nodes, roles: role_payload
          expect(response).to have_http_status(:ok)
          # check that all minions are set to minion role
          expect(Minion.where("hostname REGEXP ?", "minion*").map(&:role).uniq).to eq ["minion"]
        end

        it "fails to assign the master role" do
          allow_any_instance_of(Minion).to receive(:assign_role).with(:master).and_return(false)
          allow_any_instance_of(Minion).to receive(:assign_role).with(:minion).and_return(false)
          allow_any_instance_of(Minion).to receive(:errors).and_return(
            ActiveModel::Errors.new(Minion.find_by(hostname: "master"))
          )
          put :update_nodes, roles: role_payload
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "fails to assign the minion role" do
          allow_any_instance_of(Minion).to receive(:assign_role).with(:master).and_return(true)
          allow_any_instance_of(Minion).to receive(:assign_role).with(:minion).and_return(false)
          put :update_nodes, roles: role_payload
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when the minion doesn't exist" do
        it "fails to assign the master role" do
          put :update_nodes, roles: { "doesntexist" => ["master"] }
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
  # rubocop:enable RSpec/AnyInstance
  # rubocop:enable RSpec/ExampleLength
  # rubocop:enable RSpec/NestedGroups
end
