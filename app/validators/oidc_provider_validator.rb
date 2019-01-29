# Validate that column contains a reachable OIDC Provider
class OidcProviderValidator < HttpUrlValidator
  def self.validate_issuer?(i)
    url = URI.parse(i)
    # collapse things like trailing slashes, etc in URL
    url.path = File.absolute_path(url.path)

    c = HTTPClient.new
    # disable TLS validation :/
    # TODO: enable specifying self-signed cert in upstream dex (or disabling cert validation)
    # TODO: enable checking system certificates in Velum container
    # do not enable cert validation until the above are done
    c.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
    # c.ssl_config.add_trust_ca cert_file "a.pem" # to use a specific cert
    unparsed_response = c.get_content "#{url}/.well-known/openid-configuration"
    response = JSON.parse(unparsed_response)

    iss = URI.parse(response["issuer"])
    unless iss == url
      raise OpenIDConnect::Discovery::DiscoveryFailed, "provider '#{url}' !=  issuer '#{iss}'"
    end
    true

    # TODO: also check supported methods?

    # Once we get CA certs working, this is perhaps better than the above:
    # This is also why all the errors raise DiscoveryFailed exceptions
    #
    # parsed_uri = URI.parse(value)
    # unless parsed_uri.is_a?(URI::HTTPS)
    #   # SWD will be replaced with Webfinger in OIDC gem eventually.
    #   # Setting both here should help future-proof things
    #   SWD.url_builder = URI::HTTP
    #   WebFinger.url_builder = URI::HTTP
    # end
    # response = OpenIDConnect::Discovery::Provider::Config.discover!(i)
    # response.validate(i)
  end

  def self.compliant?(value)
    return false unless super
    validate_issuer?(value)
  # SSl validation errors should be turned back on eventually
  rescue OpenSSL::SSL::SSLError => e
    raise OpenIDConnect::Discovery::DiscoveryFailed, e
  # pass through timeout and socket errors
  rescue SocketError => e
    raise e
  rescue TimeoutError => e
    raise e
  # any other error just gets converted to a discovery error w/ same content
  rescue StandardError => e
    raise OpenIDConnect::Discovery::DiscoveryFailed, e
  end

  def validate_each(record, attribute, value)
    return false unless super
    return true if value.present? && self.class.compliant?(value)
    # record.errors.add(attribute, "is not a valid OIDC provider")
    # false
  rescue OpenIDConnect::Discovery::DiscoveryFailed => e
    record.errors.add(attribute, "is not a valid OIDC provider: discovery failure (error: #{e})")
    false # any error with webfinger / issuer mismatch
  rescue SocketError
    record.errors.add(attribute, "is not a valid OIDC provider: bad/unresolvable hostname")
    false # hostname not resolvable
  rescue TimeoutError
    record.errors.add(attribute, "is not a valid OIDC provider: connection timeout")
    false # The System Is Down
  end
end
