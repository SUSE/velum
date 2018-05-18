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
    system_certificate_params.except(:certificate)
  end

  private

  def certificate_param
    system_certificate_params[:certificate].strip if
      system_certificate_params[:certificate].present?
  end

  def system_certificate_params
    params.require(:system_certificate).permit(:name, :certificate)
  end
end
