class AddRememberToken < ActiveRecord::Migration
  def change
    add_column :users, :remember_token, :string, limit: 150, index: true, after: :reset_password_sent_at
  end
end
