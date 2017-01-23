class AddColumnsToSaltEvents < ActiveRecord::Migration[5.0]
  def change
    add_column :salt_events, :taken_at, :datetime
    add_column :salt_events, :processed_at, :datetime
    add_column :salt_events, :worker_id, :string
  end
end
