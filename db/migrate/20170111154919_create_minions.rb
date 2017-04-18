class CreateMinions < ActiveRecord::Migration
  def change
    create_table :minions do |t|
      t.string :minion_id
      t.string :fqdn
      t.timestamps
    end
    add_index :minions, :minion_id
    add_index :minions, :fqdn
  end
end
