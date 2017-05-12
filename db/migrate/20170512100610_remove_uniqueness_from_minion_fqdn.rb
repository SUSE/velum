class RemoveUniquenessFromMinionFqdn < ActiveRecord::Migration
  def up
    remove_index :minions, :fqdn
    add_index :minions, :fqdn
  end

  def down
    remove_index :minions, :fqdn
    add_index :minions, :fqdn, unique: true
  end
end
