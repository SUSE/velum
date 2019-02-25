/* eslint-disable no-new */

$(function () {
  var globals = window;

  var openstackSettings = new globals.OpenStackSettings('.openstack-settings');
  new globals.SUSERegistryMirrorPanel('.suse-mirror-panel-body');

  $('.btn-group-toggle').click(function (e) {
    var $btnGroup = $(this);
    var $btnClicked = $(e.target);

    if ($btnClicked.hasClass('btn-primary')) {
      return;
    }

    $btnGroup.find('.btn').toggleClass('btn-primary active');
  });

  $(document).on('click', '.js-toggle-overlay-settings-btn', function () {
    var targetId = $(this).data('target');
    var collapsed = $(targetId).attr('aria-expanded') === 'true';

    if (collapsed) {
      $(this).text('Hide');
    } else {
      $(this).text('Show');
    }
  });

  $(document).on('click', '.runtime-btn-group .btn', function () {
    $('.docker-desc, .crio-desc').collapse('hide');
    $($(this).data('element')).collapse('show');
  });

  $(document).on('click', '.cni-btn-group .btn', function () {
    $('.flannel-desc, .cilium-desc').collapse('hide');
    $($(this).data('element')).collapse('show');
  });


  function toggleOpenStackSettings() {
    if ($('input[name="settings[cloud_provider]"]').val() === 'openstack') {
      openstackSettings.settingsEnabled();
    } else {
      openstackSettings.settingsDisabled();
    }
  }

  $(document).on('change', 'input[name="settings[cloud_provider]"]', toggleOpenStackSettings);
  toggleOpenStackSettings();
});
