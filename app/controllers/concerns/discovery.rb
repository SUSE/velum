require "velum/salt"

# Discovery implements the discovery method that is shared both when
# bootstrapping and when showing the dashboard.
module Discovery
  extend ActiveSupport::Concern

  # Responds with either an HTML or JSON version of the available minions.
  def discovery
    @assigned_minions   = assigned_with_status
    @unassigned_minions = Minion.unassigned_role
    pending_minions     = ::Velum::Salt.pending_minions

    respond_to do |format|
      format.html
      format.json do
        hsh = {
          assigned_minions:   @assigned_minions,
          unassigned_minions: @unassigned_minions,
          pending_minions:    pending_minions,
          admin:              admin_status
        }
        render json: hsh, methods: [:update_status]
      end
    end
  end

  protected

  # TODO(mssola):
  #  1. It would make more sense to have the update status on the DB and have
  #     another process polling for this. Then, on the `discovery` method this
  #     would all be returned transparently (thus removing all the methods below).
  #  2. NOTE: Other nodes should only be taken into consideration if
  #     automatic updates has not been enabled.

  def assigned_with_status
    needed, failed = ::Velum::Salt.update_status(cached: true)

    # NOTE: this is highly inefficient and will disappear if we implement the
    # idea written above.
    minions = Minion.assigned_role
    minions.each do |minion|
      minion.update_status = Minion.computed_status(minion.minion_id, needed, failed)
    end

    minions
  end

  def admin_status
    needed, failed = ::Velum::Salt.update_status(cached: true)
    { update_status: Minion.computed_status("admin", needed, failed) }
  end
end
