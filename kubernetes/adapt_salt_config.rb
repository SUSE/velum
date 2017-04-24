# Copyright (C) 2017 SUSE LLC
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

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
