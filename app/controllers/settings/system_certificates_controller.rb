# Settings::SystemCertificatesController is responsible to manage requests
# related to system wide certificates.
class Settings::SystemCertificatesController < Settings::BaseCertificateController
  def index
    @system_certificates = SystemCertificate.all
  end

  def new
    @certificate_holder = certificate_holder_type.new
    @cert = Certificate.new
  end

  def destroy
    @certificate_holder.destroy
    redirect_to settings_system_certificates_path,
                notice: "System certificate was successfully removed."
  end

  protected

  def certificate_holder_type
    SystemCertificate
  end

  def certificate_holder_params
    system_certificate_params
  end

  def certificate_holder_update_params
    system_certificate_params.except(:certificate, :current_cert)
  end

  private

  def system_certificate_params
    params.require(:system_certificate).permit(:name, :certificate, :current_cert)
  end
end
