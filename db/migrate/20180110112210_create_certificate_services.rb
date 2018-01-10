class CreateCertificateServices < ActiveRecord::Migration
  def change
    create_table :certificate_services do |t|
      t.references :certificate
      t.references :service, polymorphic: true
      t.timestamps
    end
    add_index :certificate_services, [:certificate_id, :service_id, :service_type], name: "index_certificate_services_on_certificate_id_and_service", unique: true
  end
end
