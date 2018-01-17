$(function () {
  var $userEmail = $('#user_email');

  // setup tooltip
  $userEmail.tooltip({
    trigger: 'manual',
    title: 'Warning: it\'s preferred to use an email address in the format "user@example.com"',
    placement: 'left'
  });

  // shows tooltip
  function showsWarning() {
    // avoids blink
    if (!$userEmail.next().length) {
      $userEmail.tooltip('show');
    }
  }

  // keyup event handler
  $userEmail.on('input', function () {
    var w3cRegex = /^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/;
    var dotRegex = /^.+@.+\..+/
    var value = this.value;

    if (w3cRegex.test(value) && !dotRegex.test(value)) {
      showsWarning();
    } else {
      $userEmail.tooltip('hide');
    }
  });
})