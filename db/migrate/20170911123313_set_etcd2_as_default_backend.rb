class SetEtcd2AsDefaultBackend < ActiveRecord::Migration
  def up
    Pillar.find_or_create_by pillar: "api:etcd_version" do |pillar|
      pillar.value = "etcd2"
    end
  end
  def down
    Pillar.where(pillar: "api:etcd_version").destroy_all
  end
end
