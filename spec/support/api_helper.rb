module ApiHelper
  def http_login
    request.env["HTTP_AUTHORIZATION"] =
      ActionController::HttpAuthentication::Basic.encode_credentials "test", "test"
  end
end
