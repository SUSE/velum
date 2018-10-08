class RenameCloudSubnetPillar < ActiveRecord::Migration
  def up
    rename_pillar(
      from: "cloud:profiles:cluster_node:network_interfaces:0:SubnetId",
      to:   "cloud:profiles:cluster_node:subnet"
    )
    rename_pillar(
      from: "cloud:profiles:cluster_node:network_interfaces:0:SecurityGroupId",
      to:   "cloud:profiles:cluster_node:security_group"
    )
  end

  def down
    rename_pillar(
      from: "cloud:profiles:cluster_node:subnet",
      to:   "cloud:profiles:cluster_node:network_interfaces:0:SubnetId"
    )
    rename_pillar(
      from: "cloud:profiles:cluster_node:security_group",
      to:   "cloud:profiles:cluster_node:network_interfaces:0:SecurityGroupId"
    )
  end

  def rename_pillar(from:, to:)
    return unless Pillar.find_by_pillar(from)
    return if Pillar.find_by_pillar(to)
    Pillar.find_by_pillar(from).update(pillar: to)
  end
end
