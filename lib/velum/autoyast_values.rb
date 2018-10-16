module Velum
  # Load values that will be used to populate the autoyast profile
  class AutoyastValues
    DEFAULT_KEYBOARD_LAYOUT = "english-us".freeze
    YAST_KEYBOARD_KEY = "YAST_KEYBOARD".freeze
    SSH_KEY_FILE = "/var/lib/misc/ssh-public-key/id_rsa.pub".freeze

    def initialize
      @controller_node = Pillar.value pillar: :dashboard
      return if @controller_node.blank?
      begin
        suse_connect_config = Rails.cache.fetch("SUSEConnect_config") do
          Velum::SUSEConnect.config
        end
        @suse_smt_url = suse_connect_config.smt_url
        @suse_regcode = suse_connect_config.regcode
        @do_registration = true
      rescue Velum::SUSEConnect::MissingRegCodeException,
             Velum::SUSEConnect::MissingCredentialsException,
             Velum::SUSEConnect::SCCConnectionException
        @do_registration = false
      end
      # rubocop:disable Style/RescueModifier
      @ssh_public_key = File.read(SSH_KEY_FILE) rescue nil
      @keyboard_layout = read_keyboard_layout
      # rubocop:enable Style/RescueModifier

      # proxy related settings
      @proxy_systemwide = Pillar.value(pillar: :proxy_systemwide) == "true"
      @proxy_http       = Pillar.value(pillar: :http_proxy)
      @proxy_https      = Pillar.value(pillar: :https_proxy)
      @proxy_no_proxy   = Pillar.value(pillar: :no_proxy)
    end

    # Read the keyboard layout set by Yast during installation.
    #
    # @return [String] the keyboard set from Yast, or 'english-us' as
    # default
    def read_keyboard_layout(keyboard_config_file: "/var/lib/misc/keyboard")
      return DEFAULT_KEYBOARD_LAYOUT unless File.file?(keyboard_config_file)
      yast_layout = File.readlines(keyboard_config_file).select do |line|
        line =~ /^#{YAST_KEYBOARD_KEY}=/
      end.first
      return DEFAULT_KEYBOARD_LAYOUT unless yast_layout
      layout, _char_map = yast_layout.split("=")[1].delete('"').split(",")
      layout ? layout : DEFAULT_KEYBOARD_LAYOUT
    end
  end
end
