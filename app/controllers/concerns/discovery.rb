require "velum/salt"

# Discovery implements the discovery method that is shared both when
# bootstrapping and when showing the dashboard.
module Discovery
  extend ActiveSupport::Concern

  # Responds with either an HTML or JSON version of the available minions.
  def discovery
    assigned_minions                  = Minion.cluster_role
    unassigned_minions                = Minion.unassigned_role
    pending_minions                   = ::Velum::Salt.pending_minions
    retryable_bootstrap_orchestration = Orchestration.retryable? kind: :bootstrap
    retryable_upgrade_orchestration   = Orchestration.retryable? kind: :upgrade

    respond_to do |format|
      format.html
      format.json do
        hsh = {
          assigned_minions:                  assigned_minions,
          unassigned_minions:                unassigned_minions,
          pending_minions:                   pending_minions,
          admin:                             Minion.find_by(minion_id: "admin"),
          retryable_bootstrap_orchestration: retryable_bootstrap_orchestration,
          retryable_upgrade_orchestration:   retryable_upgrade_orchestration
        }
        render json: hsh
      end
    end
  end
end
