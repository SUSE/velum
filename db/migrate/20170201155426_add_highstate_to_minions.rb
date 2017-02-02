class AddHighstateToMinions < ActiveRecord::Migration[5.0]
  def change
    add_column :minions, :highstate, :integer, default: 0, after: :role
  end
end
