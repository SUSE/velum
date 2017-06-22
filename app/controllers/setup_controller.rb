# frozen_string_literal: true

require "velum/salt"

# SetupController is responsible for everything related to the bootstrapping
# process:
# welcoming, setting certain general settings, master selection, discovery and
# bootstrapping
class SetupController < ApplicationController
  include Discovery

  rescue_from Minion::NonExistingNode, with: :node_not_found

  skip_before_action :redirect_to_setup
  before_action :redirect_to_dashboard
  before_action :check_empty_settings, only: :configure
  before_action :check_empty_bootstrap, only: :bootstrap

  def configure
    res = Pillar.apply(settings_params)

    respond_to do |format|
      if res.empty?
        format.html { redirect_to setup_worker_bootstrap_path }
        format.json { head :ok }
      else
        format.html do
          flash[:alert] = res
          redirect_to setup_path
        end
        format.json { render json: res, status: :unprocessable_entity }
      end
    end
  end

  def worker_bootstrap
    @controller_node = Pillar.value pillar: :dashboard
  end

  def bootstrap
    assigned = Minion.assign_roles!(roles: update_nodes_params)

    respond_to do |format|
      if assigned.values.include?(false)
        message = "Failed to assign #{failed_assigned_nodes(assigned)}"

        format.html do
          flash[:error] = message
          redirect_to setup_discovery_path
        end
        format.json { render json: message, status: :unprocessable_entity }
      else
        Velum::Salt.orchestrate
        format.html { redirect_to root_path }
        format.json { head :ok }
      end
    end
  end

  private

  def settings_params
    params.require(:settings).permit(*Pillar.all_pillars.keys)
  end

  def update_nodes_params
    params.require(:roles)
  end

  def redirect_to_dashboard
    redirect_to root_path if setup_done?
  end

  def failed_assigned_nodes(assigned)
    assigned.select { |_name, success| !success }.keys.join(", ")
  end

  def node_not_found(exception)
    respond_to do |format|
      format.html do
        flash[:error] = exception.message
        redirect_to setup_path
      end
      format.json { render json: exception.message, status: :not_found }
    end
  end

  def check_empty_settings
    params = settings_params.except(:http_proxy, :https_proxy, :no_proxy)
    return unless params.values.any?(&:empty?)

    respond_to do |format|
      msg = "Please fill out all necessary form fields"
      format.html do
        redirect_to setup_path, alert: msg
      end
      format.json { render json: msg, status: :unprocessable_entity }
    end
  end

  def check_empty_bootstrap
    return if params.try(:[], "roles").try(:[], "master")
    respond_to do |format|
      msg = "Please select a master node"
      format.html do
        redirect_to setup_discovery_path, alert: msg
      end
      format.json { render json: msg, status: :unprocessable_entity }
    end
  end
end
