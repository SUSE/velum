class CreateSystemCertificates < ActiveRecord::Migration
  def change
    create_table :system_certificates do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
