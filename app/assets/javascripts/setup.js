$(function() {
  $('.btn-group-toggle').click(function() {
    var $btnGroup = $(this);
    $btnGroup.find('.btn').toggleClass('active');
    $btnGroup.find('.btn').toggleClass('btn-primary');
    $btnGroup.find('.btn').toggleClass('btn-default');
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
});
