require "rails_helper"

describe KubeletComputeResourcesReservation, type: :model do
  it { is_expected.not_to validate_presence_of(:cpu) }
  it { is_expected.not_to validate_presence_of(:memory) }
  it { is_expected.not_to validate_presence_of(:ephemeral_storage) }

  describe "#cpu_validations" do
    let(:reservation) { KubeletComputeResourcesReservation.new(component: "kube") }

    it "allows numbers with digits" do
      reservation.cpu = "0.1"
      expect(reservation.valid?).to be true
    end

    it "does not allow numbers without digits" do
      reservation.cpu = "1"
      expect(reservation.valid?).to be false
    end

    it "allows millicpu format" do
      reservation.cpu = "100m"
      expect(reservation.valid?).to be true
    end

    it "does not allow to mix millicpu format and digits" do
      reservation.cpu = "100.0m"
      expect(reservation.valid?).to be false
    end
  end

  describe "#bytes_validations" do
    let(:reservation) { KubeletComputeResourcesReservation.new(component: "kube") }

    it "allows numbers without suffix" do
      reservation.memory = "1024"
      reservation.ephemeral_storage = "1024"

      expect(reservation.valid?).to be true
    end

    it "does not allow numbers with digits" do
      reservation.memory = "1024.1"
      reservation.ephemeral_storage = "1024.1"

      expect(reservation.valid?).to be false
    end

    it "allows numbers with e-notation" do
      reservation.memory = "129e6"
      reservation.ephemeral_storage = "129e6"

      expect(reservation.valid?).to be true
    end

    it "allows numbers with valid suffixes" do
      %w[E P T G M K Ei Pi Ti Gi Mi Ki].each do |suffix|
        reservation.memory = "1024#{suffix}"
        reservation.ephemeral_storage = "1024#{suffix}"

        expect(reservation.valid?).to be true
      end
    end
  end
end
