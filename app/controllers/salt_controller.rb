require "velum/salt"
require "velum/salt_api"
# HealthController holds methods for checking the readiness of the application.
class SaltController < ApplicationController
  include Velum::SaltApi
  skip_before_action :redirect_to_setup

  def update
    minions = Velum::Salt.minions()
    minions.each do |minion_id, grains|
      if grains["tx_update_reboot_needed"]
        Minion.find_by(minion_id: minion_id).update(highstate: Minion.highstates[:pending])
      end
    end

    Velum::Salt.update_orchestration

    respond_to do |format|
      format.html { redirect_to root_path }
      format.json { head :ok }
    end
  end
end
