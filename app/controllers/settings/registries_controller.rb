# Settings::RegistriesController is responsibe to manage all the requests
# related to the registries feature
class Settings::RegistriesController < SettingsController
  before_action :set_registry, except: [:index, :new, :create]

  def index
    @registries = Registry.displayable
  end

  def new
    @registry = Registry.new
    @cert = Certificate.new
  end

  def create
    @registry = Registry.new(registry_params.except(:certificate))
    @cert = Certificate.find_or_initialize_by(certificate: certificate_param)

    ActiveRecord::Base.transaction do
      @registry.save!
      create_or_update_certificate! if certificate_param.present?
    end

    redirect_to [:settings, @registry], notice: "Registry was successfully created."
  rescue ActiveRecord::RecordInvalid
    render action: :new, status: :unprocessable_entity
  end

  def show
    not_found if suse_registry?(@registry)
  end

  def edit
    @cert = @registry.certificate || Certificate.new
  end

  def update
    @cert = @registry.certificate || Certificate.new(certificate: certificate_param)

    ActiveRecord::Base.transaction do
      @registry.update_attributes!(registry_params.except(:certificate))

      if certificate_param.present?
        create_or_update_certificate!
      elsif @registry.certificate.present?
        @registry.certificate.destroy!
      end
    end

    redirect_to [:settings, @registry], notice: "Registry was successfully updated."
  rescue ActiveRecord::RecordInvalid
    render action: :edit, status: :unprocessable_entity
  end

  def destroy
    @registry.destroy
    redirect_to settings_registries_path, notice: "Registry was successfully removed."
  end

  private

  def set_registry
    @registry = Registry.find(params[:id])
  end

  def certificate_param
    registry_params[:certificate].strip if registry_params[:certificate].present?
  end

  def registry_params
    params.require(:registry).permit(:name, :url, :certificate)
  end

  def suse_registry?(registry)
    registry.name == Registry::SUSE_REGISTRY_NAME
  end

  def create_or_update_certificate!
    if @cert.new_record?
      @cert.save!
      CertificateService.create!(service: @registry, certificate: @cert)
    else
      @cert.update_attributes!(certificate: certificate_param)
    end
  end
end
