$(function() {
  var $mirrorForm = $('.mirror-form');
  var $registryForm = $('.registry-form');
  var $systemCertificateForm = $('.system-certificate-form');
  var $dexConnectorForm = $('.dex-connector-form');

  if ($mirrorForm.length) {
    new RegistryForm($mirrorForm);
  }

  if ($registryForm.length) {
    new RegistryForm($registryForm);
  }

  if ($systemCertificateForm.length) {
    new SystemCertificateForm($systemCertificateForm);
  }

  if ($dexConnectorForm.length) {
    new DexConnectorForm($dexConnectorForm);
  }
});
