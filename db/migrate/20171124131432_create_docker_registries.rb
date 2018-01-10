class CreateDockerRegistries < ActiveRecord::Migration
  def change
    create_table :docker_registries do |t|
      t.string :url, unique: true
      t.string :mirror
      t.timestamps
    end
  end
end
