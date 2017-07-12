class AddProcessedAtWorkerIdTakenAtIndexesToSaltEvents < ActiveRecord::Migration
  def change
    add_index :salt_events, :processed_at
    add_index :salt_events, [:worker_id, :taken_at]
  end
end
