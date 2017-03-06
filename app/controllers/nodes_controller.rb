# frozen_string_literal: true

require "velum/salt"

# NodesController is responsible for everything related to nodes: showing
# information on nodes, deleting them, etc.
class NodesController < ApplicationController
  rescue_from Minion::NonExistingMinion, with: :minion_not_found

  def index
    @minions = Minion.all

    respond_to do |format|
      format.html
      format.json { render json: @minions }
    end
  end

  def show
    @minion = Minion.find(params[:id])
  end

  def update_nodes
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
        format.html { redirect_to nodes_path }
        format.json { head :ok }
      end
    end
  end

  # Bootstraps the cluster. This method will search for minions missing an
  # assigned role, assign a random role to it, and then call the salt
  # orchestration.
  def bootstrap
    if Minion.exists?(role: "master")
      Velum::Salt.orchestrate
      flash[:info] = "Successfully triggered orchestration on all Salt minions."
    else
      flash[:alert] = "There is no minion with the master role assigned yet."
    end

    redirect_to nodes_path
  end

  # TODO
  def destroy; end

  protected

  def update_nodes_params
    params.require(:roles)
  end

  def failed_assigned_nodes(assigned)
    assigned.select { |_name, success| !success }.keys.join(", ")
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
