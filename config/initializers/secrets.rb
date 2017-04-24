# frozen_string_literal: true
# Be sure to restart your server after modifying this file.

require "velum/secrets"

Rails.application.secrets.secret_key_base = Velum::Secrets.read_or_create_secret_key_base(
  File.join(ENV["VELUM_SECRETS_DIR"], "key_base.json")
)
