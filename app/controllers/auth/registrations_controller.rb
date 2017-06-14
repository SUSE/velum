# frozen_string_literal: true
# Auth::RegistrationsController manages user signup/removal.
class Auth::RegistrationsController < Devise::RegistrationsController
  before_action :restrict_admin_users

  layout "authentication", except: :edit

  skip_before_action :redirect_to_setup

  # Re-implemented so the template has some auxiliary instance variables.
  def new
    @have_users = User.any?
    super
  end

  # Restrict the amount of admin users to 1, see bsc#1040831
  def restrict_admin_users
    return if User.count.zero?
    flash[:alert] = "Admin user already exists."
    redirect_to root_path
  end
end
