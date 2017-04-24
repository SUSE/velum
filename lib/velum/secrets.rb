require "pathname"
require "securerandom"

module Velum
  # If there is a rails key base stored on disk, return the stored one.
  # Otherwise, create a new key base from cryptographic random pool and store it.
  class Secrets
    def self.read_or_create_secret_key_base(key_path)
      key_path = Pathname.new(key_path)
      key_path.dirname.mkpath
      return key_path.read if key_path.exist?
      SecureRandom.hex(64).tap { |secret_key_base| key_path.write secret_key_base }
    end
  end
end
