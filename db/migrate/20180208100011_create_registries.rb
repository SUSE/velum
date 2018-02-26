class CreateRegistries < ActiveRecord::Migration
  def change
    create_table :registries do |t|
      t.string :name
      t.string :url, unique: true
      t.timestamps
    end
  end
end
