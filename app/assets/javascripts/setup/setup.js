$(function() {
  $('.btn-group-toggle').click(function(e) {
    var $btnGroup = $(this);
    var $btnClicked = $(e.target);

    if ($btnClicked.hasClass('btn-primary')) {
      return false;
    }

    $btnGroup.find('.btn').toggleClass('btn-primary active');
  });

  $(document).on('click', '.js-toggle-overlay-settings-btn', function() {
    var targetId = $(this).data('target');
    var collapsed = $(targetId).attr('aria-expanded') === 'true';

    if (collapsed) {
      $(this).text('Hide');
    } else {
      $(this).text('Show');
    }
  });

  $(document).on('change', '.cloud-provider-select', function () {
    var isOpenStack = $(this).val() === 'openstack';

    $('.openstack-settings').toggleClass('hidden', !isOpenStack);
  });

  $(document).on('change', '.enable-cloud', function () {
    var isOpenStack = $('.cloud-provider-select').val() === 'openstack';

    $('.openstack-settings').toggleClass('hidden', !isOpenStack);
  });

  $(document).on('change', '.disable-cloud', function () {
    $('.openstack-settings').addClass('hidden');
  });

  new SUSERegistryMirrorPanel('.suse-mirror-panel-body');
});