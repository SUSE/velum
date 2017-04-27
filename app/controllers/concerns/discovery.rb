# Discovery implements the discovery method that is shared both when
# bootstrapping and when showing the dashboard.
module Discovery
  extend ActiveSupport::Concern

  # Responds with either an HTML or JSON version of the available minions.
  def discovery
    @assigned_minions = Minion.assigned_role
    @unassigned_minions = Minion.unassigned_role

    respond_to do |format|
      format.html
      format.json do
        render json: { assigned_minions:   @assigned_minions,
                       unassigned_minions: @unassigned_minions }
      end
    end
  end
end
