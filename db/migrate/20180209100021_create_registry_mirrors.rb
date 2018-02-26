class CreateRegistryMirrors < ActiveRecord::Migration
  def change
    create_table :registry_mirrors do |t|
      t.string :name
      t.string :url, unique: true
      t.references :registry, index: true

      t.timestamps null: false
    end
  end
end
