require "rails_helper"

describe SaltHandler::AuthEvent do
  let(:minion_id) do
    "3bcb66a2e50646dcabf779e50c6f3232"
  end

  # rubocop:disable Metrics/LineLength
  let(:salt_accept_event) do
    event_data =
      {
        "_stamp" => "2018-09-03T13:54:56.605784",
        "act" => "accept",
        "id" => minion_id,
        "pub" => "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArqE0PfawKs3sIOkh1hvH\nf9XB1Zt2fAufGv0fdFzILSsr8Te9nuz9OIRVNUxVkXONUv5BGw0yNxTY4whvSRLs\ng3HetqG1akLD8psQYWgI2VGOuyIV1fwsV4wx/yQ
            Rb9RqSDWghvFrPLvNKmzkxy3C\nbF75+MzrM67jfktKUDKWABhET2JEMo+nQhgQtxrJ5LVXreJ3097QXVLRZnFMYGQr\nzcjiGzVvvWzQ+uf5fe0mKz5yervqK/GTVA/SBDTVdksuoxFhc1B9xNvXpAjsahJb\noOrcVLhNtT5P3YUDrDpDiLdOG6Pp7mUftp8lTNdQ/b83cIBXP0hm
            gZ8NH50vORbf\n9wIDAQAB\n-----END PUBLIC KEY-----\n",
        "result" => true, "pretag" => nil,
        "tag" => "salt/auth"
      }.to_json

    FactoryGirl.create(:salt_event, tag: "salt/auth", data: event_data)

  end
  # rubocop:enable Metrics/LineLength

  # rubocop:disable Metrics/LineLength
  let(:salt_pend_event) do
    event_data =
      {
        "_stamp" => "2018-09-03T13:54:56.605784",
        "act" => "pend",
        "id" => minion_id,
        "pub" => "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArqE0PfawKs3sIOkh1hvH\nf9XB1Zt2fAufGv0fdFzILSsr8Te9nuz9OIRVNUxVkXONUv5BGw0yNxTY4whvSRLs\ng3HetqG1akLD8psQYWgI2VGOuyIV1fwsV4wx/yQ
            Rb9RqSDWghvFrPLvNKmzkxy3C\nbF75+MzrM67jfktKUDKWABhET2JEMo+nQhgQtxrJ5LVXreJ3097QXVLRZnFMYGQr\nzcjiGzVvvWzQ+uf5fe0mKz5yervqK/GTVA/SBDTVdksuoxFhc1B9xNvXpAjsahJb\noOrcVLhNtT5P3YUDrDpDiLdOG6Pp7mUftp8lTNdQ/b83cIBXP0hm
            gZ8NH50vORbf\n9wIDAQAB\n-----END PUBLIC KEY-----\n",
        "result" => true, "pretag" => nil,
        "tag" => "salt/auth"
      }.to_json

    FactoryGirl.create(:salt_event, tag: "salt/auth", data: event_data)
  end

  # rubocop:enable Metrics/LineLength

  describe "process_event" do
    # rubocop:disable RSpec/ExampleLength
    it "removes a minion from salt cluster" do
      Minion.create! [{ minion_id: minion_id, fqdn: "minion0.k8s.local", role: "master" }]
      handler = described_class.new(salt_pend_event)
      VCR.use_cassette("salt/minion_remove", record: :none) do
        expect { handler.process_event }.to(change { Minion.where(minion_id: minion_id).count }
        .from(1).to(0))
      end
    end
    # rubocop:enable RSpec/ExampleLength

    it "creates a new Minion when one with the specified id does not exist" do
      handler = described_class.new(salt_accept_event)
      VCR.use_cassette("salt/minion_list", record: :none) do
        expect { handler.process_event }.to(change { Minion.where(minion_id: minion_id).count }
          .from(0).to(1))
      end
    end
  end
end
