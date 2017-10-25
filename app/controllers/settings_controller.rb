# SettingsController is a generic controller that so far only sets the layout template
# and redirects the /settings endpoint
class SettingsController < ApplicationController
  layout "settings"

  def index
    redirect_to settings_registries_path
  end
end
