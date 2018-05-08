class CreateKubeletComputeResourcesReservations < ActiveRecord::Migration
  def change
    create_table :kubelet_compute_resources_reservations do |t|
      t.string :component, null: false
      t.string :cpu, default: ''
      t.string :memory, default: ''
      t.string :ephemeral_storage, default: ''
      t.timestamps
    end

    add_index :kubelet_compute_resources_reservations, :component, unique: true
  end
end
