class SetUdpAsDefaultFlannelBackend < ActiveRecord::Migration
  def up
    Pillar.find_or_create_by pillar: "flannel:backend" do |pillar|
      pillar.value = "udp"
    end
  end
  def down
    Pillar.where(pillar: "flannel:backend").destroy_all
  end
end
