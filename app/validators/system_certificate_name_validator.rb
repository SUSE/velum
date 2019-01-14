require "openssl"

# Verifies that the name of a system certificate can not contain any
# components that could be relative paths on the file system.
class SystemCertificateNameValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    suspicious_path = /[\.\/]/ =~ value
    return true if suspicious_path.nil?
    record.errors[attribute] << "Invalid certificate name." \
                                "Do not include '.' or '/' in the name."
  end
end
