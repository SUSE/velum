# Settings::SystemCertificatesController is responsible to manage requests
# related to system wide certificates.
class Settings::SystemCertificatesController < SettingsController
  before_action :set_system_certificate, except: [:index, :new, :create]

  def index
    @system_certificates = SystemCertificate.all
  end

  def new
    @system_certificate = SystemCertificate.new
    @cert = Certificate.new
  end

  def create
    @system_certificate = SystemCertificate.new(system_certificate_params.except(:certificate))
    @cert = Certificate.find_or_initialize_by(certificate: certificate_param)

    ActiveRecord::Base.transaction do
      @system_certificate.save!
      create_or_update_certificate! if certificate_param.present?
    end

    redirect_to [:settings, @system_certificate],
                notice: "System certificate successfully created."
  rescue ActiveRecord::RecordInvalid
    render action: :new, status: :unprocessable_entity
  end

  def edit
    @cert = @system_certificate.certificate || Certificate.new
  end

  def destroy
    @system_certificate.destroy
    redirect_to settings_system_certificates_path,
                notice: "System certificate was successfully removed."
  end

  def update
    @cert = @system_certificate.certificate || Certificate.new(certificate: certificate_param)

    ActiveRecord::Base.transaction do
      @system_certificate.update_attributes!(system_certificate_params.except(:certificate))

      if certificate_param.present?
        create_or_update_certificate!
      elsif @system_certificate.certificate.present?
        @system_certificate.certificate.destroy!
      end
    end
    redirect_to [:settings, @system_certificate],
                notice: "System certificate was successfully updated."
  rescue ActiveRecord::RecordInvalid
    render action: edit, status: :unprocessable_entity
  end

  private

  def set_system_certificate
    @system_certificate = SystemCertificate.find(params[:id])
  end

  def certificate_param
    system_certificate_params[:certificate].strip if
      system_certificate_params[:certificate].present?
  end

  def system_certificate_params
    params.require(:system_certificate).permit(:name, :certificate)
  end

  def create_or_update_certificate!
    if @cert.new_record?
      @cert.save!
      CertificateService.create!(service: @system_certificate, certificate: @cert)
    else
      @cert.update_attributes!(certificate: certificate_param)
    end
  end
end
