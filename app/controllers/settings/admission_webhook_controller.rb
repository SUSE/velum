# Settings::AdmissionWebhook is responsibe to manage all the requests
# related to the kubernetes auditing feature.
class Settings::AdmissionWebhookController < SettingsController
  def index
    @form = AdmissionWebhookForm.new
    set_instance_variables
  end

  def create
    @form = AdmissionWebhookForm.new(admission_webhook_params)

    if @form.valid?
      @errors = Pillar.apply(
        admission_webhook_pillars,
        unprotected_pillars: admission_webhook_pillars.keys
      )
    end

    if @form.valid? && @errors.empty?
      redirect_to settings_admission_webhook_index_path,
        notice: "Admission webhook settings successfully saved."
    else
      set_instance_variables
      render action: :index, status: :unprocessable_entity
    end
  end

  private

  def set_instance_variables
    @admission_webhook_enabled = @form.enabled == "true" ||
      Pillar.value(pillar: :api_admission_webhook_enabled) == "true"
    @certificate = Pillar.value(pillar: :api_admission_webhook_cert)
    @key = Pillar.value(pillar: :api_admission_webhook_key)
    @errors ||= []
  end

  def admission_webhook_params
    params.require(
      :admission_webhook
    ).permit(
      :enabled,
      :cert_file,
      :key_file,
      :current_cert,
      :current_key
    )
  end

  def admission_webhook_pillars
    ret = {
      api_admission_webhook_enabled: @form.enabled,
      api_admission_webhook_cert:    nil,
      api_admission_webhook_key:     nil
    }

    return ret if @form.enabled == "false"

    ret[:api_admission_webhook_cert] = @form.certificate || @form.current_cert
    ret[:api_admission_webhook_key] = @form.key || @form.current_key

    ret
  end
end
