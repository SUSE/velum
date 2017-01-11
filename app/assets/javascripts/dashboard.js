MinionPoller = {
  poll: function() {
    return setInterval(this.request, 5000);
  },
  request: function() {
    $.get($('#nodes').data('url'), {
      after: function() {
      }
    });
  }
};
