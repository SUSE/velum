# Settings::Auditing is responsibe to manage all the requests
# related to the kubernetes auditing feature.
class Settings::AuditingController < SettingsController
  def index
    set_instance_variables
  end

  def create
    @errors = Pillar.apply audit_params
    if @errors.empty?
      redirect_to settings_auditing_index_path,
        notice: "Auditing settings successfully saved."
    else
      set_instance_variables
      render action: :index, status: :unprocessable_entity
    end
  end

  private

  def set_instance_variables
    @audit_enabled = Pillar.value(pillar: :api_audit_log_enabled) || "false"
    @maxsize = Pillar.value(pillar: :api_audit_log_maxsize) || 10
    @maxage = Pillar.value(pillar: :api_audit_log_maxage) || 15
    @maxbackup = Pillar.value(pillar: :api_audit_log_maxbackup) || 20
    @policy = Pillar.value(pillar: :api_audit_log_policy) || ""
  end

  def audit_params
    ret = {}
    params.require(
      :audit
    ).permit(
      :enabled,
      :maxage,
      :maxsize,
      :maxbackup,
      :policy
    ).each do |k, v|
      ret["api_audit_log_#{k}".to_sym] = v
    end
    ret
  end
end
