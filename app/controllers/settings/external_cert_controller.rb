require "openssl"
require "velum/salt"
require "net/http"

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
      external_cert_velum_cert: key_cert_map_temp[VELUM_HASH_KEY][:cert][:cert_string],
      external_cert_velum_key: key_cert_map_temp[VELUM_HASH_KEY][:key][:key_string],
      external_cert_kubeapi_cert: key_cert_map_temp[KUBEAPI_HASH_KEY][:cert][:cert_string],
      external_cert_kubeapi_key: key_cert_map_temp[KUBEAPI_HASH_KEY][:key][:key_string],
      external_cert_dex_cert: key_cert_map_temp[DEX_HASH_KEY][:cert][:cert_string],
      external_cert_dex_key: key_cert_map_temp[DEX_HASH_KEY][:key][:key_string],
    }

    logger.silence do
      # Silences logging of cert/key insertion into DB
      @errors = Pillar.apply cert_map
    end

    if @errors.empty?
      flash[:alert] = warning_messages.join(" && ") if warning_messages.count > 0
      redirect_to settings_external_cert_index_path, notice: "External Certificate settings successfully saved."
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
      VELUM_HASH_KEY => {
        name: VELUM_NAME,
        cert: {
          cert_string: get_val_from_form(:velum_cert),
          pillar_model_key: :external_cert_velum_cert,
        },
        key: {
          key_string: get_val_from_form(:velum_key),
          pillar_model_key: :external_cert_velum_key,
        },
      },
      KUBEAPI_HASH_KEY => {
        name: KUBEAPI_NAME,
        cert: {
          cert_string: get_val_from_form(:kubeapi_cert),
          pillar_model_key: :external_cert_kubeapi_cert,
        },
        key: {
          key_string: get_val_from_form(:kubeapi_key),
          pillar_model_key: :external_cert_kubeapi_key,
        },
      },
      DEX_HASH_KEY => {
        name: DEX_NAME,
        cert: {
          cert_string: get_val_from_form(:dex_cert),
          pillar_model_key: :external_cert_dex_cert,
        },
        key: {
          key_string: get_val_from_form(:dex_key),
          pillar_model_key: :external_cert_dex_key,
        },
      },
    }
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
  def upload_validate(key_cert_map_elem)
    # Do nothing if both cert/key are empty
    if key_cert_map_elem[:cert][:cert_string].empty? && key_cert_map_elem[:key][:key_string].empty?
      true # return true
      # Prevent upload unnless both cert/key are present
    elsif key_cert_map_elem[:cert][:cert_string].empty? || key_cert_map_elem[:key][:key_string].empty?
      message = "Error with #{key_cert_map_elem[:name]}, certificate and key must be uploaded together."
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
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize

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
    # subject_alt_name.value.gsub("DNS:", "").gsub("IP:", "").delete(",").split(" ")

    asn_san = OpenSSL::ASN1.decode(subject_alt_name)
    asn_san_sequence = OpenSSL::ASN1.decode(asn_san.value[1].value)

    address_array = []
    asn_san_sequence.each do |asn_data|
      temp_val = asn_data.value
      begin
        # If the address is an IP, it is represented as string-encoded byte array
        # here.  As far as ruby is concerned it is the same type and encoding as
        # DNS entries.  There is no convenient way to distinguish the difference
        # other than to parse with IPAddr.ntop and catch the exception for DNS.
        address_array << IPAddr.ntop(temp_val)
      rescue IPAddr::AddressFamilyError
        address_array << temp_val
      end
    end

    return address_array
  end

  # Check if a certificate has a vaild date
  def valid_cert_date?(cert)
    return true unless Time.now.utc > cert.not_after || Time.now.utc < cert.not_before
    message = "Certificate out of valid date range"
    render_failure_event(message)
  end

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

  # Checks the Certificate's SubjectAltName list against list of hostnames required by the cluster
  def warning_subjectaltname(cert, warning_messages, required_san_array, service_name)
    missing_cert_base_msg = "Warning: #{service_name} is missing the following hostnames in its certificate:  "
    cert_san_array = get_san_array(cert)
    missing_hostnames = []
    
    if !cert_san_array
      warning_messages.push( missing_cert_base_msg + required_san_array.join(" "))
    else
      required_san_array.each do |i|
        if !cert_san_array.include?(i)
          missing_hostnames << i
        end
      end
    end

    if missing_hostnames.length > 0
      warning_messages.push("Missing the following hostnames in the certificate: #{missing_hostnames.join(" ")}")
    end
  end

  # # Placeholder for trust chain validation
  # def trust_chain_verify(_cert)
  #   true
  # end

  def hosts_info
    minion_hash = {}
    minions = Velum::Salt.minions

    minions.each_key do |i|
      machine_id = minions[i]["machine_id"]
      node_name = minions[i]["nodename"]
      roles = minions[i]["roles"]
      # minion_hash[i.to_sym] = minions[i]["machine_id"]
      minion_hash[i.to_sym] = {machine_id: machine_id, node_name: node_name, roles: roles}
    end
    minion_hash
  end

  # def pillar_info(pillar)
  #   pillar_obj = Velum::Salt.call(
  #     action: "pillar.get",
  #     arg: pillar,
  #     targets: "admin",
  #     # targets:     "roles:(admin|kube-(master|minion))",
  #     # target_type: "grain_pcre"
  #   )
  #   if pillar_obj[0].kind_of? Net::HTTPSuccess
  #     return pillar_obj[1]["return"][0]["admin"]
  #   else
  #     return nil
  #   end
  # end

  def pillar_items
    pillar = Velum::Salt.call(
      action: "pillar.items",
      targets: "admin",
    )
    if pillar[0].kind_of? Net::HTTPSuccess
      return pillar[1]["return"][0]["admin"]
    else
      return nil
    end
  end

  # rubocop:disable Metrics/AbcSize
  def build_subject_alt_names
    begin
      host_info = hosts_info
    rescue NoMethodError
      error_hash = {:error => "Error retrieving node information, please refresh page to try again"}
      return {
               VELUM_HASH_KEY => error_hash,
               KUBEAPI_HASH_KEY => error_hash,
               DEX_HASH_KEY => error_hash,
             }
    end

    pillar = pillar_items

    # Generic required hostnames
    begin
      velum_san_array_base = [
        pillar["dashboard_external_fqdn"],
        pillar["dashboard"],
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
        pillar["api"]["server"]["extra_ips"],
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
        pillar["api"]["server"]["extra_ips"],
      ]
    rescue NoMethodError
      error_hash = {:error => "Error retrieving pillar information, please refresh page to try again"}
      return {
               VELUM_HASH_KEY => error_hash,
               KUBEAPI_HASH_KEY => error_hash,
               DEX_HASH_KEY => error_hash,
             }
    end

    # Add host-specific hostnames
    begin
      host_info.values.each do |i|
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
      error_hash = {:error => "Error retrieving node information, please refresh page to try again"}
      return {
               VELUM_HASH_KEY => error_hash,
               KUBEAPI_HASH_KEY => error_hash,
               DEX_HASH_KEY => error_hash,
             }
    end

    # Remove empty entries
    velum_san_array = velum_san_array_base.reject { |i| i.nil? || i.empty? }
    kubeapi_san_array = kubeapi_san_array_base.reject { |i| i.nil? || i.empty? }
    dex_san_array = dex_san_array_base.reject { |i| i.nil? || i.empty? }

    {VELUM_HASH_KEY => velum_san_array, KUBEAPI_HASH_KEY => kubeapi_san_array, DEX_HASH_KEY => dex_san_array}
  end

  # rubocop:enable Metrics/AbcSize

  # def gen_velum_hostnames
  #   velum_hosts = {}
  #   Pillar.value(pillar: :external_cert_velum_cert)
  # end
end
# rubocop:enable Metrics/ClassLength
