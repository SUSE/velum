# Be sure to restart your server after modifying this file.

Rails.application.config.internal_api = {
  username_path: "/var/lib/misc/infra-secrets/velum-internal-api-username",
  password_path: "/var/lib/misc/infra-secrets/velum-internal-api-password"
}

if File.exist?(Rails.application.config.internal_api[:username_path]) &&
    File.exist?(Rails.application.config.internal_api[:password_path])
  Rails.application.secrets.internal_api = {
    username: File.read(Rails.application.config.internal_api[:username_path]).strip,
    password: File.read(Rails.application.config.internal_api[:password_path]).strip
  }
end
