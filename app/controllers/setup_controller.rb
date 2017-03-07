# frozen_string_literal: true

require "velum/salt"

# SetupController is responsible for everything related to the bootstrapping
# process:
# welcoming, setting certain general settings, master selection, discovery and
# bootstrapping
class SetupController < ApplicationController
  rescue_from Minion::NonExistingMinion, with: :minion_not_found

  skip_before_action :redirect_to_setup
  before_action :redirect_to_dashboard

  def configure
    Pillar.all_pillars.each do |key, pillar_key|
      pillar = Pillar.find_or_initialize_by pillar: pillar_key
      pillar.value = settings_params[key]
      pillar.save
    end
    redirect_to setup_worker_bootstrap_path
  end

  def discovery
    @minions = Minion.all

    respond_to do |format|
      format.html
      format.json { render json: @minions }
    end
  end

  def bootstrap
    assigned = Minion.assign_roles!(roles: update_nodes_params)

    respond_to do |format|
      if assigned.values.include?(false)
        message = "Failed to assign #{failed_assigned_nodes(assigned)}"
        format.html do
          flash[:error] = message
          redirect_to nodes_path
        end
        format.json { render json: message, status: :unprocessable_entity }
      else
        Velum::Salt.orchestrate
        format.html { redirect_to_dashboard }
        format.json { head :ok }
      end
    end
  end

  private

  def redirect_to_dashboard
    redirect_to root_path unless Minion.assigned_role.count.zero?
  end

  def settings_params
    params.require(:settings).permit(*Pillar.all_pillars.keys)
  end

  def update_nodes_params
    params.require(:roles)
  end

  def minion_not_found(exception)
    respond_to do |format|
      format.html do
        flash[:error] = exception.message
        redirect_to nodes_path
      end
      format.json { render json: exception.message, status: :not_found }
    end
  end
end
