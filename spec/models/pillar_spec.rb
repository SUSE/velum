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
    subject(:pillar) { described_class.find_or_initialize_by(pillar: "kubelet:eviction-hard") }

    it "is not valid if there is no comparator" do
      pillar.value = "10%"
      pillar.validate

      expect(pillar.errors[:value].first).to eq EvictionValidator::INVALID_SYNTAX
    end

    it "catches as many errors as possible with operands" do
      pillar.value = "memory.lala<10|"
      pillar.validate

      expect(pillar.errors[:value].size).to eq 2
    end

    context "when memory is used" do
      it "is not valid if there is no method specified" do
        pillar.value = "memory<10%"
        pillar.validate

        expect(pillar.errors[:value].first).to(
          eq "`memory` requires something like `memory.available`"
        )
      end

      it "is not valid if the given method is unknown" do
        pillar.value = "memory.IAMERROR<10%"
        pillar.validate

        expect(pillar.errors[:value].first).to eq "unknown `memory.IAMERROR` option"
      end
    end

    # NOTE: 'imagefs' follows the same case as 'nodefs'
    context "when nodefs is used" do
      it "is not valid if there is no method specified" do
        pillar.value = "nodefs<10%"
        pillar.validate

        expect(pillar.errors[:value].first).to(
          eq "`nodefs` requires something like `nodefs.available`"
        )
      end

      it "is not valid if the given method is unknown" do
        pillar.value = "nodefs.IAMERROR<10%"
        pillar.validate

        expect(pillar.errors[:value].first).to eq "unknown `nodefs.IAMERROR` option"
      end

      it "is valid for `available` and for `inodesFree`" do
        %w[available inodesFree].each do |m|
          pillar.value = "nodefs.#{m}<10%"
          expect(pillar).to be_valid
        end
      end
    end

    context "with left value" do
      it "is not valid for unknown values" do
        pillar.value = "IAMERROR.available<10%"
        pillar.validate

        expect(pillar.errors[:value].first).to eq "unknown component `IAMERROR`"
      end
    end

    context "with right value" do
      it "accepts percentages" do
        pillar.value = "memory.available<10%"
        expect(pillar).to be_valid
      end

      it "accepts percentages with dots in it" do
        pillar.value = "memory.available<10.55%"
        expect(pillar).to be_valid
      end

      it "accepts lone numbers" do
        pillar.value = "memory.available<10"
        expect(pillar).to be_valid
      end

      it "accepts lone numbers with dots in it" do
        pillar.value = "memory.available<10.0"
        expect(pillar).to be_valid
      end

      it "accepts valid suffixes" do
        %w[E P T G M K Ei Pi Ti Gi Mi Ki].each do |suffix|
          pillar.value = "memory.available<1024#{suffix}"
          expect(pillar).to be_valid
        end
      end

      it "accepts exponential numbers" do
        pillar.value = "memory.available<10e6M"
        expect(pillar).to be_valid
      end

      it "does not accept weird suffixes" do
        pillar.value = "memory.available<10|"
        pillar.validate

        msg = "invalid syntax for right side (i.e. expected something like `1.5Gi` or `10%`)"
        expect(pillar.errors[:value].first).to eq msg
      end
    end
  end
end
