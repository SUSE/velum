class CreateDexConnectorsLdap < ActiveRecord::Migration
  def change
    create_table :dex_connectors_ldap do |t|
      t.timestamps
      t.string    :name,               limit: 255
      t.string    :host,               limit: 255
      t.integer   :port,               limit: 2,   default: 636
      t.boolean   :start_tls,                      default: false, null: false
      t.boolean   :bind_anon,                      default: false, null: false # bind_dn and bind_pw ignored if true
      t.string    :bind_dn,            limit: 255, default: "uid=someuid,cn=users,dc=somedomain,dc=com"
      t.string    :bind_pw,            limit: 255
      t.string    :username_prompt,    limit: 255, default: "Username"
      t.string    :user_base_dn,       limit: 255, default: "cn=users,dc=somedomain,dc=com"
      t.string    :user_filter,        limit: 255, default: "(objectClass=person)"
      t.string    :user_attr_username, limit: 255, default: "uid"
      t.string    :user_attr_id,       limit: 255, default: "uid"
      t.string    :user_attr_email,    limit: 255, default: "mail", null: false
      t.string    :user_attr_name,     limit: 255, default: "name"
      t.string    :group_base_dn,      limit: 255, default: "cn=groups,dc=somedomain,dc=com"
      t.string    :group_filter,       limit: 255, default: "(objectClass=group)"
      t.string    :group_attr_user,    limit: 255, default: "uid"
      t.string    :group_attr_group,   limit: 255, default: "member"
      t.string    :group_attr_name,    limit: 255, default: "name"
    end
  end
end