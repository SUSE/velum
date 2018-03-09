$(function() {
  var $mirrorForm = $('.mirror-form');
  var $registryForm = $('.registry-form');

  if ($mirrorForm.length) {
    new RegistryForm($mirrorForm);
  }

  if ($registryForm.length) {
    new RegistryForm($registryForm);
  }
});