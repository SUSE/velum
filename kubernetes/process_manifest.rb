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
require "yaml"
require "fileutils"

if ARGV.count != 3
  puts "usage: #{$PROGRAM_NAME} container-manifests-dir velum-source-code-dir salt-dir"
  Process.exit 1
end

CONTAINERS_MANIFESTS_DIR = ARGV[0]
VELUM_SOURCE_CODE_DIR = ARGV[1]
SALT_DIR = ARGV[2]

CONTAINERS_MANIFESTS_ORIG_DIR = "/usr/share/caasp-container-manifests".freeze
SALT_ORIG_DIR = "/usr/share/salt/kubernetes".freeze

def container_volume(name:, path:)
  {
    "name"      => volume_name(name: name),
    "mountPath" => path
  }
end

def patch_container_image(container)
  if container["image"] =~ /^sles12\/velum/
    container["image"] = "sles12/velum:development"
  elsif container["image"] =~ /^sles12/
    # FIXME: this is a temporary solution until an official registry is available
    container["image"] = "docker-testing-registry.suse.de/#{container["image"]}"
  else
    warn "unknown image #{container["image"]}; won't replace it"
  end
end

def patch_container_envvars(container)
  (container["env"] || []).each do |envvar|
    case envvar["name"]
    when "RAILS_ENV"
      envvar["value"] = "development"
    when "VELUM_PORT"
      envvar["value"] = "3000"
    end
  end
end

def patch_container_volumes(container)
  container["volumeMounts"].reject! do |volume_mount|
    ["salt", "salt-master-config"].include? volume_mount["name"]
  end
  container["volumeMounts"] +=
    case container["name"]
    when "salt-master"
      [
        container_volume(name: "salt", path: SALT_ORIG_DIR),
        container_volume(name: "salt-master-config", path: "/etc/salt/master.d")
      ]
    when "salt-api"
      [
        container_volume(name: "salt-master-config", path: "/etc/salt/master.d")
      ]
    when "velum-dashboard", "velum-event-processor"
      [
        container_volume(name: "velum-source-code", path: "/srv/velum"),
        container_volume(name: "velum-bundle-config", path: "/srv/velum/.bundle")
      ]
    else
      []
    end
end

def patch_containers(yaml)
  yaml["spec"]["containers"].each do |container|
    patch_container_image container
    patch_container_envvars container
    patch_container_volumes container
  end
end

def volume_name(name:)
  "dev-env-#{name}"
end

def host_volume(name:, path:)
  {
    "name"     => volume_name(name: name),
    "hostPath" => {
      "path" => path
    }
  }
end

def patch_host_container_manifests(volume)
  if volume["hostPath"] && volume["hostPath"]["path"] =~ %r{^#{CONTAINERS_MANIFESTS_ORIG_DIR}}
    volume["hostPath"]["path"] = volume["hostPath"]["path"].sub CONTAINERS_MANIFESTS_ORIG_DIR,
                                                                CONTAINERS_MANIFESTS_DIR
    true
  else
    false
  end
end

def patch_host_salt(volume)
  if volume["hostPath"]["path"] && volume["hostPath"]["path"] =~ %r{^#{SALT_ORIG_DIR}}
    volume["hostPath"]["path"] = volume["hostPath"]["path"].sub SALT_ORIG_DIR, SALT_DIR
    true
  else
    false
  end
end

def patch_root_dir(volume)
  if volume["hostPath"] && volume["hostPath"]["path"]
    host_path = File.join File.expand_path(File.join(File.dirname(__FILE__),
                                                     "tmp",
                                                     "fake-root")),
                         volume["hostPath"]["path"]
    volume["hostPath"]["path"] = host_path
    FileUtils.mkdir_p host_path
    true
  else
    false
  end
end

def patch_host_volumes(yaml)
  yaml["spec"]["volumes"] ||= []
  yaml["spec"]["volumes"].each do |volume|
    patch_host_container_manifests(volume) || patch_host_salt(volume) || patch_root_dir(volume)
  end
  yaml["spec"]["volumes"] += [
    host_volume(name: "velum-source-code", path: VELUM_SOURCE_CODE_DIR),
    host_volume(name: "velum-bundle-config", path: File.join(VELUM_SOURCE_CODE_DIR, "kubernetes",
                                                             "velum-config")),
    host_volume(name: "salt", path: SALT_DIR),
    host_volume(name: "salt-master-config", path: File.join(salt_adapted_config_dir, "config",
                                                            "master.d"))
  ]
end

yaml = YAML.safe_load STDIN

patch_containers yaml
patch_host_volumes yaml

puts yaml.to_yaml
