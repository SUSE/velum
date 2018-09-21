/* eslint-disable no-new */
$(function () {
  var globals = window;

  var $mirrorForm = $('.mirror-form');
  var $registryForm = $('.registry-form');
  var $systemCertificateForm = $('.system-certificate-form');
  var $dexConnectorForm = $('.dex-connector-form');

  if ($mirrorForm.length) {
    new globals.RegistryForm($mirrorForm);
  }

  if ($registryForm.length) {
    new globals.RegistryForm($registryForm);
  }

  if ($systemCertificateForm.length) {
    new globals.SystemCertificateForm($systemCertificateForm);
  }

  if ($dexConnectorForm.length) {
    new globals.DexConnectorForm($dexConnectorForm);
  }
});
