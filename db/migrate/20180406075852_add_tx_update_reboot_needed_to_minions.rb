class AddTxUpdateRebootNeededToMinions < ActiveRecord::Migration
  def change
    add_column :minions, :tx_update_reboot_needed, :boolean, default: false, after: :highstate
  end
end
