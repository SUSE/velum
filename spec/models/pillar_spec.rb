describe Pillar do
  subject { create(:pillar) }

  it { is_expected.to validate_presence_of(:pillar) }
  it { is_expected.to validate_presence_of(:value) }

  describe "#apply" do
    let(:settings_params) do
      {
        dashboard:        "dashboard.example.com",
        apiserver:        "apiserver.example.com",
        proxy_systemwide: "false"
      }
    end

    it "returns an empty array when everything is fine" do
      res = described_class.apply(settings_params)
      expect(res).to be_empty
    end

    context "when proxy settings are disabled" do
      let(:proxy_enabled_settings_params) do
        proxy_enabled = settings_params.dup
        proxy_enabled[:http_proxy]  = "squid.corp.net:3128"
        proxy_enabled[:https_proxy] = "squid.corp.net:3128"
        proxy_enabled[:no_proxy]    = "localhost"
        proxy_enabled
      end

      let(:proxy_pillars_that_can_be_blank) do
        [:http_proxy, :https_proxy, :no_proxy]
      end

      before do
        described_class.apply(proxy_enabled_settings_params)
      end

      it "has the expected attributes set to nil" do
        proxy_pillars_that_can_be_blank.each do |key|
          expect(settings_params[key]).to be_nil
        end
      end

      it "removes proxy pillars when blank" do
        described_class.apply(settings_params)

        proxy_pillars_that_can_be_blank.each do |key|
          expect(described_class.find_by(pillar: key)).to be_nil
        end
      end
    end
  end

  describe "EvictionValidator" do
    subject { Pillar.find_or_initialize_by(pillar: "kubelet:eviction-hard") }

    it "is not valid if there is no comparator" do
      subject.value = "10%"
      subject.validate

      expect(subject.errors[:value].first).to eq EvictionValidator::INVALID_SYNTAX
    end

    context "memory" do
      it "is not valid if there is no method specified" do
        subject.value = "memory<10%"
        subject.validate

        expect(subject.errors[:value].first).to eq "`memory` requires something like `memory.available`"
      end

      it "is not valid if the given method is unknown" do
        subject.value = "memory.IAMERROR<10%"
        subject.validate

        expect(subject.errors[:value].first).to eq "unknown `memory.IAMERROR` option"
      end
    end

    # NOTE: 'imagefs' follows the same case as 'nodefs'
    context "nodefs" do
      it "is not valid if there is no method specified" do
        subject.value = "nodefs<10%"
        subject.validate

        expect(subject.errors[:value].first).to eq "`nodefs` requires something like `nodefs.available`"
      end

      it "is not valid if the given method is unknown" do
        subject.value = "nodefs.IAMERROR<10%"
        subject.validate

        expect(subject.errors[:value].first).to eq "unknown `nodefs.IAMERROR` option"
      end

      it "is valid for `available` and for `inodesFree`" do
        %w[available inodesFree].each do |m|
          subject.value = "nodefs.#{m}<10%"
          expect(subject).to be_valid
        end
      end
    end

    context "right value" do
      it "accepts percentages" do
        subject.value = "memory.available<10%"
        expect(subject).to be_valid
      end

      it "accepts percentages with dots in it" do
        subject.value = "memory.available<10.55%"
        expect(subject).to be_valid
      end

      it "accepts lone numbers" do
        subject.value = "memory.available<10"
        expect(subject).to be_valid
      end

      it "accepts lone numbers with dots in it" do
        subject.value = "memory.available<10.0"
        expect(subject).to be_valid
      end

      it "accepts valid suffixes" do
        %w[E P T G M K Ei Pi Ti Gi Mi Ki].each do |suffix|
          subject.value = "memory.available<1024#{suffix}"
          expect(subject).to be_valid
        end
      end

      it "accepts exponential numbers" do
        subject.value = "memory.available<10e6M"
        expect(subject).to be_valid
      end
    end
  end
end
