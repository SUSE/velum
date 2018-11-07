# Settings::DexConnectorOidcsController is responsible to manage requests
# related to OIDC connectors.
class Settings::DexConnectorOidcsController < SettingsController
  # populate @data_holder with existing database record
  before_action :set_data_holder, except: [:index, :new, :create]

  def index
    @oidc_connectors = DexConnectorOidc.all
  end

  def new
    @is_data_valid = false
    @data_holder = data_holder_type.new
  end

  def edit
    @is_data_valid = false
  end

  def create
    @data_holder = data_holder_type.new(data_holder_params)

    if params[:validate]
      @is_data_valid = @data_holder.valid?
      if @is_data_valid
        flash.now[:notice] = "#{friendly_name} is valid"
      else
        flash.now[:alert]  = "#{friendly_name} is invalid"
      end
      render action: :new
    else
      @data_holder.save!
      redirect_to settings_dex_connector_oidcs_path,
                  notice: "#{friendly_name} was successfully created."
    end
  rescue ActiveRecord::RecordInvalid
    render action: :new, status: :unprocessable_entity
  end

  def destroy
    @data_holder.destroy!

    redirect_to settings_dex_connector_oidcs_path,
                notice: "OIDC Connector was successfully removed."
  end

  def update
    if params[:validate]
      # merge form values with DB record so form redisplays properly
      data_holder_update_params.each do |key, value|
        @data_holder[key] = value
      end
      @is_data_valid = @data_holder.valid?
      if @is_data_valid
        flash.now[:notice] = "#{friendly_name} is valid"
      else
        flash.now[:alert]  = "#{friendly_name} is invalid"
      end
      render action: :edit
    else
      @data_holder.update_attributes!(data_holder_update_params)
      redirect_to [:settings, @data_holder],
                  notice: "#{friendly_name} was successfully updated."
    end
  rescue ActiveRecord::RecordInvalid
    render action: :edit, status: :unprocessable_entity
  end

  protected

  def data_holder_type
    DexConnectorOidc
  end

  def data_holder_params
    oidc_connector_params
  end

  def data_holder_update_params
    oidc_connector_params
  end

  def friendly_name
    "OIDC Connector"
  end

  private

  def oidc_connector_params
    params.require(:dex_connector_oidc).permit(
      :name, :provider_url, :client_id, :client_secret, :callback_url, :basic_auth
    )
  end

  def set_data_holder
    @data_holder = data_holder_type.find(params[:id])
  end
end
