class AddMigrationStatus < ActiveRecord::Migration
  def change
    add_column :minions, :tx_update_migration_available, :boolean, default: false, after: :tx_update_failed
    add_column :minions, :tx_update_migration_notes, :string, after: :tx_update_migration_available
    add_column :minions, :tx_update_migration_mirror_synced, :boolean, default: false, after: :tx_update_migration_notes
    add_column :minions, :tx_update_migration_newversion, :string, after: :tx_update_migration_mirror_synced
    add_column :minions, :os_release, :string, after: :online
  end
end
