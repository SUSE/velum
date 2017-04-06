class AddEc2ConfigurationToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.text :ec2_configuration
    end
  end
end
