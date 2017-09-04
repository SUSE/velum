class CreateOrchestrations < ActiveRecord::Migration
  def change
    create_table :orchestrations do |t|
      t.string :jid, index: true
      t.integer :kind
      t.integer :status, default: 0
      t.datetime :started_at
      t.datetime :finished_at
      t.timestamps
    end
    add_index :orchestrations, [:kind, :status]
  end
end
