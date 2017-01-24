# frozen_string_literal: true
# Auth::RegistrationsController manages user signup/removal.
class Auth::RegistrationsController < Devise::RegistrationsController
  layout "authentication", except: :edit

  # Re-implemented so the template has some auxiliary instance variables.
  def new
    @have_users = User.any?
    super
  end
end
