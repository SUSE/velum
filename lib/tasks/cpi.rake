# rubocop:disable Metrics/BlockLength

namespace :cpi do
  desc "Import OpenStack Cloud Proivider options"
  task :openstack, [:config] => :environment do |_, args|
    config_file = args[:config] || "/etc/caasp/cpi/openstack.conf"
    unless File.exist?(config_file)
      puts "OpenStack Cloud Provider config file doesn't exist"
      exit(1)
    end
    cfg = {}
    File.open(config_file, "r").each do |line|
      cfg["cloud:provider"] = "openstack"
      line.chomp!
      key, value = line.delete('"').split("=")
      case key
        when /^[\[#]/; # ignore line
        when "auth-url" then            cfg["cloud:openstack:auth_url"] = value
        when "domain-name" then         cfg["cloud:openstack:domain_name"] = value
        when "tenant-name" then         cfg["cloud:openstack:tenant_name"] = value
        when "region" then              cfg["cloud:openstack:region"] = value
        when "username" then            cfg["cloud:openstack:username"] = value
        when "password" then            cfg["cloud:openstack:password"] = value
        when "subnet-id" then           cfg["cloud:openstack:subnet_id"] = value
        when "floating-network-id" then cfg["cloud:openstack:floating_id"] = value
        when "monitor-max-retries" then cfg["cloud:openstack:lb_mon_retries"] = value
        when "bs-version" then          cfg["cloud:openstack:bs_version"] = value
        when /^./ then                  puts "#{key}: unknown option"
      end
    end
    cfg.each do |pillar, value|
      Pillar.find_or_create_by!(pillar: pillar) do |pillar|
        pillar.value = value
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
