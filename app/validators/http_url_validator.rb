# Validate that a URL is a legal http/https format URL
class HttpUrlValidator < ActiveModel::EachValidator
  def self.compliant?(value)
    # Ruby URI complains if any underscores are in the FQDN
    # value = value.gsub('_','')
    uri = URI.parse(value)
    # https inherits from http, so both "is a" http
    uri.is_a?(URI::HTTP) && !uri.host.nil?
  rescue URI::InvalidURIError
    false
  end

  def validate_each(record, attribute, value)
    return true if value.present? && self.class.compliant?(value)
    record.errors.add(attribute, "is not a valid HTTP URL")
    false
  end
end
