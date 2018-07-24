FactoryGirl.define do
  factory :dex_connector_ldap, class: DexConnectorLdap do
    sequence(:name) { |n| "LDAP Server #{n}" }
    sequence(:host) { |n| "ldap_host_#{n}.com" }

    # default to TLS
    port 636
    start_tls false

    trait :tls do
      port 636
      start_tls false
    end

    trait :starttls do
      port 389
      start_tls true
    end

    # default to anon_admin
    bind_anon true

    trait :anon_admin do
      bind_anon true
    end

    trait :regular_admin do
      bind_anon false
      bind_dn { "cn=admin,dc=#{host.chomp(".com")},dc=com" }
      bind_pw "pass"
    end

    username_prompt "Username"
    user_base_dn { "cn=users,dc=#{host.chomp(".com")},dc=com" }
    user_filter "(objectClass=person)"
    user_attr_username "uid"
    user_attr_id "uid"
    user_attr_email "mail"
    user_attr_name "name"
    group_base_dn { "cn=groups,dc=#{host.chomp(".com")},dc=com" }
    group_filter "(objectClass=group)"
    group_attr_user "uid"
    group_attr_group "member"
    group_attr_name "name"
  end
end
