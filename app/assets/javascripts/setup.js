$('.btn-group-toggle').click(function() {
  var $btnGroup = $(this);
  $btnGroup.find('.btn').toggleClass('active');
  $btnGroup.find('.btn').toggleClass('btn-primary');
  $btnGroup.find('.btn').toggleClass('btn-default');
});
