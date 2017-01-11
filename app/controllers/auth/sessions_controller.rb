# frozen_string_literal: true
# Auth::SessionsController manages the session of users.
class Auth::SessionsController < Devise::SessionsController
  layout "authentication"

  before_action :configure_sign_up_params, only: [:create]

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:email])
  end
end
