# frozen_string_literal: true
# Auth::RegistrationsController manages user signup/removal.
class Auth::RegistrationsController < Devise::RegistrationsController
  layout "authentication", except: :edit

  skip_before_action :redirect_to_setup

  # Re-implemented so the template has some auxiliary instance variables.
  def new
    @have_users = User.any?
    super
  end
end
