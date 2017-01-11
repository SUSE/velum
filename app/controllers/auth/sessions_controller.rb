# frozen_string_literal: true
# Auth::SessionsController manages the session of users.
class Auth::SessionsController < Devise::SessionsController
  layout "authentication"
end
