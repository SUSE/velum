$LOAD_PATH.unshift File.dirname(__FILE__)

require "util"
require "fileutils"

if ARGV.count != 1
  puts "usage: #{$PROGRAM_NAME} salt-dir"
  Process.exit 1
end

SALT_DIR = ARGV[0]

SALT_CONFIG_SUBSTITUTIONS = {
  "velum_production" => "velum_development"
}.freeze

def adapt_salt_configuration
  FileUtils.rm_rf salt_adapted_config_dir
  FileUtils.mkdir_p salt_adapted_config_dir
  FileUtils.cp_r File.join(SALT_DIR, "config"), salt_adapted_config_dir
  Dir.glob(File.join(salt_adapted_config_dir, "**", "*")) do |config_file|
    next unless File.file? config_file
    file_contents = File.read config_file
    SALT_CONFIG_SUBSTITUTIONS.each do |old_value, new_value|
      file_contents.gsub! old_value, new_value
    end
    File.open(config_file, "w") { |file| file.write file_contents }
  end
end

adapt_salt_configuration
