# frozen_string_literal: true

# InternalApiController is the superclass of all internal API controllers.
class InternalApiController < ActionController::Base
  include Api

  before_action :authenticate_request

  private

  def authenticate_request
    authenticate_or_request_with_http_basic("Velum Internal API") do |username, password|
      username == Rails.application.secrets.internal_api[:username] &&
        password == Rails.application.secrets.internal_api[:password]
    end
  end
end
