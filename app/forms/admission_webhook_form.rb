require "openssl"

# AdmissionWebhookForm represents a form for AdmissionWebhookController
class AdmissionWebhookForm
  include ActiveModel::Model

  attr_accessor :enabled, :current_cert, :current_key, :key_file, :cert_file

  validates :key, presence: true, if: :current_key_file_blank?
  validates :key, pem_der_key: true
  validates :certificate, presence: true, if: :current_certificate_file_blank?
  validates :certificate, x509_certificate: true

  validate :cant_be_empty_file
  validate :check_cert_private_key

  def valid?(context = nil)
    return true if @enabled == "false"
    super
  end

  def certificate
    @certificate ||= @cert_file.try(:read)
  end

  def key
    @key ||= @key_file.try(:read)
  end

  private

  def cant_be_empty_file
    cert_file_empty = @cert_file.present? && certificate.blank?
    key_file_empty = @key_file.present? && key.blank?

    errors.add(:key, "can't be an empty file") if key_file_empty
    errors.add(:certificate, "can't be an empty file") if cert_file_empty
  end

  def check_cert_private_key
    begin
      x509 = OpenSSL::X509::Certificate.new(certificate)
      pkey = OpenSSL::PKey.read(key)
      valid = x509.check_private_key(pkey)
    rescue OpenSSL::X509::CertificateError, TypeError, ArgumentError
      # we are validating if the key matches with cert, not cert or key formats
      valid = true
    end

    errors.add(:key, "doesn't pair with the certificate") unless valid
  end

  def current_key_file_blank?
    @current_key.blank? && @key_file.blank?
  end

  def current_certificate_file_blank?
    @current_cert.blank? && @cert_file.blank?
  end
end
