# Certificate store
class Certificate < ActiveRecord::Base
  has_many :certificate_services, dependent: :destroy

  validates :certificate, presence: true, x509_certificate: true

  class << self
    # Extracts the certificate text from form parameters. Expects the parameters
    # to either have a `certificate` or `certificate_file` field.
    #
    # @param [Hash] params The form parameters.
    # @option params [File] :certificate File containing a certificate
    # @option params [String] :current_cert Certificate as a string
    #
    # @return [String] Text of the certificate
    def get_certificate_text(params)
      if params[:certificate].present?
        params[:certificate].read.strip
      elsif params[:current_cert].present?
        params[:current_cert].strip
      end
    end
  end
end
