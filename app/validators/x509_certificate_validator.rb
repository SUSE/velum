require "openssl"

# Verifies that an attribute is a valid X509 certificate
class X509CertificateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    OpenSSL::X509::Certificate.new(value) if value.present?
  rescue OpenSSL::X509::CertificateError
    record.errors[attribute] << "Invalid X509 certificate."
  end
end
