class AddRoleToMinions < ActiveRecord::Migration[5.0]
  def change
    add_column :minions, :role, :integer, index: true, after: :hostname
  end
end
