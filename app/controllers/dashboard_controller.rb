# frozen_string_literal: true

# DashboardController shows the main page.
class DashboardController < ApplicationController
  def index
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
