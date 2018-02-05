class CreateRegistries < ActiveRecord::Migration
  def change
    create_table :registries do |t|
      t.string :url, unique: true
      t.string :mirror
      t.timestamps
    end
  end
end
