# Auth::SessionsController manages the session of users.
class Auth::SessionsController < Devise::SessionsController
  layout "authentication"

  skip_before_action :redirect_to_setup
end
