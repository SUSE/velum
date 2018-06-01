class AlterDexDefaults < ActiveRecord::Migration
    def change
        change_column_default("dex_connectors_ldap", "port", nil)
        change_column_default("dex_connectors_ldap", "start_tls", nil)
        change_column_default("dex_connectors_ldap", "bind_anon", nil)
        change_column_default("dex_connectors_ldap", "bind_dn", nil)
        change_column_default("dex_connectors_ldap", "username_prompt", nil)
        change_column_default("dex_connectors_ldap", "user_base_dn", nil)
        change_column_default("dex_connectors_ldap", "user_filter", nil)
        change_column_default("dex_connectors_ldap", "user_attr_id", nil)
        change_column_default("dex_connectors_ldap", "user_attr_username", nil)
        change_column_default("dex_connectors_ldap", "user_attr_email", nil)
        change_column_default("dex_connectors_ldap", "user_attr_name", nil)
        change_column_default("dex_connectors_ldap", "group_base_dn", nil)
        change_column_default("dex_connectors_ldap", "group_filter", nil)
        change_column_default("dex_connectors_ldap", "group_attr_user", nil)
        change_column_default("dex_connectors_ldap", "group_attr_group", nil)
        change_column_default("dex_connectors_ldap", "group_attr_name", nil)        
    end
end