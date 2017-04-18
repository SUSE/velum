class AddUniqIndexOnMinionsId < ActiveRecord::Migration
  def up
    remove_index :minions, :minion_id
    remove_index :minions, :fqdn
    add_index :minions, :minion_id, unique: true
    add_index :minions, :fqdn, unique: true
  end

  def down
    remove_index :minions, :minion_id
    remove_index :minions, :fqdn
    add_index :minions, :minion_id
    add_index :minions, :fqdn
  end
end
