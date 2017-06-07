require "velum/salt"

# Discovery implements the discovery method that is shared both when
# bootstrapping and when showing the dashboard.
module Discovery
  extend ActiveSupport::Concern

  # Responds with either an HTML or JSON version of the available minions.
  def discovery
    @assigned_minions   = Minion.assigned_role
    @unassigned_minions = Minion.unassigned_role

    respond_to do |format|
      format.html
      format.json do
        render json: {
                 assigned_minions:   @assigned_minions,
                 unassigned_minions: @unassigned_minions,
                 admin:              { update: admin_status }
               }
      end
    end
  end

  protected

  # TODO: for now this only applies to the admin node, but for the future:
  #
  #  1. A similar thing should be done for *all* nodes.
  #  2. Since it would apply to all nodes, maybe it would make more sense to
  #     have it on the DB and have another process polling for this. Then, on the
  #     `discovery` method this would all be returned transparently.
  #     2.1. NOTE: Other nodes should only be taken into consideration if
  #          automatic updates has not been enabled.
  def admin_status
    Rails.cache.fetch("update_status", expires_in: 30.seconds) do
      needed, failed = ::Velum::Salt.update_status(targets: "*")

      if failed.first && !failed.first["admin"].blank?
        Minion.statuses[:update_failed]
      elsif needed.first && !needed.first["admin"].blank?
        Minion.statuses[:update_needed]
      else
        Minion.status[:unknown]
      end
    end
  end
end
