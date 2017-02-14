# frozen_string_literal: true

require "velum/salt"

# NodesController is responsible for everything related to nodes: showing
# information on nodes, deleting them, etc.
class NodesController < ApplicationController
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

  # Bootstraps the cluster. This method will search for minions missing an
  # assigned role, assign a random role to it, and then call the salt
  # orchestration.
  def bootstrap
    if Minion.where(role: nil).count > 1
      Minion.assign_roles(roles: [:master], default_role: :minion)
      Velum::Salt.orchestrate
    else
      flash[:alert] = "Not enough Workers to bootstrap. Please start at least one worker."
    end

    redirect_to nodes_path
  end

  # TODO
  def destroy; end
end
