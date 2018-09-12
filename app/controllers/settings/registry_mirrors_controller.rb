# Settings::RegistryMirrorsController is responsibe to manage all the requests
# related to the registry mirrors feature
class Settings::RegistryMirrorsController < Settings::BaseCertificateController
  def index
    @grouped_mirrors = Registry.grouped_mirrors
  end

  def create
    @registry = Registry.find(registry_mirror_params[:registry_id])
    registry_mirror_create_params = registry_mirror_params.except(:certificate,
                                                                  :current_cert,
                                                                  :registry_id)
    @certificate_holder = @registry.registry_mirrors.build(registry_mirror_create_params)
    @cert = passed_certificate

    ActiveRecord::Base.transaction do
      @certificate_holder.save!

      create_or_update_certificate! if passed_certificate.present?

      @created = true
    end

    redirect_to [:settings, @certificate_holder], notice: "Mirror was successfully created."
  rescue ActiveRecord::RecordInvalid
    render action: :new, status: :unprocessable_entity
  end

  def destroy
    @certificate_holder.destroy
    redirect_to settings_registry_mirrors_path, notice: "Mirror was successfully removed."
  end

  protected

  def certificate_holder_type
    RegistryMirror
  end

  def certificate_holder_params
    registry_mirror_params
  end

  def certificate_holder_update_params
    registry_mirror_params.except(:certificate, :current_cert, :registry_id)
  end

  private

  def registry_mirror_params
    params.require(:registry_mirror).permit(:name,
                                            :url,
                                            :certificate,
                                            :registry_id,
                                            :current_cert)
  end
end
