# frozen_string_literal: true

require "pharos/salt"

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
    available_roles = [:master]
    Minion.where(role: nil).find_each do |minion|
      random_role = if available_roles.blank?
        :minion
      else
        available_roles.delete_at(rand(available_roles.length))
      end
      minion.assign_role(role: random_role)
    end
    Pharos::Salt.orchestrate
    redirect_to nodes_path
  end

  # TODO
  def destroy; end
end
