# frozen_string_literal: true
# Auth::RegistrationsController manages user signup/removal.
class Auth::RegistrationsController < Devise::RegistrationsController
  layout "authentication", except: :edit
end
