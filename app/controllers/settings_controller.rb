# SettingsController is a generic controller that so far only sets the layout template
# and redirects the /settings endpoint
class SettingsController < ApplicationController
  layout "settings"

  def index
    redirect_to settings_registries_path
  end

  def apply
    Minion.mark_pending_bootstrap!
    Orchestration.run(kind: :bootstrap)
    redirect_to root_path, notice: "Registry settings are applied once orchestration is done."
  rescue Orchestration::OrchestrationOngoing
    redirect_to request.referer,
                  alert: "Orchestration currently ongoing. Please wait for it to finish."
  end
end
