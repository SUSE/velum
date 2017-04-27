MinionPoller = {
  poll: function() {
    this.request();
    return setInterval(this.request, 5000);
  },

  request: function() {
    $.ajax({
      url: $('.nodes-container').data('url'),
      dataType: "json",
      success: function(data) {
        var rendered = "";
        MinionPoller.selectedMasters = $("input[name='roles[master][]']:checked").map(function() {
          return parseInt($( this ).val());
        }).get();

        // depending on the url we might have these data:
        // when monitoring:
        //  [assigned_minions: [<minion1>,<minion2>,<minion3>], unassigned_minions: []]
        // when discovering:
        //   [<minion1>,<minion2>,<minion3>]
        var minions = data.assigned_minions || data;

        for (i = 0; i < minions.length; i++) {
          if (MinionPoller.renderMode == "discovery") {
            rendered += MinionPoller.renderDiscovery(minions[i]);
          } else {
            rendered += MinionPoller.render(minions[i]);
          }
        }
        $(".nodes-container tbody").html(rendered);

        // disable bootstrap button if there are no minions
        if (minions.length == 0) {
          $("#bootstrap").prop('disabled', true);
        } else {
          $("#bootstrap").prop('disabled', false);
        }

        var unassignedMinions = data.unassigned_minions || [];

        if (unassignedMinions.length > 0) {
          $('#unassigned_count').html(unassignedMinions.length + " \
            <strong>new</strong> nodes are available but have not been added to the cluster yet"
          );
        } else {
          $('#unassigned_count').html('');
        }
      }
    });
  },

  render: function(minion) {
    var statusHtml;
    var checked;
    var masterHtml;

    switch(minion.highstate) {
      case "not_applied":
        statusHtml = '<i class="fa fa-circle-o text-success fa-2x" aria-hidden="true"></i>';
        break;
      case "pending":
        statusHtml = '\
          <span class="fa-stack" aria-hidden="true">\
            <i class="fa fa-circle fa-stack-2x text-success" aria-hidden="true"></i>\
            <i class="fa fa-refresh fa-stack-1x fa-spin fa-inverse" aria-hidden="true"></i>\
          </span>';
        break;
      case "failed":
        statusHtml = '<i class="fa fa-times-circle text-danger fa-2x" aria-hidden="true"></i>';
        break;
      case "applied":
        statusHtml = '<i class="fa fa-check-circle-o text-success fa-2x" aria-hidden="true"></i>';
        break;
    }

    if ((MinionPoller.selectedMasters && MinionPoller.selectedMasters.indexOf(minion.id) != -1) || minion.role == "master") {
      checked =  "checked";
    } else {
      checked = '';
    }
    masterHtml = '<input name="roles[master][]" id="roles_master_' + minion.id +
      '" value="' + minion.id + '" type="radio" disabled="" ' + checked + '>';

    return "\
      <tr> \
        <th>" + minion.id +  "</th>\
        <td class='text-center'>" + statusHtml +  "</td>\
        <td>" + minion.fqdn +  "</td>\
        <td>" + (minion.role || '') +  "</td>\
        <td class='text-center'>" + masterHtml + "</td>\
      </tr>";
  },

  renderDiscovery: function(minion) {
    var masterHtml;
    var checked;

    if (MinionPoller.selectedMasters && MinionPoller.selectedMasters.indexOf(minion.id) != -1) {
      checked = "checked";
    } else {
      checked = '';
    }
    masterHtml = '<input name="roles[master][]" id="roles_master_' + minion.id +
      '" value="' + minion.id + '" type="radio" ' + checked + '>';

    return "\
      <tr> \
        <th>" + minion.id +  "</th>\
        <td>" + minion.fqdn +  "</td>\
        <td class='text-center'>" + masterHtml + "</td>\
      </tr>";
  }
};
