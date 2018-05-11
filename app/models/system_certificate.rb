# System certificates represents CA certificates that should be
# installed in a system-wide used location: e.g. /etc/pki/trust/anchors
class SystemCertificate < ActiveRecord::Base
  has_one :certificate_service, as: :service, dependent: :destroy
  has_one :certificate, through: :certificate_service

  validates :name, presence: true, uniqueness: true

  class << self
    # Create a new SystemCertificate from parameters
    #
    # @param system_certificate_params [ActionController::Parameters]
    # @return [String] A list of errors while attempting to create the
    #                  certificate and related objects
    def create_system_certificate(system_certificate_params)
      return [] if system_certificate_params.blank?
      cert_name = system_certificate_params[:name]
      cert = system_certificate_params[:certificate]
      ActiveRecord::Base.transaction do
        system_certificate = SystemCertificate.find_or_initialize_by(name: cert_name)
        system_certificate.save! if system_certificate.new_record?
        certificate = Certificate.find_or_initialize_by(certificate: cert)
        certificate.save! if certificate.new_record?
        service = CertificateService.find_or_initialize_by(service:     system_certificate,
                                                           certificate: certificate)
        service.save! if service.new_record?
        []
      end
    rescue ActiveRecord::RecordInvalid
      ["A certificate needs a valid name."]
    end
  end
end
