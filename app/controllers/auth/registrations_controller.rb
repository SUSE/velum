# frozen_string_literal: true
# Auth::RegistrationsController manages user signup/removal.
class Auth::RegistrationsController < Devise::RegistrationsController
  layout "authentication", except: :edit

  before_action :configure_sign_up_params, only: [:create]

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email])
  end
end
