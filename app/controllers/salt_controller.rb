require "velum/salt"
# SaltController holds methods for triggering updates of nodes
class SaltController < ApplicationController
  skip_before_action :redirect_to_setup

  def update
    Minion.mark_pending_update
    Velum::Salt.update_orchestration

    respond_to do |format|
      format.html { redirect_to root_path }
      format.json { head :ok }
    end
  end
end
