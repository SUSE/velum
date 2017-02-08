class AddUniqIndexOnMinionsId < ActiveRecord::Migration
  def up
    remove_index :minions, :hostname
    add_index :minions, :hostname, unique: true
  end

  def down
    remove_index :minions, :hostname
    add_index :minions, :hostname
  end
end
