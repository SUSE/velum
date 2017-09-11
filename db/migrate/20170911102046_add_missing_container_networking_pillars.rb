class AddMissingContainerNetworkingPillars < ActiveRecord::Migration
  def up
    Pillar.find_or_create_by pillar: :cluster_cidr do |pillar|
      pillar.value = "172.20.0.0/16"
    end
    Pillar.find_or_create_by pillar: :cluster_cidr_min do |pillar|
      pillar.value = "172.20.50.0"
    end
    Pillar.find_or_create_by pillar: :cluster_cidr_max do |pillar|
      pillar.value = "172.20.199.0"
    end
    Pillar.find_or_create_by pillar: :cluster_cidr_len do |pillar|
      pillar.value = "24"
    end
    Pillar.find_or_create_by pillar: :services_cidr do |pillar|
      pillar.value = "172.21.0.0/16"
    end
    Pillar.find_or_create_by pillar: "api:cluster_ip" do |pillar|
      pillar.value = "172.21.0.1"
    end
    Pillar.find_or_create_by pillar: "dns:cluster_ip" do |pillar|
      pillar.value = "172.21.0.2"
    end
  end
  def down
    Pillar.where(pillar: [:cluster_cidr, :cluster_cidr_min, :cluster_cidr_max, :cluster_cidr_len,
                          :services_cidr, "api:cluster_ip", "dns:cluster_ip"]).destroy_all
  end
end
