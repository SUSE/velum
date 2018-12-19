# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [
  :pass, :password, :bind_pw,
  :cert, :certificate,
  :client_secret,
  :authenticity_token, :id_token, :refresh_token,
  :velum_cert, :velum_key, :kubeapi_cert,
  :kubeapi_key, :dex_cert, :dex_key
]
