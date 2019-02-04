require "openssl"
require "velum/salt"
require "resolv"

# Settings::ExternalCertController allows users to install their own SSL Certificates
# and Private Keys for encrypted external communication
# rubocop:disable Metrics/ClassLength
class Settings::ExternalCertController < SettingsController
  VELUM_HASH_KEY = :velum
  KUBEAPI_HASH_KEY = :kubeapi
  DEX_HASH_KEY = :dex
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
      external_cert_velum_cert:   key_cert_map_temp[VELUM_HASH_KEY][:cert][:cert_string],
      external_cert_velum_key:    key_cert_map_temp[VELUM_HASH_KEY][:key][:key_string],
      external_cert_kubeapi_cert: key_cert_map_temp[KUBEAPI_HASH_KEY][:cert][:cert_string],
      external_cert_kubeapi_key:  key_cert_map_temp[KUBEAPI_HASH_KEY][:key][:key_string],
      external_cert_dex_cert:     key_cert_map_temp[DEX_HASH_KEY][:cert][:cert_string],
      external_cert_dex_key:      key_cert_map_temp[DEX_HASH_KEY][:key][:key_string]
    }

    logger.silence do
      # Silences logging of cert/key insertion into the database
      @errors = Pillar.apply cert_map
    end

    if @errors.empty?
      flash[:alert] = warning_messages.join(" && ") if warning_messages.count > 0
      redirect_to settings_external_cert_index_path, notice: "External Certificate " \
      "settings successfully saved."
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

    @subject_alt_names = build_subject_alt_names
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
      VELUM_HASH_KEY   => {
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
      KUBEAPI_HASH_KEY => {
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
      DEX_HASH_KEY     => {
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

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
  # Validates certificate and key prior to uploading
  def upload_validate(key_cert_map_elem)
    # Do nothing if both cert/key are empty
    if key_cert_map_elem[:cert][:cert_string].empty? && key_cert_map_elem[:key][:key_string].empty?
      true # return true
    # Prevent upload unless both cert/key are present
    elsif key_cert_map_elem[:cert][:cert_string].empty? ||
        key_cert_map_elem[:key][:key_string].empty?
      message = "Error with #{key_cert_map_elem[:name]}, certificate and key must be " \
      "uploaded together."
      render_failure_event(message)
    # Validate cert/key and verify that they match
    else
      cert = read_cert(key_cert_map_elem[:cert][:cert_string])
      key = read_key(key_cert_map_elem[:key][:key_string])

      # Check certificate valid format
      unless cert
        message = "Invalid #{key_cert_map_elem[:name]} certificate, check format and try again."
        return render_failure_event(message)
      end

      # Check key valid format
      unless key
        message = "Invalid #{key_cert_map_elem[:name]} key, check format and try again."
        return render_failure_event(message)
      end

      # Check that key matches certificate
      unless cert.check_private_key(key)
        message = "#{key_cert_map_elem[:name]} Certificate/Key pair invalid.  Ensure Certificate" \
        " and Key are matching."
        return render_failure_event(message)
      end

      # Check if a certificate has a vaild date
      return false unless valid_cert_date?(cert)

      trust_error = trust_chain_verify(cert)
      unless trust_error.nil?
        message = "Certificate verification failed: " + trust_error
        return render_failure_event(message)
      end

      # Everything's good!
      true
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize

  # Checks for warning conditions prior to uploading
  def get_warning_message(key_cert_map)
    warning_messages = []
    subjectaltname_hash = build_subject_alt_names
    key_cert_map.each_key do |i|
      next if key_cert_map[i][:cert][:cert_string].empty?
      cert = read_cert(key_cert_map[i][:cert][:cert_string])
      warning_rsa_keylength(cert, warning_messages)
      warning_weak_hash(cert, warning_messages)
      warning_subjectaltname(cert, warning_messages, subjectaltname_hash[i], key_cert_map[i][:name])
    end
    warning_messages.uniq
  end

  # Parses certificate to display details
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
      san_hash = get_san_hash(cert)
      altnames = san_hash[:altnames] || []
      ip_altnames = san_hash[:ip_altnames] || []

      params["Subject Alternative Name".to_sym] = altnames + ip_altnames
      params["Subject Name".to_sym] = cert.subject.to_s.tr("/", " ")
      params["Issuer Name".to_sym] = cert.issuer.to_s.tr("/", " ")
      params["Signature Algorithm".to_sym] = cert.signature_algorithm
      params["Not Valid Before".to_sym] = cert.not_before
      params["Not Valid After".to_sym] = cert.not_after
      params[fingerprint[0]] = fingerprint[1]
    end
    params
  end

  # Calculates SHA256 signature of certificate
  def cert_fingerprint(cert)
    # Error-checking ignored, cert already validated and verified
    fingerprint = OpenSSL::Digest::SHA256.new(cert.to_der)
    # This adds colons every 2 characters which is typical fingerprint display
    fingerprint_string = fingerprint.to_s.scan(/../).join(":").upcase
    ["SHA256 Fingerprint".to_sym, fingerprint_string]
  end

  # Check validity of private key
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
        true # returns true
      else
        false # returns false
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

  # Get SubjectAltName field of a certificate
  def get_san_hash(cert)
    subject_alt_name = cert.extensions.find { |e| e.oid == "subjectAltName" }
    return { error: 1 } unless subject_alt_name

    asn_san = OpenSSL::ASN1.decode(subject_alt_name)
    asn_san_sequence = OpenSSL::ASN1.decode(asn_san.value[1].value)

    # Ruby OpenSSL library does not unfortunately have constants for the DNS
    # altnames versus IP based altnames
    # See verify_certificate_identity in
    # https://github.com/ruby/openssl/blob/master/lib/openssl/ssl.rb

    # There are actually 9 types, as defined by RFC5280 :
    # ( https://tools.ietf.org/html/rfc5280#section-4.2.1.6 )
    # DNS string hostnames are type 2 ( dNSName )
    # Both ipv4 and ipv6 addresses are type 7 ( iPAddress )
    # Email addresses are stored as type 1 ( rfc822Name )

    altnames = []
    ip_altnames = []
    asn_san_sequence.each do |altname|
      val = altname.value
      case altname.tag
      when 2
        altnames << val
      when 7
        # Pushes IP address string in canonical format
        ip_altnames << IPAddr.new(IPAddr.ntop(val)).to_string
      end
    end

    { error: 0, altnames: altnames, ip_altnames: ip_altnames }
  end

  # Check if a certificate has a vaild date
  def valid_cert_date?(cert)
    return true unless Time.now.utc > cert.not_after || Time.now.utc < cert.not_before
    message = "Certificate out of valid date range"
    render_failure_event(message)
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

  # rubocop:disable Metrics/CyclomaticComplexity
  # Checks the Certificate's SubjectAltName list against list of hostnames required by the cluster
  def warning_subjectaltname(cert, warning_messages, required_san_array, service_name)
    cent_san_hash = get_san_hash(cert)
    altnames = cent_san_hash[:altnames] || []
    ip_altnames = cent_san_hash[:ip_altnames] || []
    cert_san_array = altnames + ip_altnames
    missing_hostnames = []

    # Convert all IP addresses to canonical form
    required_san_array.each do |i|
      temp_san = case i
                 when Resolv::IPv4::Regex
                   IPAddr.new(i).to_string
                 when Resolv::IPv6::Regex
                   IPAddr.new(i).to_string
                 else
                   i
      end
      missing_hostnames << i unless cert_san_array.include?(temp_san)
    end

    return if missing_hostnames.empty?
    warning_messages.push("Warning, #{service_name} is missing the following hostnames in its " \
      "certificate: #{missing_hostnames.join(" ")}")
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def trust_chain_verify(cert)
    _trust_chain_verify(cert, _build_system_wide_certs_store)
  end

  def _build_system_wide_certs_store
    cert_store = OpenSSL::X509::Store.new

    system_certs = SystemCertificate.all
    system_certs.each do |system_cert|
      cert = system_cert.certificate
      cert_text = cert.certificate
      cert_obj = read_cert(cert_text)
      # Certs must pass parsing to get into the SystemCertificate table; so we ignore failing parse
      next unless cert_obj
      cert_store.add_cert(cert_obj)
    end

    cert_store
  end

  # rubocop:disable Lint/RescueException
  def _trust_chain_verify(cert_obj, cert_store)
    verify_error = ""

    # setup callback
    cert_store.verify_callback = proc do |preverify_ok, ssl_context|
      begin
        if preverify_ok != true || ssl_context.error != 0
          cert_being_checked = ssl_context.chain[ssl_context.error_depth]
          failed_cert_subject = cert_being_checked.subject
          err_msg = "SSL Verification failed: #{ssl_context.error_string}"\
                    " (#{ssl_context.error}) while verifying #{failed_cert_subject}"
          verify_error += err_msg
          false
        else
          true
        end
      rescue Exception
        verify_error += err_msg
        false
      end
    end

    if cert_store.verify(cert_obj)
      nil
    else
      verify_error
    end
  end
  # rubocop:enable Lint/RescueException

  # Returns host info via Salt Grains
  def hosts_info
    minion_hash = {}
    minions = if ENV["RAILS_ENV"] != "test"
      # :nocov:
      # Production condition, corresponding test condition below
      Velum::Salt.minions
      # :nocov:
    else
      YAML.load_file(::Rails.root.join("config", "ext_cert_minion.yaml"))
    end

    minions.each_key do |i|
      machine_id = minions[i]["machine_id"]
      node_name = minions[i]["nodename"]
      roles = minions[i]["roles"]
      minion_hash[i.to_sym] = { machine_id: machine_id, node_name: node_name, roles: roles }
    end
    minion_hash
  end

  # Returns Salt Pillar for admin node
  def pillar_items
    if ENV["RAILS_ENV"] != "test"
      # :nocov:
      # Production condition, corresponding test condition below
      pillar = Velum::Salt.call(
        action:  "pillar.items",
        targets: "admin"
      )
      return nil unless pillar[0].is_a? Net::HTTPSuccess
      pillar[1]["return"][0]["admin"]
      # :nocov:
    else
      YAML.load_file(::Rails.root.join("config", "ext_cert_pillar.yaml"))
    end
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  # Returns a hash of required SubjectAltNames covering all three services
  def build_subject_alt_names
    begin
      host_info = hosts_info
    rescue NoMethodError
      # :nocov:
      # Protects for failure of HTTP call to Salt
      error_hash = { error: "Error retrieving node information, please refresh page to try again" }
      return {
        VELUM_HASH_KEY   => error_hash,
        KUBEAPI_HASH_KEY => error_hash,
        DEX_HASH_KEY     => error_hash
      }
      # :nocov:
    end

    pillar = pillar_items

    # Generic required hostnames
    begin
      velum_san_array_base = [
        pillar["dashboard_external_fqdn"],
        pillar["dashboard"]
      ]

      kubeapi_san_array_base = [
        "kubernetes",
        "kubernetes.default",
        "kubernetes.default.svc",
        "kubernetes.default.svc.cluster.local",
        "api",
        "api" + "." + pillar["internal_infra_domain"],
        pillar["api"]["server"]["external_fqdn"],
        pillar["api"]["cluster_ip"],
        pillar["api"]["server"]["extra_names"],
        pillar["api"]["server"]["extra_ips"]
      ]

      dex_san_array_base = [
        "dex",
        "dex.kube-system",
        "dex.kube-system.svc",
        "dex.kube-system.svc" + "." + pillar["internal_infra_domain"],
        "dex.kube-system.svc" + "." + pillar["dns"]["domain"],
        "kubernetes",
        "kubernetes.default",
        "kubernetes.default.svc",
        "api",
        "api" + "." + pillar["internal_infra_domain"],
        pillar["api"]["server"]["external_fqdn"],
        pillar["api"]["cluster_ip"],
        pillar["api"]["server"]["extra_names"],
        pillar["api"]["server"]["extra_ips"]
      ]
    rescue NoMethodError
      # :nocov:
      # Protects for failure of HTTP call to Salt
      error_hash = {
        error: "Error retrieving pillar information, please refresh page to try again"
      }
      return {
        VELUM_HASH_KEY   => error_hash,
        KUBEAPI_HASH_KEY => error_hash,
        DEX_HASH_KEY     => error_hash
      }
      # :nocov:
    end

    # Add host-specific hostnames
    begin
      host_info.each_value do |i|
        if i[:roles].include? "admin"
          velum_san_array_base << i[:node_name]
          velum_san_array_base << i[:node_name] + "." + pillar["internal_infra_domain"]
          velum_san_array_base << i[:machine_id]
          velum_san_array_base << i[:machine_id] + "." + pillar["internal_infra_domain"]
        elsif i[:roles].include? "kube-master"
          node_name = i[:node_name]
          machine_id = i[:machine_id]

          kubeapi_san_array_base << node_name
          kubeapi_san_array_base << node_name + "." + pillar["internal_infra_domain"]
          kubeapi_san_array_base << machine_id
          kubeapi_san_array_base << machine_id + "." + pillar["internal_infra_domain"]
          dex_san_array_base << node_name
          dex_san_array_base << node_name + "." + pillar["internal_infra_domain"]
          dex_san_array_base << machine_id
          dex_san_array_base << machine_id + "." + pillar["internal_infra_domain"]
        end
      end
    rescue TypeError
      # :nocov:
      # Protects for failure due to incomplete results from Salt request
      error_hash = { error: "Error retrieving node information, please refresh page to try again" }
      return {
        VELUM_HASH_KEY   => error_hash,
        KUBEAPI_HASH_KEY => error_hash,
        DEX_HASH_KEY     => error_hash
      }
      # :nocov:
    end

    # Remove empty entries
    velum_san_array = velum_san_array_base.reject(&:blank?)
    kubeapi_san_array = kubeapi_san_array_base.reject(&:blank?)
    dex_san_array = dex_san_array_base.reject(&:blank?)

    {
      VELUM_HASH_KEY   => velum_san_array,
      KUBEAPI_HASH_KEY => kubeapi_san_array,
      DEX_HASH_KEY     => dex_san_array
    }
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end
# rubocop:enable Metrics/ClassLength
