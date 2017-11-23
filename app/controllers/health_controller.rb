# HealthController holds methods for checking the readiness of the application.
class HealthController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :redirect_to_setup

  # Skipping the CSRF validation just in case. If we add more methods, then
  # we'll need to add an "except" or an "only" clause to this.
  skip_before_action :verify_authenticity_token

  def index
    render nothing: true, status: 200
  end
end
