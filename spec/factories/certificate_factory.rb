FactoryGirl.define do
  factory :certificate do
    rsa_key = OpenSSL::PKey::RSA.new(2048)
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.subject = OpenSSL::X509::Name.parse "/CN=hostname"
    cert.issuer = cert.subject
    cert.public_key = rsa_key.public_key
    cert.not_before = Time.now.utc
    cert.not_after = cert.not_before + 2 * 365 * 24 * 60 * 60 # 2 years validity
    cert.sign(rsa_key, OpenSSL::Digest::SHA1.new)
    certificate { cert.to_pem }
  end
end
