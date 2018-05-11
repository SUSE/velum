class CreateSaltJobs < ActiveRecord::Migration
  def change
    create_table :salt_jobs do |t|
      t.string :jid
      t.integer :retcode
      t.text :master_trace
      t.text :minion_trace

      t.timestamps null: false
    end
    add_index :salt_jobs, :jid
  end
end
