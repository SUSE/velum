class CreateMinions < ActiveRecord::Migration
  def change
    create_table :minions do |t|
      t.string :hostname
      t.timestamps
    end
    add_index :minions, :hostname
  end
end
