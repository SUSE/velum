# Settings::RegistriesController is responsibe to manage all the requests
# related to the registries feature
class Settings::RegistriesController < Settings::BaseCertificateController
  def index
    @registries = Registry.displayable
  end

  def show
    not_found if suse_registry?(@certificate_holder)
  end

  def destroy
    @certificate_holder.destroy
    redirect_to settings_registries_path, notice: "Registry was successfully removed."
  end

  protected

  def certificate_holder_type
    Registry
  end

  def certificate_holder_params
    registry_params
  end

  def certificate_holder_update_params
    registry_params.except(:certificate, :current_cert)
  end

  private

  def registry_params
    params.require(:registry).permit(:name, :url, :certificate, :current_cert)
  end

  def suse_registry?(registry)
    registry.name == Registry::SUSE_REGISTRY_NAME
  end
end
