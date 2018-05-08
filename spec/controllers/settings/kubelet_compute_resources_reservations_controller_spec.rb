require "rails_helper"

RSpec.describe Settings::KubeletComputeResourcesReservationsController, type: :controller do
  let(:user) { create(:user) }

  before do
    setup_done
    sign_in user
  end

  describe "GET #index" do
    let!(:kube_expected) do
      create(
        :kube_resouces_reservation,
        cpu:               "100m",
        memory:            "1024",
        ephemeral_storage: "1G"
      )
    end

    let!(:system_expected) do
      create(
        :system_resouces_reservation,
        cpu:               "200m",
        memory:            "1024Gi",
        ephemeral_storage: "2M"
      )
    end

    let!(:eviction_expected) do
      e = Pillar.new(
        pillar: "kubelet:eviction-hard",
        value:  "memory.available<10%"
      )
      e.save
      e
    end

    before do
      get :index
    end

    it "populates kube reservations" do
      expect(assigns(:kube_reservations)).to eq(kube_expected)
    end

    it "populates system reservations" do
      expect(assigns(:system_reservations)).to eq(system_expected)
    end

    it "populates eviction hard" do
      expect(assigns(:eviction_hard)).to eq(eviction_expected)
    end

  end

  describe "POST #create" do
    context "when no pre-existing reservations are in place" do
      let(:kube_cpu) { "100m" }
      let(:kube_memory) { "100M" }
      let(:kube_ephemeral_storage) { "1G" }

      let(:system_cpu) { "200m" }
      let(:system_memory) { "200M" }
      let(:system_ephemeral_storage) { "2G" }

      let(:eviction_policy) { "memory.available<10%" }

      before do
        post :create, kubelet_compute_resources_reservations: {
          kube_cpu:                 kube_cpu,
          kube_memory:              kube_memory,
          kube_ephemeral_storage:   kube_ephemeral_storage,
          system_cpu:               system_cpu,
          system_memory:            system_memory,
          system_ephemeral_storage: system_ephemeral_storage,
          eviction_hard:            eviction_policy
        }
      end

      # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
      it "saves the kube reservations" do
        kube_reservations = KubeletComputeResourcesReservation.find_by(
          component: "kube"
        )
        expect(kube_reservations.cpu).to eq(kube_cpu)
        expect(kube_reservations.memory).to eq(kube_memory)
        expect(kube_reservations.ephemeral_storage).to eq(kube_ephemeral_storage)
      end

      it "saves the system reservations" do
        system_reservations = KubeletComputeResourcesReservation.find_by(
          component: "system"
        )
        expect(system_reservations.cpu).to eq(system_cpu)
        expect(system_reservations.memory).to eq(system_memory)
        expect(system_reservations.ephemeral_storage).to eq(system_ephemeral_storage)
      end
      # rubocop:enable RSpec/ExampleLength,RSpec/MultipleExpectations

      it "saves the eviction policy" do
        eviction_hard = Pillar.find_by(pillar: "kubelet:eviction-hard")
        expect(eviction_hard.value).to eq(eviction_policy)
      end
    end

    context "when an eviction policy is already defined" do
      before do
        Pillar.new(
          pillar: "kubelet:eviction-hard",
          value:  "memory.available<10%"
        ).save
      end

      it "removes the eviction policy when an empty value is given" do
        post :create, kubelet_compute_resources_reservations: {
          eviction_hard: ""
        }

        expect(Pillar.find_by(pillar: "kubelet:eviction-hard")).to be_nil
      end
    end

    it "send a 422 response when validation fails" do
      post :create, kubelet_compute_resources_reservations: {
        kube_cpu: "hello"
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
