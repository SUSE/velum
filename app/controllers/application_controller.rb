# frozen_string_literal: true

# ApplicationController is the superclass of all controllers.
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :redirect_to_setup
  protect_from_forgery with: :exception

  private

  def redirect_to_setup
    return true unless signed_in?
    redirect_to setup_path unless setup_done?
  end

  # setup means minions were assigned to roles
  # returns true if at least one minion has role != nil
  # return false otherwise
  def setup_done?
    !Minion.assigned_role.count.zero?
  end
end
