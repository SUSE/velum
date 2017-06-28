$('.btn-toggle').click(function() {
  $(this).find('.btn').toggleClass('active');
  $(this).find('.btn').toggleClass('btn-primary');
  $(this).find('.btn').toggleClass('btn-default');
});
