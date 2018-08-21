require "velum/salt"

# Discovery implements the discovery method that is shared both when
# bootstrapping and when showing the dashboard.
module Discovery
  extend ActiveSupport::Concern

  # Responds with either an HTML or JSON version of the available minions.
  def discovery
    respond_to do |format|
      format.html
      format.json do
        hsh = {
          assigned_minions:                  Minion.cluster_role,
          unassigned_minions:                Minion.unassigned_role,
          pending_minions:                   ::Velum::Salt.pending_minions,
          pending_cloud_jobs:                SaltJob.all_open.count,
          cloud_jobs_failed:                 SaltJob.failed.count,
          admin:                             Minion.find_by(minion_id: "admin"),
          retryable_bootstrap_orchestration: Orchestration.retryable?(kind: :bootstrap),
          retryable_migration_orchestration: Orchestration.retryable?(kind: :migration),
          retryable_upgrade_orchestration:   Orchestration.retryable?(kind: :upgrade),
          last_orchestration_at:             Orchestration.last.try(:created_at)
        }
        render json: hsh
      end
    end
  end
end
