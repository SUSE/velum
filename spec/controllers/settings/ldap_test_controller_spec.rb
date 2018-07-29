require "rails_helper"
require "json"
require "socket"
require "openssl"

RSpec.describe Settings::LdapTestController, type: :controller do
  let(:user) { create(:user) }

  before do
    setup_done
    sign_in user
  end

  describe "POST #create" do
    let(:host) { "ldaptest.com" }
    let(:port) { 636 }
    let(:start_tls) { "false" }
    let(:cert) do
      "MIIC0zCCAlmgAwIBAgIUCfQ+m0pgZ/BjYAJvxrn/bdGNZokwCgYIKoZIzj0EAwMw" \
      "gZYxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxBMUEgQ2FyIFdhc2gxJDAiBgNVBAsT" \
      "G0luZm9ybWF0aW9uIFRlY2hub2xvZ3kgRGVwLjEUMBIGA1UEBxMLQWxidXF1ZXJx" \
      "dWUxEzARBgNVBAgTCk5ldyBNZXhpY28xHzAdBgNVBAMTFmRvY2tlci1saWdodC1i" \
      "YXNlaW1hZ2UwHhcNMTUxMjIzMTM1MzAwWhcNMjAxMjIxMTM1MzAwWjCBljELMAkG" \
      "A1UEBhMCVVMxFTATBgNVBAoTDEExQSBDYXIgV2FzaDEkMCIGA1UECxMbSW5mb3Jt" \
      "YXRpb24gVGVjaG5vbG9neSBEZXAuMRQwEgYDVQQHEwtBbGJ1cXVlcnF1ZTETMBEG" \
      "A1UECBMKTmV3IE1leGljbzEfMB0GA1UEAxMWZG9ja2VyLWxpZ2h0LWJhc2VpbWFn" \
      "ZTB2MBAGByqGSM49AgEGBSuBBAAiA2IABMZf/12pupAgl8Sm+j8GmjNeNbSFAZWW" \
      "oTmIvf2Mu4LWPHy4bTldkQgHUbBpT3xWz8f0lB/ru7596CHsGoL2A28hxuclq5hb" \
      "Ux1yrIt3bJIY3TuiX25HGTe6kGCJPB1aLaNmMGQwDgYDVR0PAQH/BAQDAgEGMBIG" \
      "A1UdEwEB/wQIMAYBAf8CAQIwHQYDVR0OBBYEFE+l6XolXDAYnGLTl4W6ULKHrm74" \
      "MB8GA1UdIwQYMBaAFE+l6XolXDAYnGLTl4W6ULKHrm74MAoGCCqGSM49BAMDA2gA" \
      "MGUCMQCXLZj8okyxW6UTL7hribUUbu63PbjuwIXnwi420DdNsvA9A7fcQEXScWFL" \
      "XAGC8rkCMGcqwXZPSRfwuI9r+R11gTrP92hnaVxs9sjRikctpkQpOyNlIXFPopFK" \
      "8FdfWPypvA=="
    end
    let(:anon_bind) { "false" }
    let(:dn) { "cn=admin,dc=ldaptest,dc=com" }
    let(:pass) { "admin" }
    let(:base_dn) { "dc=ldaptest,dc=com" }
    let(:filter) { "(objectClass=person)" }
    let(:mock) { "true" }

    it "request has OK response status" do
      post :create, host: host, port: port, start_tls: start_tls, cert: cert,
      anon_bind: anon_bind, dn: dn, pass: pass, base_dn: base_dn, filter: filter, mock: mock
      expect(response).to have_http_status(:ok)
    end

    it "well-formed request passes" do
      post :create, host: host, port: port, start_tls: start_tls, cert: cert,
      anon_bind: anon_bind, dn: dn, pass: pass, base_dn: base_dn, filter: filter, mock: mock
      parse_json = JSON(response.body)
      expect(parse_json["result"]["test_pass"]).to eq(true)
    end

    it "failure with bad server address" do
      host = "example.com"
      post :create, host: host, port: port, start_tls: start_tls, cert: cert,
      anon_bind: anon_bind, dn: dn, pass: pass, base_dn: base_dn, filter: filter, mock: mock
      parse_json = JSON(response.body)
      expect(parse_json["result"]["test_pass"]).to eq(false)
    end

    it "failure with bad server port" do
      port = 12345
      post :create, host: host, port: port, start_tls: start_tls, cert: cert,
      anon_bind: anon_bind, dn: dn, pass: pass, base_dn: base_dn, filter: filter, mock: mock
      parse_json = JSON(response.body)
      expect(parse_json["result"]["test_pass"]).to eq(false)
    end

    # rubocop:disable RSpec/ExampleLength
    it "pass with StartTLS" do
      port = 389
      start_tls = "true"
      post :create, host: host, port: port, start_tls: start_tls, cert: cert,
      anon_bind: anon_bind, dn: dn, pass: pass, base_dn: base_dn, filter: filter, mock: mock
      parse_json = JSON(response.body)
      expect(parse_json["result"]["test_pass"]).to eq(true)
    end
    # rubocop:enable RSpec/ExampleLength

    it "failure with malformed certificate" do
      cert = "abcdefg"
      post :create, host: host, port: port, start_tls: start_tls, cert: cert,
      anon_bind: anon_bind, dn: dn, pass: pass, base_dn: base_dn, filter: filter, mock: mock
      parse_json = JSON(response.body)
      expect(parse_json["result"]["test_pass"]).to eq(false)
    end

    # rubocop:disable RSpec/ExampleLength
    it "pass with anonymous bind" do
      anon_bind = "true"
      dn = ""
      pass = ""
      post :create, host: host, port: port, start_tls: start_tls, cert: cert,
      anon_bind: anon_bind, dn: dn, pass: pass, base_dn: base_dn, filter: filter, mock: mock
      parse_json = JSON(response.body)
      expect(parse_json["result"]["test_pass"]).to eq(true)
    end
    # rubocop:enable RSpec/ExampleLength

    it "failure with bad DN" do
      dn = "cn=steve,dc=fakehost,dc=biz"
      post :create, host: host, port: port, start_tls: start_tls, cert: cert,
      anon_bind: anon_bind, dn: dn, pass: pass, base_dn: base_dn, filter: filter, mock: mock
      parse_json = JSON(response.body)
      expect(parse_json["result"]["test_pass"]).to eq(false)
    end

    it "failure with bad password" do
      pass = "fake_password"
      post :create, host: host, port: port, start_tls: start_tls, cert: cert,
      anon_bind: anon_bind, dn: dn, pass: pass, base_dn: base_dn, filter: filter, mock: mock
      parse_json = JSON(response.body)
      expect(parse_json["result"]["test_pass"]).to eq(false)
    end

    it "failure with bad baseDN" do
      base_dn = "dc=suse,dc=de"
      post :create, host: host, port: port, start_tls: start_tls, cert: cert,
      anon_bind: anon_bind, dn: dn, pass: pass, base_dn: base_dn, filter: filter, mock: mock
      parse_json = JSON(response.body)
      expect(parse_json["result"]["test_pass"]).to eq(false)
    end

    it "failure with incorrect filter" do
      filter = "(objectClass=cat)"
      post :create, host: host, port: port, start_tls: start_tls, cert: cert,
      anon_bind: anon_bind, dn: dn, pass: pass, base_dn: base_dn, filter: filter, mock: mock
      parse_json = JSON(response.body)
      expect(parse_json["result"]["test_pass"]).to eq(false)
    end

    it "failure with bad filter syntax" do
      filter = "(objectClass=person"
      post :create, host: host, port: port, start_tls: start_tls, cert: cert,
      anon_bind: anon_bind, dn: dn, pass: pass, base_dn: base_dn, filter: filter, mock: mock
      parse_json = JSON(response.body)
      expect(parse_json["result"]["test_pass"]).to eq(false)
    end
  end
end
