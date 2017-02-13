class AddHighstateToMinions < ActiveRecord::Migration
  def change
    add_column :minions, :highstate, :integer, default: 0, after: :role
  end
end
