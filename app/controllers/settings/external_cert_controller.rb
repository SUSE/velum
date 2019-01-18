require "openssl"

# Settings::ExternalCertController allows users to install their own SSL Certificates
# and Private Keys for encrypted external communication
# rubocop:disable Metrics/ClassLength
class Settings::ExternalCertController < SettingsController
  VELUM_NAME = "Velum".freeze
  KUBEAPI_NAME = "Kubernetes API".freeze
  DEX_NAME = "Dex".freeze
  WEAK_SIGNATURE_HASHES = ["sha1", "md5"].freeze

  def index
    set_instance_variables
  end

  # rubocop:disable Metrics/AbcSize
  def create
    key_cert_map_temp = key_cert_map
    key_cert_map_temp.each_key do |i|
      return false unless upload_validate(key_cert_map_temp[i])
    end
    warning_messages = get_warning_message(key_cert_map_temp)
    cert_map = {
      external_cert_velum_cert:   key_cert_map_temp[:velum][:cert][:cert_string],
      external_cert_velum_key:    key_cert_map_temp[:velum][:key][:key_string],
      external_cert_kubeapi_cert: key_cert_map_temp[:kubeapi][:cert][:cert_string],
      external_cert_kubeapi_key:  key_cert_map_temp[:kubeapi][:key][:key_string],
      external_cert_dex_cert:     key_cert_map_temp[:dex][:cert][:cert_string],
      external_cert_dex_key:      key_cert_map_temp[:dex][:key][:key_string]
    }
    @errors = Pillar.apply cert_map
    if @errors.empty?
      flash[:alert] = warning_messages.join(" && ") if warning_messages.count > 0
      redirect_to settings_external_cert_index_path, \
                           notice: "External Certificate settings successfully saved."
      return
    # :nocov:
    # An error here would require a failure in connection to velum->salt
    # or a corruption in mapping of values in the salt pillar
    else
      set_instance_variables
      render action: :index, status: :unprocessable_entity
      # :nocov:
    end
  end
  # rubocop:enable Metrics/AbcSize

  private

  def set_instance_variables
    @velum_cert = cert_parse(Pillar.value(pillar: :external_cert_velum_cert))
    @velum_key = key_parse(Pillar.value(pillar: :external_cert_velum_key))
    @kubeapi_cert = cert_parse(Pillar.value(pillar: :external_cert_kubeapi_cert))
    @kubeapi_key = key_parse(Pillar.value(pillar: :external_cert_kubeapi_key))
    @dex_cert = cert_parse(Pillar.value(pillar: :external_cert_dex_cert))
    @dex_key = key_parse(Pillar.value(pillar: :external_cert_dex_key))
  end

  def get_val_from_form(param)
    if params.key?(:external_certificate) && params[:external_certificate].key?(param)
      params[:external_certificate][param].read
    else
      ""
    end
  end

  def key_cert_map
    {
      velum:   {
        name: VELUM_NAME,
        cert: {
          cert_string:      get_val_from_form(:velum_cert),
          pillar_model_key: :external_cert_velum_cert
        },
        key:  {
          key_string:       get_val_from_form(:velum_key),
          pillar_model_key: :external_cert_velum_key
        }
      },
      kubeapi: {
        name: KUBEAPI_NAME,
        cert: {
          cert_string:      get_val_from_form(:kubeapi_cert),
          pillar_model_key: :external_cert_kubeapi_cert
        },
        key:  {
          key_string:       get_val_from_form(:kubeapi_key),
          pillar_model_key: :external_cert_kubeapi_key
        }
      },
      dex:     {
        name: DEX_NAME,
        cert: {
          cert_string:      get_val_from_form(:dex_cert),
          pillar_model_key: :external_cert_dex_cert
        },
        key:  {
          key_string:       get_val_from_form(:dex_key),
          pillar_model_key: :external_cert_dex_key
        }
      }
    }
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def upload_validate(key_cert_map)
    # Do nothing if both cert/key are empty
    if key_cert_map[:cert][:cert_string].empty? && key_cert_map[:key][:key_string].empty?
      true # return true
    # Prevent upload unnless both cert/key are present
    elsif key_cert_map[:cert][:cert_string].empty? || key_cert_map[:key][:key_string].empty?
      message = "Error with #{key_cert_map[:name]}, certificate and key must be uploaded together."
      render_failure_event(message)
    # Validate cert/key and verify that they match
    else
      cert = read_cert(key_cert_map[:cert][:cert_string])
      key = read_key(key_cert_map[:key][:key_string])

      # Check certificate valid format
      unless cert
        message = "Invalid #{key_cert_map[:name]} certificate, check format and try again."
        return render_failure_event(message)
      end

      # Check key valid format
      unless key
        message = "Invalid #{key_cert_map[:name]} key, check format and try again."
        return render_failure_event(message)
      end

      # Check that key matches certificate
      unless cert.check_private_key(key)
        message = "#{key_cert_map[:name]} Certificate/Key pair invalid.  Ensure Certificate" \
        " and Key are matching."
        return render_failure_event(message)
      end

      # Check if a certificate has a vaild date
      return false unless valid_cert_date?(cert)

      # Moved to another task
      # Check that hostname is in SubjectAltName of cert
      # return false unless hostname_check(key_cert_map[:name], cert)

      # Moved to another task
      # Check the trust chain is valid
      # return false unless trust_chain_verify(cert)

      # Everything's good!
      true
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def cert_parse(cert_string)
    params = {}

    # Check if certificate exists, assume that validation has already occured
    if !cert_string
      params[:Message] = { Notice: "Certificate not available, please upload a certificate" }
    else
      cert = read_cert(cert_string)
      unless cert
        # :nocov:
        # Cert has aleady been valiated when entered, an error here would require a failure
        # in connection from velum to salt or an unintended change in the salt pillar
        params[:Message] = { Error: "Failed to parse stored certificate, please check format and " \
        "upload again" }
        return params
        # :nocov:
      end
      fingerprint = cert_fingerprint(cert)

      params["Subject Alternative Name".to_sym] = get_san_array(cert)
      params["Subject Name".to_sym] = cert.subject.to_s.tr("/", " ")
      params["Issuer Name".to_sym] = cert.issuer.to_s.tr("/", " ")
      params["Signature Algorithm".to_sym] = cert.signature_algorithm
      params["Not Valid Before".to_sym] = cert.not_before
      params["Not Valid After".to_sym] = cert.not_after
      params[fingerprint[0]] = fingerprint[1]
    end
    params
  end

  def cert_fingerprint(cert)
    # Error-checking ignored, cert already validated and verified
    fingerprint = OpenSSL::Digest::SHA256.new(cert.to_der)
    # This adds colons every 2 characters which is typical fingerprint display
    fingerprint_string = fingerprint.to_s.scan(/../).join(":").upcase
    ["SHA256 Fingerprint".to_sym, fingerprint_string]
  end

  def key_parse(key_string)
    params = {}
    if !key_string
      params[:Message] = { Notice: "Key not available, please upload a key" }
    # :nocov:
    # Key has aleady been valiated when entered, an error here would require a failure
    # in connection from velum to salt or an unintended change in the salt pillar
    else
      key = read_key(key_string)
      unless key
        params[:Message] = { Error: "Failed to parse stored key, please check format and " \
        "upload again" }
        return params
      end
      key_valid = if key
        true # return true
      else
        false # return false
      end
      params["Valid Key"] = key_valid
      # :nocov:
    end
    params
  end

  # Common method to build cert object from string
  def read_cert(cert_string)
    return OpenSSL::X509::Certificate.new(cert_string)
  rescue OpenSSL::X509::CertificateError, NoMethodError, TypeError
    # Push error handling to calling method for flexibility
    return nil
  end

  # Common method to build key object from string
  def read_key(key_string)
    return OpenSSL::PKey::RSA.new(key_string)
  rescue OpenSSL::PKey::RSAError, NoMethodError, TypeError
    # Push error handling to calling method for flexibility
    return nil
  end

  # Common method to simplify failure renders
  def render_failure_event(message)
    set_instance_variables
    flash[:alert] = message
    render action: :index, status: :unprocessable_entity
    false
  end

  # Get SubjectAltName field buried in a certificate
  def get_san_array(cert)
    subject_alt_name = cert.extensions.find { |e| e.oid == "subjectAltName" }
    return nil unless subject_alt_name
    subject_alt_name.value.gsub("DNS:", "").delete(",").split(" ")
  end

  # Check if a certificate has a vaild date
  def valid_cert_date?(cert)
    return true unless Time.now.utc > cert.not_after || Time.now.utc < cert.not_before
    message = "Certificate out of valid date range"
    render_failure_event(message)
  end

  def get_warning_message(key_cert_map)
    warning_messages = []
    key_cert_map.each_key do |i|
      next if key_cert_map[i][:cert][:cert_string].empty?
      cert = read_cert(key_cert_map[i][:cert][:cert_string])
      warning_rsa_keylength(cert, warning_messages)
      warning_weak_hash(cert, warning_messages)
    end
    warning_messages.uniq
  end

  # Warn if a certificate uses the key length that is less than 2048 bits
  def warning_rsa_keylength(cert, warning_messages)
    key_length_in_bits = cert.public_key.n.num_bytes * 8
    return unless key_length_in_bits < 2048
    warning_messages.push("Warning: RSA key bit length should be greater than or equal to 2048")
  end

  # Warn if a certificate uses a weak hash algorithm
  def warning_weak_hash(cert, warning_messages)
    hash_algorithm = cert.signature_algorithm.chomp "WithRSAEncryption"
    return unless WEAK_SIGNATURE_HASHES.include? hash_algorithm
    warning_messages.push("Warning: Certificate includes a weak signature hash algorithm
                      (#{WEAK_SIGNATURE_HASHES.join(", ")})")
  end

  # # Placeholder for hostname/SubjectAltName check
  # def hostname_check(_cert)
  #   true
  # end

  # # Placeholder for trust chain validation
  # def trust_chain_verify(_cert)
  #   true
  # end
end
# rubocop:enable Metrics/ClassLength
