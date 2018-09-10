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

  function ldapConnectionTestPart1 () {
    var file = $('#dex_connector_ldap_certificate').val()
    if(!file) {
      ldapConnectionTestPart2( $('#dex_connector_ldap_current_cert').val() )
      return;
    }
    var fileInput = $('#dex_connector_ldap_certificate')[0];
    var reader = new FileReader();

    reader.onload = function(e) {
      ldapConnectionTestPart2(reader.result);
    }

    reader.readAsText(fileInput.files[0]);	
  }

  function ldapFormSubmit (event) {
    var file = $('#dex_connector_ldap_certificate').val()
    if(!file) {
      var currentCert = $('#dex_connector_ldap_current_cert').val();
      if(currentCert) {
        $('#dex_connector_ldap_certificate').remove();
      }
    }
    return true;
  }

  function ldapConnectionTestPart2 (cert) {
    var host     = $('#dex_connector_ldap_host').val()
    var port     = $('#dex_connector_ldap_port').val()
    var startTLS = $('#dex_connector_ldap_start_tls_true').parent().hasClass('active')
    // Flip logic of #anonymous_bind_toggle since expanded div means anonymous binding is 'false'
    var anonBind = ($('#anonymous_bind_toggle').attr('aria-expanded') === 'false')
    var dn       = $('#dex_connector_ldap_bind_dn').val()
    var pass     = $("#dex_connector_ldap_bind_pw[required='required']").val();
    var baseDN   = $('#dex_connector_ldap_user_base_dn').val()
    var filter   = $('#dex_connector_ldap_user_filter').val()
    var paramArray = anonBind ? [host, port, cert, baseDN, filter] : [host, port, cert, dn, pass, baseDN, filter]

    if (noneEmpty(paramArray)) { // Check if form inputs are filled in
      $.post('/settings/ldap_test', {
        host: host, port: port, start_tls: startTLS, cert: cert,
        anon_bind: anonBind, dn: dn, pass: pass, base_dn: baseDN, filter: filter
      }).done(function (data) {
        if (data.result.test_pass) renderValidity('Sucessfully validated connection to LDAP server', true)
        else                       renderValidity('Validation failure. ' + data.result.message, false)
      }).fail(function (status) {
        var valMessage = 'Failed to connect to Velum server with following error code/message: ' + status.status + '; ' + status.statusText
        renderValidity(valMessage, false)
      })
    } else {
      renderValidity('Missing form data', false)
    }
  }

  function setupFieldOnchange ( fieldName ) {
    var fetch;
    if( fieldName == 'bind_pw' ) fetch = "#dex_connector_ldap_bind_pw[required='required']";
    else fetch = '#dex_connector_ldap_' + fieldName;

    var field = $(fetch);
    field.change( fieldChange );
  }

  function fieldChange () {
    showTestConnectionMessage();
  }

  function showTestConnectionMessage () {
    renderValidity( 'Test Connection first before saving', false );
  }

  $(function () {
    // Elements specific to LDAP Connector page; check for existence before changing
    if ($('#ldap_conn_save').length > 0 && $('#ldap_conn_message').length > 0) {
      showTestConnectionMessage();
    };

    // Run LDAP Connection Test with button click
    $('#ldap_conn_test').click(ldapConnectionTestPart1)

    var currentCert = $('#dex_connector_ldap_current_cert').val();
    if( currentCert ) {
      $('#dex_connector_ldap_certificate').removeAttr('required');
      var form = $('form.dex-connectors-form');
      form.submit(ldapFormSubmit);
    }

    // prepend with dex_connector_ldap_
    var fields = [
      'name', 'host', 'port', 'start_tls_true', 'start_tls_false', 'certificate',
      'bind_anon_true', 'bind_anon_false', 'bind_dn', 'bind_pw',
      'user_base_dn', 'user_filter'
    ];
    for( var i=0;i<fields.length;i++ ) setupFieldOnchange( fields[i] );
  })
})
