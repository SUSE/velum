class AddRoleToMinions < ActiveRecord::Migration
  def change
    add_column :minions, :role, :integer, index: true, after: :hostname
  end
end
