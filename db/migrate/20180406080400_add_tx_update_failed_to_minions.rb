class AddTxUpdateFailedToMinions < ActiveRecord::Migration
  def change
    add_column :minions, :tx_update_failed, :boolean, default: false, after: :tx_update_reboot_needed
  end
end
