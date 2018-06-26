class AddOnlineStatusToMinions < ActiveRecord::Migration
  def change
    add_column :minions, :online, :boolean, default: true, after: :tx_update_failed
  end
end
