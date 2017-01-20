MinionPoller = {
    poll: function() {
        this.request();
        return setInterval(this.request, 5000);
    },

    request: function() {
        $.ajax({
            url: $('#nodes').data('url'),
            dataType: "json",
            success: function(data) {
                var rendered = "";

                for (i = 0; i < data.length; i++) {
                    rendered += MinionPoller.render(data[i]);
                }
                $("#nodes").html(rendered);
            }
        });
    },

    render: function(minion) {
        return "<div> \
  <a href=\"/nodes/" + minion.id + "\">" + minion.hostname + "</a>\
  <dl>\
    <dt>Created at</dt>\
    <dd>" + minion.created_at + "</dd>\
\
    <dt>Updated at</dt>\
    <dd>" + minion.updated_at + "</dd>\
  </dl>"
    }
};
