$(function () {
  function noneEmpty (paramArray) {
    for (var i = 0; i < paramArray.length; i++) {
      if (paramArray[i] === '') return false
    }
    return true
  };

  function renderValidity (msg, isValid) {
    $('#ldap_conn_message').removeClass('ldap-conn-message-default ldap-conn-message-valid ldap-conn-message-invalid')
    if (isValid) {
      $('#ldap_conn_save').removeProp('disabled')
      $('#ldap_conn_message').addClass('ldap-conn-message-valid')
    } else {
      $('#ldap_conn_save').prop('disabled', 'disabled')
      $('#ldap_conn_message').addClass('ldap-conn-message-invalid')
    }
    $('#ldap_conn_message').html(msg)
  }

  $(function () {
    // Elements specific to LDAP Connector page; check for existence before changing
    if ($('#ldap_conn_save').length > 0 && $('#ldap_conn_message').length > 0) {
      $('#ldap_conn_save').prop('disabled', 'disabled')
      $('#ldap_conn_message').addClass('ldap-conn-message-default')
      $('#ldap_conn_message').html('Test Connection first before saving')
    };

    // Run LDAP Connection Test with button click
    $('#ldap_conn_test').click(function (event) {
      // Get values from form
      var host = $('#dex_connector_ldap_host').val()
      var port = $('#dex_connector_ldap_port').val()
      var startTLS = $('#dex_connector_ldap_start_tls_true').parent().hasClass('active')
      var cert = $('#dex_connector_ldap_certificate').val()
      // Flip logic of #anonymous_bind_toggle since expanded div means anonymous binding is 'false'
      var anonBind = ($('#anonymous_bind_toggle').attr('aria-expanded') === 'false')
      var dn = $('#dex_connector_ldap_bind_dn').val()
      var pass = $('#dex_connector_ldap_bind_pw').val()
      var baseDN = $('#dex_connector_ldap_user_base_dn').val()
      var filter = $('#dex_connector_ldap_user_filter').val()

      var baseURL = '/settings/ldap_test'
      var valMessage = ''
      var paramArray = []

      if (anonBind) {
        paramArray = [host, port, cert, baseDN, filter]
      } else {
        paramArray = [host, port, cert, dn, pass, baseDN, filter]
      }

      var allParamsEntered = noneEmpty(paramArray)

      // Check if form inputs are filled in
      if (allParamsEntered) {
        $.post(baseURL, {
          host: host,
          port: port,
          start_tls: startTLS,
          cert: cert,
          anon_bind: anonBind,
          dn: dn,
          pass: pass,
          base_dn: baseDN,
          filter: filter
        }).done(function (data) {
          if (data.result.test_pass) {
            renderValidity('Sucessfully validated connection to LDAP server', true)
          } else {
            renderValidity('Validation failure. ' + data.result.message, false)
          }
        }).fail(function (status) {
          valMessage = 'Failed to connect to Velum server with following error code/message: ' + status.status + '; ' + status.statusText
          renderValidity(valMessage, false)
        })
      } else {
        renderValidity('Missing form data', false)
      }
    })
  })
})
