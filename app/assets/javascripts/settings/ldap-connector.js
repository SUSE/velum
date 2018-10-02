$(function () {
    // Link browser form requirements for bindDN and password to anonymous bind status
    // There is no 'toggle' event for this Bootstrap element, so both buttons must be monitored for change
    $('#dex_connector_ldap_bind_anon_true').on('change', function () {
        $('#dex_connector_ldap_bind_dn').removeAttr('required')
        $("#dex_connector_ldap_bind_pw[type='password']").removeAttr('required')
    })

    $('#dex_connector_ldap_bind_anon_false').on('change', function () {
        $('#dex_connector_ldap_bind_dn').attr('required', 'required')
        $("#dex_connector_ldap_bind_pw[type='password']").attr('required', 'required')
    })
})