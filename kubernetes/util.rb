def salt_adapted_config_dir
  File.expand_path File.join(File.dirname(__FILE__), "tmp", "salt")
end
