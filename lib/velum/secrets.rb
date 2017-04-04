require "securerandom"

module Velum
  # If there is a rails key base stored on disk, return the stored one.
  # Otherwise, create a new key base from cryptographic random pool and store it.
  class Secrets
    def self.read_or_create_secret_key_base(pathname)
      pathname.dirname.mkpath
      key_base = nil
      if pathname.exist?
        content = pathname.read
        content != "" && key_base = content
      end
      if key_base.nil?
        key_base = SecureRandom.hex(64)
        pathname.write(key_base)
      end
      key_base
    end
  end
end
