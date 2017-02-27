class CreatePillars < ActiveRecord::Migration
  def change
    create_table :pillars do |t|
      t.string :minion_id, index: true
      t.string :pillar, index: true
      t.string :value
      t.timestamps
    end
  end
end
