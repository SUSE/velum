# coding: utf-8

describe Pillar do
  subject { create(:pillar) }

  it { is_expected.to validate_presence_of(:pillar) }
  it { is_expected.to validate_presence_of(:value) }

  describe "Validator" do
    context "on protected values" do
      it "does not allow non-ascii digits" do
        name = described_class.all_pillars[:city]
        pillar = described_class.create pillar: name, value: "Nürnberg"

        expect(pillar.errors.messages).to eq(value: ["contains invalid characters"])
      end

      it "does allow alphabetical" do
        name = described_class.all_pillars[:city]
        pillar = described_class.create pillar: name, value: "Nuernberg"

        expect(pillar.errors.messages).to be_empty
      end
    end

    context "on non-protected values" do
      it "does allow non-ascii digits" do
        pillar = described_class.create pillar: "something.foo", value: "Nürnberg"

        expect(pillar.errors.messages).to be_empty
      end
    end
  end

  describe "#apply" do
    let(:settings_params) do
      {
        apiserver:    "something",
        city:         "Nuremberg",
        company_name: "SUSE Linux GmbH",
        company_unit: "Research and development",
        country:      "DE",
        dashboard:    "something",
        email:        "containers@suse.de",
        state:        "Bavaria"
      }
    end

    let(:expectations) do
      [
        "'apiserver' could not be saved: can't be blank.",
        "'city' could not be saved: contains invalid characters.",
        "'company_name' could not be saved: contains invalid characters.",
        "'dashboard' could not be saved: can't be blank.",
        "'email' could not be saved: can't be blank.",
        "'state' could not be saved: contains invalid characters."
      ]
    end

    # rubocop:disable RSpec/ExampleLength
    it "returns all the errors" do
      res = described_class.apply(
        city:         "Nürnberg",   # UTF-8 character
        state:        "Sòmething1", # Number not allowed
        country:      "DE",
        company_unit: "It can have, spac3s and numb3rs!",
        company_name: "Però no pot tenir UTF-8"
      ).sort

      expect(res).to eq(expectations)
    end
    # rubocop:enable RSpec/ExampleLength

    it "returns an empty array when everything is fine" do
      res = described_class.apply(settings_params)
      expect(res).to be_empty
    end
  end
end
