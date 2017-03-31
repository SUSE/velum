# frozen_string_literal: true
# Be sure to restart your server after modifying this file.

require "pathname"
require "velum/secrets"

env_path = Pathname.new("#{ENV.fetch("VELUM_SECRETS_DIR")}/key_base.json")
Rails.application.secrets.secret_key_base = Velum.read_create_secret_key_base(env_path)
