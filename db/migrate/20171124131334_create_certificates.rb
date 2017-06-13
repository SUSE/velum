class CreateCertificates < ActiveRecord::Migration
  def change
    create_table :certificates do |t|
      t.text :certificate

      t.timestamps
    end
  end
end
