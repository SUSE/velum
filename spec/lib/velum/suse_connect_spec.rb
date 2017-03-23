# frozen_string_literal: true
require "rails_helper"
require "velum/suse_connect"

describe Velum::SUSEConnect do

  context "when loading SUSEConnect settings" do
    context "when the file exists" do
      before do
        allow(YAML).to receive(:load_file).with("/run/secrets/SUSEConnect")
          .and_return("url" => "https://smt.mycompany.com")
      end

      it "returns the contents unmarshalled" do
        expect(described_class.smt_config_file_contents(prefix: "/run/secrets")).to(
          eq("url" => "https://smt.mycompany.com")
        )
      end
    end
    context "when the file does not exist" do
      before do
        allow(YAML).to receive(:load_file).with("/run/secrets/SUSEConnect")
          .and_raise(Errno::ENOENT)
      end

      it "returns nil" do
        expect(described_class.smt_config_file_contents(prefix: "/run/secrets")).to be_nil
      end
    end
  end

  context "smt server set as https://smt.mycompany.com" do
    before do
      allow(described_class).to receive(:smt_config_file_contents)
        .and_return("url" => "https://smt.mycompany.com")
    end

    it "returns a SUSEConnectConfig with https://smt.mycompany.com as smt_url" do
      expect(described_class.config.smt_url).to eq("https://smt.mycompany.com")
    end

    it "returns a SUSEConnectConfig without regcode" do
      expect(described_class.config.regcode).to be_nil
    end

    it "returns https://smt.mycompany.com as smt_url" do
      expect(described_class.smt_url).to eq("https://smt.mycompany.com")
    end

    it "raises an exception about missing credentials" do
      expect do
        described_class.credentials
      end.to raise_error(Velum::SUSEConnect::MissingCredentialsException)
    end
  end

  context "smt server not set (defaults to https://scc.suse.com)" do
    before do
      allow(described_class).to receive(:smt_config_file_contents).and_return({})
    end

    it "returns the SCC server" do
      expect(described_class.smt_url).to eq("https://scc.suse.com")
    end

    context "when credentials exist" do
      before do
        allow(described_class).to receive(:credentials_file_contents)
          .and_return("username=username\npassword=password")
      end

      it "returns a SUSEConnectConfig with https://scc.suse.com as smt_url" do
        VCR.use_cassette("suse_connect/caasp_registration_active", record: :none) do
          expect(described_class.config.smt_url).to eq("https://scc.suse.com")
        end
      end

      it "returns a SUSEConnectConfig with regcode" do
        VCR.use_cassette("suse_connect/caasp_registration_active", record: :none) do
          expect(described_class.config.regcode).not_to be_nil
        end
      end

      it "does return SCC credentials" do
        expect(described_class.credentials).to eq(username: "username",
                                                  password: "password")
      end
    end
    context "when credentials are missing" do
      before do
        allow(described_class).to receive(:credentials_file_contents).and_return(nil)
      end

      it "asking for config should raise an exception" do
        expect do
          described_class.config
        end.to raise_error(Velum::SUSEConnect::MissingCredentialsException)
      end

      it "raises an exception about missing credentials" do
        expect do
          described_class.credentials
        end.to raise_error(Velum::SUSEConnect::MissingCredentialsException)
      end
    end
  end

  context "when requesting the regcode for CaaSP product" do
    let(:suse_connect_client) do
      described_class.new credentials: {
        username: "valid_username",
        password: "valid_password"
      }
    end

    context "with connectivity problems with smt service" do
      before { allow(Net::HTTP).to receive(:start).and_raise(Errno::ECONNREFUSED) }

      it "raises SCCConnectionException" do
        expect do
          suse_connect_client.regcode
        end.to raise_error(Velum::SUSEConnect::SCCConnectionException)
      end
    end

    context "with an unexpected response from the SCC service" do
      before { allow(Net::HTTP).to receive(:start).and_return(Net::HTTPInternalServerError) }

      it "raises SCCConnectionException" do
        expect do
          suse_connect_client.regcode
        end.to raise_error(Velum::SUSEConnect::SCCConnectionException)
      end
    end

    context "with valid login information if there a CaaSP registration active" do
      it "returns the regcode for the product" do
        VCR.use_cassette("suse_connect/caasp_registration_active", record: :none) do
          suse_connect_client.regcode
        end
      end
    end

    context "with valid login information if there is no such product" do
      it "does raise an exception" do
        VCR.use_cassette("suse_connect/no_caasp_registration_active", record: :none) do
          expect do
            suse_connect_client.regcode
          end.to raise_error(Velum::SUSEConnect::MissingRegCodeException)
        end
      end
    end

    context "with invalid login information" do
      let(:suse_connect_client) do
        described_class.new credentials: {
          username: "invalid_username",
          password: "invalid_password"
        }
      end

      it "does raise an exception" do
        VCR.use_cassette("suse_connect/invalid_credentials", record: :none) do
          expect do
            suse_connect_client.regcode
          end.to raise_error(Velum::SUSEConnect::SCCConnectionException)
        end
      end
    end
  end
end
