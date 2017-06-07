require "velum/salt"
# Discovery implements the discovery method that is shared both when
# bootstrapping and when showing the dashboard.
module Discovery
  extend ActiveSupport::Concern

  # Responds with either an HTML or JSON version of the available minions.
  def discovery
    @assigned_minions = Minion.assigned_role
    @unassigned_minions = Minion.unassigned_role

    tx_update_reboot_needed = {}
    tx_update_failed = {}

    minions = Velum::Salt.minions()

    minions.each do |minion_id, grains|
      tx_update_reboot_needed[minion_id] = grains["tx_update_reboot_needed"]
      tx_update_failed[minion_id] = grains["tx_update_failed"]
    end

    respond_to do |format|
      format.html
      format.json do
        render json: { assigned_minions:        @assigned_minions,
                       unassigned_minions:      @unassigned_minions,
                       tx_update_reboot_needed: tx_update_reboot_needed,
                       tx_update_failed:        tx_update_failed }
      end
    end
  end
end
