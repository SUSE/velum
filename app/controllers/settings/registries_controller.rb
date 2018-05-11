# Settings::RegistriesController is responsibe to manage all the requests
# related to the registries feature
class Settings::RegistriesController < Settings::BaseCertificateController
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

  def destroy
    @registry.destroy
    redirect_to settings_registries_path, notice: "Registry was successfully removed."
  end

  protected

  def certificate_holder
    @registry
  end

  def certificate_holder_update_params
    registry_params.except(:certificate)
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
end
