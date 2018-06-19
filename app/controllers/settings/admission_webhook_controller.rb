# Settings::AdmissionWebhook is responsibe to manage all the requests
# related to the kubernetes auditing feature.
class Settings::AdmissionWebhookController < SettingsController
  def index
    set_instance_variables
  end

  def create
    @errors = Pillar.apply admission_webhook_params
    if @errors.empty?
      redirect_to settings_admission_webhook_index_path,
        notice: "Admission webhook settings successfully saved."
    else
      set_instance_variables
      render action: :index, status: :unprocessable_entity
    end
  end

  private

  def set_instance_variables
    @admission_webhook_enabled = Pillar.value(pillar: :api_admission_webhook_enabled) || "false"
    @cert = Pillar.value(pillar: :api_admission_webhook_cert)
    @key = Pillar.value(pillar: :api_admission_webhook_key)
  end

  def admission_webhook_params
    ret = {}
    sanitized_params = params.require(
      :admission_webhook
    ).permit(
      :enabled,
      :cert,
      :key,
      :current_cert,
      :current_key,
    )

    ret = {
      api_admission_webhook_enabled: sanitized_params["enabled"]
    }

    ret[:api_admission_webhook_cert] = if sanitized_params.include?("cert")
      sanitized_params["cert"].read
    else
      sanitized_params["current_cert"]
    end

    ret[:api_admission_webhook_key] = if sanitized_params.include?("key")
      sanitized_params["key"].read
    else
      sanitized_params["current_key"]
    end

    ret
  end
end
