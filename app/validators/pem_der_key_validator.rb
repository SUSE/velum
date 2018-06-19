require "openssl"

# Verifies that an attribute is a valid PEM/DER encoded key
class PemDerKeyValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    OpenSSL::PKey.read(value) if value.present?
  rescue ArgumentError
    record.errors[attribute] << "is not a valid PEM/DER encoded key"
  end
end
