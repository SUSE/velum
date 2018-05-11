# Settings::BaseCertificateController extract common methods for certificate
# handling in controllers.
# Subclasses are expected to overwrite the followingmethods:
# - certificate_holder: return the current object holding a reference
#                       to a certificate
# - certificate_holder_update_params: parameters that can be used to
#                                     update the certificate_holder model
class Settings::BaseCertificateController < SettingsController
  def edit
    @cert = certificate_holder.certificate || Certificate.new
  end

  def update
    @cert = certificate_holder.certificate || Certificate.new(certificate: certificate_param)

    ActiveRecord::Base.transaction do
      certificate_holder.update_attributes!(certificate_holder_update_params)

      if certificate_param.present?
        create_or_update_certificate!
      elsif certificate_holder.certificate.present?
        certificate_holder.certificate.destroy!
      end
    end

    redirect_to [:settings, certificate_holder],
                notice: "#{certificate_holder.class} was successfully updated."
  rescue ActiveRecord::RecordInvalid
    render action: :edit, status: :unprocessable_entity
  end

  protected

  def certificate_holder
    raise NotImplementedError,
          "#{self.class.name}#certificate_holder is an abstract method."
  end

  def certificate_holder_update_params
    raise NotImplementedError,
          "#{self.class.name}#certificate_holder_update_params is an abstract method."
  end

  def create_or_update_certificate!
    if @cert.new_record?
      @cert.save!
      CertificateService.create!(service: certificate_holder, certificate: @cert)
    else
      @cert.update_attributes!(certificate: certificate_param)
    end
  end
end
