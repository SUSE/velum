# Settings::RegistryMirrorsController is responsibe to manage all the requests
# related to the registry mirrors feature
class Settings::RegistryMirrorsController < Settings::BaseCertificateController
  before_action :set_registry_mirror, except: [:index, :new, :create]

  def index
    @grouped_mirrors = Registry.grouped_mirrors
  end

  def new
    @registry_mirror = RegistryMirror.new
    @cert = Certificate.new
  end

  def create
    @registry = Registry.find(registry_mirror_params[:registry_id])
    registry_mirror_create_params = registry_mirror_params.except(:certificate, :registry_id)
    @registry_mirror = @registry.registry_mirrors.build(registry_mirror_create_params)
    @cert = Certificate.find_or_initialize_by(certificate: certificate_param)

    ActiveRecord::Base.transaction do
      @registry_mirror.save!

      create_or_update_certificate! if certificate_param.present?

      @created = true
    end

    redirect_to [:settings, @registry_mirror], notice: "Mirror was successfully created."
  rescue ActiveRecord::RecordInvalid
    render action: :new, status: :unprocessable_entity
  end

  def destroy
    @registry_mirror.destroy
    redirect_to settings_registry_mirrors_path, notice: "Mirror was successfully removed."
  end

  protected

  def certificate_holder
    @registry_mirror
  end

  def certificate_holder_update_params
    registry_mirror_params.except(:certificate, :registry_id)
  end

  private

  def set_registry_mirror
    @registry_mirror = RegistryMirror.find(params[:id])
  end

  def certificate_param
    registry_mirror_params[:certificate].strip if registry_mirror_params[:certificate].present?
  end

  def registry_mirror_params
    params.require(:registry_mirror).permit(:name, :url, :certificate, :registry_id)
  end
end
