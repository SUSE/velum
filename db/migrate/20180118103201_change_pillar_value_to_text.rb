class ChangePillarValueToText < ActiveRecord::Migration
  def up
    change_column :pillars, :value, :text
  end
  def down
    change_column :pillars, :value, :string
  end
end
