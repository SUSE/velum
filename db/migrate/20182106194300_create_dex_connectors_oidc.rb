class CreateDexConnectorsOidc < ActiveRecord::Migration
  def change
    create_table :dex_connectors_oidc do |t|
      t.timestamps                                               null: true
      t.string   :name
      t.string   :provider_url,       limit: 2048
      t.string   :client_id
      t.string   :client_secret
      t.string   :callback_url,       limit: 2048
      t.boolean  :basic_auth,                     default: true, null: false
    end
  end
end
