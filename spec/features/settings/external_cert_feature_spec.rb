require "rails_helper"

# rubocop:disable RSpec/ExampleLength
describe "Feature: External Cerificate settings", js: true do

  success_message = "External Certificate settings successfully saved."

  let!(:user) { create(:user) }
  let!(:fixture_path) { RSpec.configuration.fixture_path }

  # Valid Velum set A
  let(:crt_v_a) { File.join(fixture_path, "external_certs/velum_a.crt") }
  let(:key_v_a) { File.join(fixture_path, "external_certs/velum_a.key") }

  # Valid Velum set B
  let(:crt_v_b) { File.join(fixture_path, "external_certs/velum_b.crt") }
  let(:key_v_b) { File.join(fixture_path, "external_certs/velum_b.key") }

  # Valid Kubeapi set A
  let(:crt_k_a) { File.join(fixture_path, "external_certs/kubeapi_a.crt") }
  let(:key_k_a) { File.join(fixture_path, "external_certs/kubeapi_a.key") }

  # Valid Kubeapi set B
  let(:crt_k_b) { File.join(fixture_path, "external_certs/kubeapi_b.crt") }
  let(:key_k_b) { File.join(fixture_path, "external_certs/kubeapi_b.key") }

  # Valid Dex set A
  let(:crt_d_a) { File.join(fixture_path, "external_certs/dex_a.crt") }
  let(:key_d_a) { File.join(fixture_path, "external_certs/dex_a.key") }

  # Valid Dex set B
  let(:crt_d_b) { File.join(fixture_path, "external_certs/dex_b.crt") }
  let(:key_d_b) { File.join(fixture_path, "external_certs/dex_b.key") }

  # *** Following sets of certs and keys are valid except for the stated ways ***

  # Malformed. Both are malformed
  let(:crt_malformed) { File.join(fixture_path, "external_certs/malformed.crt") }
  let(:key_malformed) { File.join(fixture_path, "external_certs/malformed.key") }

  # Expired
  let(:crt_v_expired) { File.join(fixture_path, "external_certs/expired.crt") }
  let(:key_v_expired) { File.join(fixture_path, "external_certs/expired.key") }

  # Weak - 1024 bit keylength
  let(:crt_v_weak) { File.join(fixture_path, "external_certs/weak.crt") }
  let(:key_v_weak) { File.join(fixture_path, "external_certs/weak.key") }

  # Weak Message Digest - Using SHA1
  let(:crt_v_sha1) { File.join(fixture_path, "external_certs/sha1_digest.crt") }
  let(:key_v_sha1) { File.join(fixture_path, "external_certs/sha1_digest.key") }

  # CAs for chain validation
  let(:crt_root) { File.join(fixture_path, "external_certs/ca_root.crt") }
  let(:crt_intermed) { File.join(fixture_path, "external_certs/ca_intermed.crt") }
  let(:crt_intermed2) { File.join(fixture_path, "external_certs/ca_intermed2.crt") }

  # Bad Subject Alternative Names
  let(:crt_v_badalt) { File.join(fixture_path, "external_certs/badalt.crt") }
  let(:key_v_badalt) { File.join(fixture_path, "external_certs/badalt.key") }

  # No Subject Alternative Names
  let(:crt_v_noalt) { File.join(fixture_path, "external_certs/noalt.crt") }
  let(:key_v_noalt) { File.join(fixture_path, "external_certs/noalt.key") }

  before do
    setup_done
    login_as user, scope: :user
  end

  describe "#index with invalid chain" do
    before do
      visit settings_external_cert_index_path
    end

    it "fails without CAs being set system wide" do
      attach_file("external_certificate_velum_cert", crt_v_a)
      attach_file("external_certificate_velum_key", key_v_a)

      click_button("Save")
      expect(page).to have_http_status(:unprocessable_entity)
      expect(page).to have_content("Certificate verification failed")
    end

    it "fails with only the root CA" do
      # Set only the root of the cert chain
      SystemCertificate.create_system_certificate(
        name:        :root,
        certificate: File.open(crt_root, "r")
      )

      # Sanity check
      system_certificate = SystemCertificate.find_by(name: "root")
      expect(system_certificate.name).to eq("root")

      visit settings_external_cert_index_path

      attach_file("external_certificate_velum_cert", crt_v_a)
      attach_file("external_certificate_velum_key", key_v_a)

      click_button("Save")
      expect(page).to have_http_status(:unprocessable_entity)
      expect(page).to have_content("Certificate verification failed")
    end
  end

  # rubocop:disable RSpec/ExpectInHook
  describe "#index with valid chain" do
    before do
      # Set the full cert chain
      SystemCertificate.create_system_certificate(
        name:        :root,
        certificate: File.open(crt_root, "r")
      )
      SystemCertificate.create_system_certificate(
        name:        :intermed,
        certificate: File.open(crt_intermed, "r")
      )
      SystemCertificate.create_system_certificate(
        name:        :intermed2,
        certificate: File.open(crt_intermed2, "r")
      )

      # Sanity checks
      system_certificate = SystemCertificate.find_by(name: "root")
      expect(system_certificate.name).to eq("root")
      system_certificate = SystemCertificate.find_by(name: "intermed")
      expect(system_certificate.name).to eq("intermed")
      system_certificate = SystemCertificate.find_by(name: "intermed2")
      expect(system_certificate.name).to eq("intermed2")

      visit settings_external_cert_index_path
    end
    # rubocop:enable RSpec/ExpectInHook

    # Success Conditions

    it "correctly shows notice messages" do
      # Does not contain 'expect(page).to have_http_status' assertion because of a
      # race condition that detects the redirect http status and not the final status.
      # This problem occurs when this assertion is before any Capybara actions.
      expect(page).to have_content("Enable the use of External SSL Certificates for " \
      "CaaSP and Kubernetes services. Certificates and matching keys must be in armored " \
      "PEM format.")
      expect(page).to have_content("Certificate not available, please upload a certificate",
      count: 3)
      expect(page).to have_content("Key not available, please upload a key", count: 3)
    end

    it "saves the form with nothing attached" do
      click_button("Save")
      expect(page).to have_http_status(:success)
      expect(page).to have_content(success_message)
    end

    it "sucessfully uploads velum cert/key" do
      attach_file("external_certificate_velum_cert", crt_v_a)
      attach_file("external_certificate_velum_key", key_v_a)

      click_button("Save")
      expect(page).to have_http_status(:success)
      expect(page).to have_content(success_message)
    end

    it "sucessfully uploads kubeAPI cert/key" do
      attach_file("external_certificate_kubeapi_cert", crt_k_a)
      attach_file("external_certificate_kubeapi_key", key_k_a)

      click_button("Save")
      expect(page).to have_http_status(:success)
      expect(page).to have_content(success_message)
    end

    it "sucessfully uploads dex cert/key" do
      attach_file("external_certificate_dex_cert", crt_d_a)
      attach_file("external_certificate_dex_key", key_d_a)

      click_button("Save")
      expect(page).to have_http_status(:success)
      expect(page).to have_content(success_message)
    end

    it "sucessfully uploads velum, kubeAPI, and dex cert/key" do
      attach_file("external_certificate_velum_cert", crt_v_a)
      attach_file("external_certificate_velum_key", key_v_a)
      attach_file("external_certificate_kubeapi_cert", crt_k_a)
      attach_file("external_certificate_kubeapi_key", key_k_a)
      attach_file("external_certificate_dex_cert", crt_d_a)
      attach_file("external_certificate_dex_key", key_d_a)

      click_button("Save")
      expect(page).to have_http_status(:success)
      expect(page).to have_content(success_message)
    end

    it "sucessfully lists Subject Alternative Names" do
      attach_file("external_certificate_velum_cert", crt_v_b)
      attach_file("external_certificate_velum_key", key_v_b)

      click_button("Save")
      expect(page).to have_http_status(:success)
      expect(page).to have_content("testdomain.com")
    end

    it "uploads velum cert with a weak RSA bit length key (<= 2048)" do
      attach_file("external_certificate_velum_cert", crt_v_weak)
      attach_file("external_certificate_velum_key", key_v_weak)

      click_button("Save")
      expect(page).to have_http_status(:success)
      expect(page).to have_content("RSA key bit length should be greater than or equal to 2048")
    end

    it "uploads velum cert with a weak hash algorithm (sha1)" do
      attach_file("external_certificate_velum_cert", crt_v_sha1)
      attach_file("external_certificate_velum_key", key_v_sha1)

      click_button("Save")
      expect(page).to have_http_status(:success)
      expect(page).to have_content("Certificate includes a weak signature hash algorithm")
    end

    it "page contains required Velum hostnames" do
      find('a[href="#collapseVelum"]').click

      # This line does not belong as it will ocasionally fail with code 304 not modified
      # expect(page).to have_http_status(:success)
      expect(page).to have_content("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.infra.caasp.local", wait: 1)
    end

    it "is missing required SubjectAltNames in certificate" do
      attach_file("external_certificate_velum_cert", crt_v_badalt)
      attach_file("external_certificate_velum_key", key_v_badalt)

      click_button("Save")
      expect(page).to have_http_status(:success)
      expect(page).to have_content("Warning, Velum is missing the following hostnames in its " \
        "certificate: admin.devenv.caasp.suse.net 10.17.1.0 admin admin.infra.caasp.local " \
        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.infra.caasp.local")
    end

    it "is has no SubjectAltNames in certificate" do
      attach_file("external_certificate_velum_cert", crt_v_noalt)
      attach_file("external_certificate_velum_key", key_v_noalt)

      click_button("Save")
      expect(page).to have_http_status(:success)
      expect(page).to have_content("Warning, Velum is missing the following hostnames in its " \
        "certificate: admin.devenv.caasp.suse.net 10.17.1.0 admin admin.infra.caasp.local " \
        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.infra.caasp.local")
    end

    # Failure Conditions

    it "uploads malformed velum certificate" do
      attach_file("external_certificate_velum_cert", crt_malformed)
      attach_file("external_certificate_velum_key", key_v_a)

      click_button("Save")
      expect(page).to have_http_status(:unprocessable_entity)
      expect(page).to have_content("Invalid Velum certificate, check format and try again")
    end

    it "uploads malformed velum key" do
      attach_file("external_certificate_velum_cert", crt_v_a)
      attach_file("external_certificate_velum_key", key_malformed)

      click_button("Save")
      expect(page).to have_http_status(:unprocessable_entity)
      expect(page).to have_content("Invalid Velum key, check format and try again.")
    end

    it "uploads malformed kubeAPI certificate" do
      attach_file("external_certificate_kubeapi_cert", crt_malformed)
      attach_file("external_certificate_kubeapi_key", key_k_a)

      click_button("Save")
      expect(page).to have_http_status(:unprocessable_entity)
      expect(page).to have_content("Invalid Kubernetes API certificate, check format " \
        "and try again")
    end

    it "uploads malformed kubeAPI key" do
      attach_file("external_certificate_kubeapi_cert", crt_k_a)
      attach_file("external_certificate_kubeapi_key", key_malformed)

      click_button("Save")
      expect(page).to have_http_status(:unprocessable_entity)
      expect(page).to have_content("Invalid Kubernetes API key, check format and try " \
        "again.")
    end

    it "uploads malformed dex certificate" do
      attach_file("external_certificate_dex_cert", crt_malformed)
      attach_file("external_certificate_dex_key", key_d_a)

      click_button("Save")
      expect(page).to have_http_status(:unprocessable_entity)
      expect(page).to have_content("Invalid Dex certificate, check format and try again")
    end

    it "uploads malformed dex key" do
      attach_file("external_certificate_dex_cert", crt_d_a)
      attach_file("external_certificate_dex_key", key_malformed)

      click_button("Save")
      expect(page).to have_http_status(:unprocessable_entity)
      expect(page).to have_content("Invalid Dex key, check format and try again.")
    end

    it "uploads only velum certificate" do
      attach_file("external_certificate_velum_cert", crt_v_a)

      click_button("Save")
      expect(page).to have_http_status(:unprocessable_entity)
      expect(page).to have_content("Error with Velum, certificate and key must be uploaded " \
        "together.")
    end

    it "uploads only velum key" do
      attach_file("external_certificate_velum_key", key_v_a)

      click_button("Save")
      expect(page).to have_http_status(:unprocessable_entity)
      expect(page).to have_content("Error with Velum, certificate and key must be uploaded " \
        "together.")
    end

    it "uploads only velum, kubeAPI, and dex certificates" do
      attach_file("external_certificate_velum_cert", crt_v_a)
      attach_file("external_certificate_kubeapi_cert", crt_k_a)
      attach_file("external_certificate_dex_cert", crt_d_a)

      click_button("Save")
      expect(page).to have_http_status(:unprocessable_entity)
      expect(page).to have_content("Error with Velum, certificate and key must be uploaded " \
        "together.")
    end

    it "uploads only velum, kubeAPI, and dex keys" do
      attach_file("external_certificate_velum_key", key_v_a)
      attach_file("external_certificate_kubeapi_key", key_k_a)
      attach_file("external_certificate_dex_key", key_d_a)

      click_button("Save")
      expect(page).to have_http_status(:unprocessable_entity)
      expect(page).to have_content("Error with Velum, certificate and key must be uploaded " \
        "together.")
    end

    it "uploads mismatched velum cert/key 1" do
      attach_file("external_certificate_velum_cert", crt_v_a)
      attach_file("external_certificate_velum_key", key_v_b)

      click_button("Save")
      expect(page).to have_http_status(:unprocessable_entity)
      expect(page).to have_content("Certificate/Key pair invalid.  Ensure Certificate and Key " \
        "are matching.")
    end

    it "uploads mismatched velum cert/key 2" do
      attach_file("external_certificate_velum_cert", crt_v_b)
      attach_file("external_certificate_velum_key", key_v_a)

      click_button("Save")
      expect(page).to have_http_status(:unprocessable_entity)
      expect(page).to have_content("Certificate/Key pair invalid.  Ensure Certificate and Key " \
        "are matching.")
    end

    it "uploads mismatched velum, kubeAPI, and dex cert/key" do
      attach_file("external_certificate_velum_cert", crt_v_a)
      attach_file("external_certificate_velum_key", key_v_b)
      attach_file("external_certificate_kubeapi_cert", crt_k_a)
      attach_file("external_certificate_kubeapi_key", key_k_b)
      attach_file("external_certificate_dex_cert", crt_d_a)
      attach_file("external_certificate_dex_key", key_d_b)

      click_button("Save")
      expect(page).to have_http_status(:unprocessable_entity)
      expect(page).to have_content("Certificate/Key pair invalid.  Ensure Certificate and Key " \
        "are matching.")
    end

    it "uploads velum cert with invalid date range" do
      attach_file("external_certificate_velum_cert", crt_v_expired)
      attach_file("external_certificate_velum_key", key_v_expired)

      click_button("Save")
      expect(page).to have_http_status(:unprocessable_entity)
      expect(page).to have_content("Certificate out of valid date range")
    end
  end
end
# rubocop:enable RSpec/ExampleLength
